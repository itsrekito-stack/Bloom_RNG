#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")
cfg=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
effects=read("src/ReplicatedStorage/Config/WorkshopEffectsConfig.luau")
service=read("src/ServerScriptService/Services/WorkshopService.luau")
season=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
block=re.search(r'Branches=\{(.*?)\n \},',cfg,re.S);assert block
branches=re.findall(r'"([A-Z]+)"',block.group(1))
assert len(branches)==27, f"expected 27 Workshop branches, got {len(branches)}"
need(cfg,"local HIVE_BY_INDEX={1,2,3,5,7,9}","Workshop Hive depth curve")
need(cfg,'Parent=i==1 and "CORE" or branch.."_"..(i-1)',"linear prerequisite chain")
need(cfg,'Cost=1',"point cost exists")
need(cfg,'local COINS_BY_INDEX={100,250,700,1800,4500,10000}',"Workshop Coin sink curve")
need(cfg,'Permanent=PERMANENT_BRANCHES[branch]==true',"permanent branch policy")
for needle,label in [
 ('if w.Nodes[id] then return false,"OWNED" end',"owned guard"),
 ('if n.Parent and n.Parent~="CORE" and not w.Nodes[n.Parent] then return false,"PARENT_REQUIRED" end',"parent guard"),
 ('if p.Hive.Level<(n.Hive or 0) then return false,"HIVE_REQUIRED" end',"Hive guard"),
 ('if w.Points<(n.Cost or 0) then return false,"POINTS_REQUIRED" end',"point guard"),
 ('if p.Currencies.Coins<(n.Coins or 0) then return false,"COINS_REQUIRED" end',"coin guard"),
 ('w.Points-=(n.Cost or 0)',"point spend"),
 ('p.Currencies.Coins-=(n.Coins or 0)',"coin spend"),
]: need(service,needle,label)
need(bloom,"EndlessHivePointsStepEvery=3","late Workshop Point acceleration")
need(bloom,"EndlessHivePointsMax=12","late Workshop Point cap")
need(season,"after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)","Season refund")
need(state,'local revealed=owned or id=="CORE" or parentOwned',"hidden node reveal rule")
need(ui,'Icons.GetWorkshopNodeIcon(id,not revealed)',"hidden node icon")
print("workshop tree progression contract: PASS")
print("27 branches / 162 nodes, Hive 1-9 depth gates, accelerated late Workshop Points and server-authoritative purchases.")
