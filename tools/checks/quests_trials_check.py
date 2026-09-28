#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")
service=read("src/ServerScriptService/Services/BuildTrialService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
quests=read("src/StarterPlayer/StarterPlayerScripts/Controllers/QuestsController.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")

entries={name:body for name,body in re.findall(r'(\w+)=\{([^}]*)\}',cfg) if 'Id="' in body}
if len(entries)!=8: raise AssertionError(f"unexpected trial count: {len(entries)}")
for name,body in entries.items():
    if 'Sector="Center"' not in body: raise AssertionError(f"{name} is still location-bound")

need(service,'return E.Feature(profile,"LEGACY_4","AdvancedTrials")',"advanced trial gate")
assert 'LocationsConfig' not in service, "trial service still imports locations"
assert 'SECTOR_LOCKED' not in service and 'WRONG_SECTOR' not in service and 'TOO_FAR' not in service, "trial service still uses location/shrine gating"
need(service,'local pos=root and root.Position or self.X.GardenPlotService:HivePosition(player)',"menu-start trial spawn position")
need(service,'id=="SwiftRoute" or id=="CrystalTriangle"',"route activities auto-spawn centrally")
need(service,'self.X.GardenActivityService:Offer(player,kind,pos,nil,nil,true)',"central trial activity offer")
need(service,'p.Quests.Trials[a.Id]=true',"trial persistence")
need(service,'self.X.WorkshopService:Point(player,"Trial_"..a.Id,2)',"trial reward")
need(service,'p.Currencies.Coins+=5',"repeat reward")

need(state,'else startHint="Ready to start from Quests" end',"menu-only trial start hint")
need(state,'NearShrine=true',"no shrine dependency")
assert 'Garden Trials shrine' not in state, "UI still references removed shrines"
need(quests,'action=function() controller:Send("Trial",trial.Id) end',"Quests starts trial")
need(locations,'Order={}',"locations stay removed")

print("quests / central trials contract: PASS")
