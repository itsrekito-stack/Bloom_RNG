#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/BuildTrialConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
activity_cfg=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
service=read("src/ServerScriptService/Services/BuildTrialService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
meta=read("src/ServerScriptService/Services/MetaProgressionService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")

base_ids={"MeadowCircuit","SwiftRoute","CrystalTriangle"}
advanced_ids={"NoCelestial","SignatureBloom","TwilightPulse","MinimalGarden","MutationStudy"}

trial_entries={}
for name,body in re.findall(r'(\w+)=\{([^}]*)\}',cfg):
    if 'Id="' not in body:
        continue
    trial_entries[name]=body

if set(trial_entries)!=base_ids|advanced_ids:
    raise AssertionError(f"unexpected release trial set: {sorted(trial_entries)}")
for name in base_ids:
    if "Advanced=true" in trial_entries[name]:
        raise AssertionError(f"Season/key trial incorrectly marked advanced: {name}")
for name in advanced_ids:
    if "Advanced=true" not in trial_entries[name]:
        raise AssertionError(f"advanced trial missing gate flag: {name}")

need(season,'TrialIds={"MeadowCircuit","SwiftRoute","CrystalTriangle"}',"Season eligibility uses base trials only")
need(service,'local E=require(RS.Shared.WorkshopEffects)',"Workshop feature authority")
need(service,'return E.Feature(profile,"LEGACY_4","AdvancedTrials")',"Advanced Trials feature gate")
need(service,'if cfg.Advanced and not self:AdvancedUnlocked(p) then return false,"ADVANCED_TRIAL_LOCKED" end',"server advanced lock")
need(service,'if not p.World.UnlockedSectors[cfg.Sector] then return false,"SECTOR_LOCKED" end',"sector lock")
need(service,'if self.X.MapService:Sector(player)~=cfg.Sector then return false,"WRONG_SECTOR" end',"current-sector lock")
need(service,'if not pos or not self.X.U.Near(player,pos,14) then return false,"TOO_FAR" end',"shrine proximity")
need(service,'Advanced=cfg.Advanced==true',"active trial derives advanced mode from config")
need(service,'local yes=(a.Counts[cfg.Event] or 0)>=cfg.Target',"target uses explicit config")
if "cfg.Target*(a.Advanced and 2 or 1)" in service:
    raise AssertionError("legacy global target doubling returned")

# Trial timeout is lifecycle-owned by the server tick, not by waiting for a random event.
need(service,"function S:Tick(player)","trial expiration tick")
need(service,"if not cfg or os.clock()-a.Start>cfg.Seconds then","timeout condition")
need(service,'self.X:Send(player,"Message",cfg and (cfg.Name.." expired") or "Trial expired")',"timeout feedback")
need(player,"local trialChanged=self.BuildTrialService:Tick(player)","PlayerService drives trial expiration")
need(player,"trialChanged or (self.BuildTrialService.Active[player] and sync>=C.SyncSeconds)","trial state refresh")

# Rewards: first completion advances persistent progression, repeats are small, advanced trials add a once-only source.
need(service,'p.Quests.Trials[a.Id]=true',"trial completion persistence")
need(service,'self.X.WorkshopService:Point(player,"Trial_"..a.Id,2)',"first-completion Workshop points")
need(service,'p.Season.CompletedGoals[a.Id]=true',"Season goal completion")
need(service,"p.Currencies.Coins+=5","repeat reward")
need(service,'self.X.WorkshopService:Point(player,"AdvancedTrial_"..a.Id,1)',"advanced completion point source")

# Swift Route must always be able to spawn its route even if normal activity slots are full.
need(service,'self.X.GardenActivityService:Offer(player,"PollenTrail",pos,cfg.Sector,nil,true)',"priority Swift Route token")

# Activity collection remains server-authoritative and bounded.
need(activity_cfg,"MaxVisible=2","bounded activity count")
need(activity_cfg,"PickupDistance=10","pickup radius")
need(activity_cfg,"HoldSeconds=.6","hold interaction duration")
need(activity,'if count>=A.MaxVisible and not priority then return false end',"activity visibility cap")
need(activity,'if o.Sector and not p.World.UnlockedSectors[o.Sector] then return false end',"activity sector validation")
need(activity,'if not self.X.U.Near(player,o.Nodes[o.Index],A.PickupDistance) then return false end',"activity proximity validation")
need(activity,'elseif not o.HoldStarted or os.clock()-o.HoldStarted<A.HoldSeconds then return false end',"hold duration validation")
need(activity,'o.Expires<workspace:GetServerTimeNow()',"activity expiry")
need(activity,'self.X:Emit(player,"ActivityCompleted",1)',"activity progression event")

# Journey/collection objectives contribute useful rewards.
need(meta,'p.Currencies.Coins=p.Currencies.Coins+10',"Journey coin reward")
need(meta,'self.X.WorkshopService:Point(player,"Collection_"..threshold,2)',"collection Workshop point rewards")

# UI mirrors server gating and explicitly labels the advanced set.
need(state,'ADVANCED_TRIAL_LOCKED="Unlock Advanced Trials in the Workshop"',"advanced lock reason")
need(state,'cfg.Advanced and not Effects.Feature(profile,"LEGACY_4","AdvancedTrials")',"UI advanced feature gate")
need(state,'Advanced=cfg.Advanced==true',"trial payload advanced flag")
need(state,'CanStart=reason==nil',"UI startability derives from server-style reason")
need(ui,'local advanced=t.Advanced and "ADVANCED  •  " or ""',"authoritative advanced label")
need(ui,'local advancedLocked=t.Advanced and not p.WorkshopV5.Nodes.LEGACY_4',"fallback advanced lock")

print("quests / activities / trials contract: PASS")
print("3 base Season trials + 5 Workshop-gated advanced trials; shrine/proximity/expiry/reward paths are server-authoritative.")
