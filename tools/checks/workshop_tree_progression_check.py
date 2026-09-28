#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
service=read("src/ServerScriptService/Services/WorkshopService.luau")
season=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

branches=["ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"]
need(cfg,'Branches={"ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"}',"release Workshop branches")
need(cfg,"local HIVE_BY_INDEX={1,2,3,4,5,5}","Workshop spans Hive 1-5")
need(cfg,'Parent=i==1 and "CORE" or branch.."_"..(i-1)',"linear prerequisite chain")
need(cfg,'Permanent=branch=="LEGACY"',"only Legacy branch is permanent")
need(cfg,'Cost=1',"point cost exists")
need(cfg,'Coins=i*30',"coin cost scales by depth")
need(cfg,'Dust=(branch=="ECONOMY" or branch=="BLOOM") and i*3 or 0',"dust sinks are branch-specific")
need(cfg,'Nectar=branch=="LEGACY" and i or 0',"Legacy consumes Ancient Nectar")

node_ids=set(re.findall(r'([A-Z]+_[1-6])=\{',effects))
expected={f"{b}_{i}" for b in branches for i in range(1,7)}
if node_ids != expected:
    raise AssertionError(f"Workshop effect coverage mismatch: missing={sorted(expected-node_ids)} extra={sorted(node_ids-expected)}")

# Purchase remains fully server-authoritative and deductions happen only after all gates.
for needle,label in [
    ('if w.Nodes[id] then return false,"OWNED" end',"owned guard"),
    ('if n.Parent and n.Parent~="CORE" and not w.Nodes[n.Parent] then return false,"PARENT_REQUIRED" end',"parent guard"),
    ('if p.Hive.Level<(n.Hive or 0) then return false,"HIVE_REQUIRED" end',"Hive guard"),
    ('if n.Branch=="LEGACY" and p.Season.Count==0 then return false,"SEASON_REQUIRED" end',"Season guard"),
    ('if w.Points<(n.Cost or 0) then return false,"POINTS_REQUIRED" end',"point guard"),
    ('if p.Currencies.Coins<(n.Coins or 0) then return false,"COINS_REQUIRED" end',"coin guard"),
    ('if p.Currencies.PetalDust<(n.Dust or 0) then return false,"DUST_REQUIRED" end',"dust guard"),
    ('if p.Currencies.AncientNectar<(n.Nectar or 0) then return false,"NECTAR_REQUIRED" end',"nectar guard"),
    ('w.Points-=(n.Cost or 0)',"point spend"),
    ('p.Currencies.Coins-=(n.Coins or 0)',"coin spend"),
    ('p.Currencies.PetalDust-=(n.Dust or 0)',"dust spend"),
    ('p.Currencies.AncientNectar-=(n.Nectar or 0)',"nectar spend"),
    ('if n.Permanent then w.LegacyNodes[id]=true end',"permanent ownership mirror"),
]:
    need(service,needle,label)

# Normal respec is intentionally disabled. RESET & REFUND belongs to a future Biome transition.
need(service,"function S:Respec(player)","closed respec endpoint")
need(service,'return false,"ACTION_UNAVAILABLE"',"normal respec fails closed")
if "p.WorkshopV5.Points+=(n.Cost or 0)" in service:
    raise AssertionError("unrestricted normal Workshop refund path returned")

# Season reset uses configured point cost instead of a hard-coded +1.
need(season,"local W=require(RS.Config.WorkshopConfig)","Season plan shares Workshop config")
need(season,"after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)","config-driven Season refund")
need(season,"if not after.WorkshopV5.LegacyNodes[id] then","Season preserves permanent nodes")

# Hidden nodes expose no real cost/requirements and the client uses unknown icons/no tooltip.
need(state,'local revealed=owned or id=="CORE" or parentOwned',"server reveal rule")
for field in ["Hive","Cost","Coins","Dust","Nectar"]:
    need(state,f'{field}=revealed and',f"hidden {field} redaction")
need(ui,'icon.Image=Icons.GetWorkshopNodeIcon(id,not revealed)',"unknown icon for hidden node")
need(ui,'if currentRevealed then\n        showTooltip',"hidden node tooltip suppression")

print("workshop tree progression contract: PASS")
print("42 effect-backed nodes, Hive 1-5 gating, permanent Legacy branch, disabled normal respec and config-driven Season refunds.")
