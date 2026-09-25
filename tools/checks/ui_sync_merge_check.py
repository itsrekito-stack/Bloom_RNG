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
required_nested={"MinimizeButton"}

def node(name):
    return {"ClassName":"Frame","Name":name,"Properties":{"Visible":True},"Children":[]}

base={"ClassName":"Frame","Name":"SafeRoot","Children":[node("ActiveBoostsHUD"),node("OptionalLocalPanel")]}
local={"ClassName":"Frame","Name":"SafeRoot","Children":[]}
remote={"ClassName":"Frame","Name":"SafeRoot","Children":[node("ActiveBoostsHUD"),node("OptionalLocalPanel")]}

merged=module.merge_remote_changes(base,local,remote)
names={x.get("Name") for x in merged["Children"]}
assert "ActiveBoostsHUD" in names, "required runtime child was lost by Python AI-sync merge"
assert "OptionalLocalPanel" not in names, "ordinary local deletion should still be preserved"

base_hud={"ClassName":"Frame","Name":"ActiveBoostsHUD","Children":[node("MinimizeButton")]}
local_hud={"ClassName":"Frame","Name":"ActiveBoostsHUD","Children":[]}
remote_hud={"ClassName":"Frame","Name":"ActiveBoostsHUD","Children":[node("MinimizeButton")]}
merged_hud=module.merge_remote_changes(base_hud,local_hud,remote_hud)
nested_names={x.get("Name") for x in merged_hud["Children"]}
assert "MinimizeButton" in nested_names, "required nested minimize control was lost by Python AI-sync merge"

safe=next(x for x in MODEL["Children"] if x.get("Name")=="SafeRoot")
model_names={x.get("Name") for x in safe.get("Children",[])}
assert required<=model_names, f"remote authored model missing required boost nodes: {sorted(required-model_names)}"
boost_root=next(x for x in safe.get("Children",[]) if x.get("Name")=="ActiveBoostsHUD")
boost_child_names={x.get("Name") for x in boost_root.get("Children",[])}
assert required_nested<=boost_child_names, f"remote authored boost HUD missing controls: {sorted(required_nested-boost_child_names)}"

assert "fn is_required_runtime_ui_child(value: &Value) -> bool" in RUST
assert '"ActiveBoostsHUD"' in RUST and '"ActiveBoostTooltip"' in RUST and '"MinimizeButton"' in RUST
assert "if is_required_runtime_ui_child(r) || b != r" in RUST

print("UI sync merge contract: PASS")
print("Required runtime BloomUI children survive stale local editor merges in both Bloom UI Studio and RoFlow.")
