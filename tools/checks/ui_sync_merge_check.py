#!/usr/bin/env python3
from pathlib import Path
import importlib.util
import json

ROOT=Path(__file__).resolve().parents[2]
SERVER=ROOT/"tools/bloom-ui-editor/server.py"
RUST=(ROOT/"tools/roflow/src-tauri/src/lib.rs").read_text(encoding="utf-8")
MODEL=json.loads((ROOT/"src/StarterGui/BloomUI.model.json").read_text(encoding="utf-8"))

spec=importlib.util.spec_from_file_location("bloom_ui_server",SERVER)
module=importlib.util.module_from_spec(spec)
assert spec and spec.loader
spec.loader.exec_module(module)

required={"ActiveBoostsHUD","ActiveBoostTooltip"}
boost_required={"MinimizeButton","LuckBadge","ScrollLeft","ScrollRight"}
additional_required={"TraitFilterPanel","TraitFilterList","TraitChipTemplate","UnequipAllButton","EquippedBadge","InventoryHoverScale","BeeSummary","PassiveRowTemplate","AbilityDescription","UsedBadge","GhostBadge","MenuDock","CurrencyHelp","Dock_SeedSatchel","Dock_Garden","Dock_Index","Dock_Workshop","Dock_Trials","Dock_Settings"}
workshop_required={
    "WorkshopTemplate","WorkshopBody","TreePanel","TreeCanvas","PanMap",
    "NodeTooltip","WorkshopCurrencyBar","WorkshopPoints","WorkshopCoins","WorkshopPetalDust","WorkshopAncientNectar",
}

def node(name,children=None,**props):
    properties={"Visible":True}
    properties.update(props)
    return {"ClassName":"Frame","Name":name,"Properties":properties,"Children":children or []}

# Existing HUD protection: stale editor deletions of runtime-critical authored UI are restored.
base={"ClassName":"Frame","Name":"SafeRoot","Children":[node("ActiveBoostsHUD"),node("OptionalLocalPanel")]}
local={"ClassName":"Frame","Name":"SafeRoot","Children":[]}
remote={"ClassName":"Frame","Name":"SafeRoot","Children":[node("ActiveBoostsHUD"),node("OptionalLocalPanel")]}
merged=module.merge_remote_changes(base,local,remote)
names={x.get("Name") for x in merged["Children"]}
assert "ActiveBoostsHUD" in names, "required runtime child was lost by Python AI-sync merge"
assert "OptionalLocalPanel" not in names, "ordinary local deletion should still be preserved"

base_hud=node("ActiveBoostsHUD",[node("MinimizeButton"),node("LuckBadge"),node("ScrollLeft"),node("ScrollRight")])
local_hud=node("ActiveBoostsHUD",[])
remote_hud=node("ActiveBoostsHUD",[node("MinimizeButton"),node("LuckBadge"),node("ScrollLeft"),node("ScrollRight")])
merged_hud=module.merge_remote_changes(base_hud,local_hud,remote_hud)
nested_names={x.get("Name") for x in merged_hud["Children"]}
assert {"MinimizeButton","LuckBadge","ScrollLeft","ScrollRight"}<=nested_names, "required boost controls were lost by Python AI-sync merge"

dock_names={"Dock_SeedSatchel","Dock_Garden","Dock_Index","Dock_Workshop","Dock_Trials","Dock_Settings"}
base_dock=node("MenuDock",[node(name) for name in sorted(dock_names)])
local_dock=node("MenuDock",[])
remote_dock=node("MenuDock",[node(name) for name in sorted(dock_names)])
merged_dock=module.merge_remote_changes(base_dock,local_dock,remote_dock)
merged_dock_names={x.get("Name") for x in merged_dock["Children"]}
assert dock_names<=merged_dock_names, "stale local UI state swallowed shared bottom-dock navigation"

# Regression for the Studio failure seen after Workshop V2 landed: local UI Studio state
# may still contain WorkshopBody without the newly required tooltip/currency overlay.
base_workshop=node("WorkshopBody",[
    node("TreePanel"),
    node("NodeTooltip",[node("Branch"),node("Effect"),node("Cost")]),
    node("WorkshopCurrencyBar",[node("WorkshopPoints"),node("Coins"),node("PetalDust"),node("AncientNectar")]),
])
local_workshop=node("WorkshopBody",[node("TreePanel")])
remote_workshop=node("WorkshopBody",[
    node("TreePanel"),
    node("NodeTooltip",[node("Branch"),node("Effect"),node("Cost")],Active=False,Selectable=False,LayoutOrder=2),
    node("WorkshopCurrencyBar",[node("WorkshopPoints"),node("WorkshopCoins"),node("WorkshopPetalDust"),node("WorkshopAncientNectar")],Active=False,Selectable=False,LayoutOrder=1),
])
merged_workshop=module.merge_remote_changes(base_workshop,local_workshop,remote_workshop)
merged_workshop_names={x.get("Name") for x in merged_workshop["Children"]}
assert "NodeTooltip" in merged_workshop_names, "stale local Workshop deletion swallowed NodeTooltip"
assert "WorkshopCurrencyBar" in merged_workshop_names, "stale local Workshop deletion swallowed currency bar"
tooltip=next(x for x in merged_workshop["Children"] if x.get("Name")=="NodeTooltip")
tooltip_names={x.get("Name") for x in tooltip.get("Children",[])}
assert {"Branch","Effect","Cost"}<=tooltip_names, "restored Workshop tooltip lost authored fields"

def walk(node):
    yield node
    for child in node.get("Children",[]) or []:
        yield from walk(child)

all_nodes={n.get("Name"):n for n in walk(MODEL)}
safe=next(x for x in MODEL["Children"] if x.get("Name")=="SafeRoot")
model_names={x.get("Name") for x in safe.get("Children",[])}
assert required<=model_names, f"remote authored model missing required boost nodes: {sorted(required-model_names)}"
boost_root=next(x for x in safe.get("Children",[]) if x.get("Name")=="ActiveBoostsHUD")
boost_child_names={x.get("Name") for x in walk(boost_root)}
assert boost_required<=boost_child_names, f"remote authored boost HUD missing controls: {sorted(boost_required-boost_child_names)}"
missing_additional=sorted(name for name in additional_required if name not in all_nodes)
assert not missing_additional, f"remote authored model missing new runtime controls: {missing_additional}"

missing_workshop=sorted(name for name in workshop_required if name not in all_nodes)
assert not missing_workshop, f"remote authored Workshop missing sync-critical nodes: {missing_workshop}"
model_tooltip=all_nodes["NodeTooltip"]
assert model_tooltip.get("Properties",{}).get("Active") is False
assert model_tooltip.get("Properties",{}).get("Selectable") is False
model_tooltip_children={x.get("Name") for x in model_tooltip.get("Children",[])}
assert {"Title","Branch","Effect","Cost","Hint","Accent"}<=model_tooltip_children

assert "fn is_required_runtime_ui_child(value: &Value) -> bool" in RUST
for name in sorted(required|boost_required|additional_required|workshop_required):
    assert f'"{name}"' in RUST, f"RoFlow merge protection missing {name}"
assert "if is_required_runtime_ui_child(r) || b != r" in RUST

print("UI sync merge contract: PASS")
print("Required BloomUI and Workshop authored nodes survive stale local editor merges in Python bridge and RoFlow.")
