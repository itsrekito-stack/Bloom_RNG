#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

remote=read("src/ServerScriptService/Services/RemoteService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
trials=read("src/ServerScriptService/Services/BuildTrialService.luau")
season=read("src/ServerScriptService/Services/SeasonService.luau")

# Every externally routable action must be covered by the remote validator.
actions=set(re.findall(r'action=="([A-Za-z0-9_]+)"',player))
actions.update({"SeasonCancel"})
for action in sorted(actions):
    covered=(f'action=="{action}"' in remote) or (re.search(rf'\b{re.escape(action)}=true\b',remote) is not None)
    if not covered: raise AssertionError(f"remote action lacks schema validation: {action}")

need(remote,'if not scalar(a) or not scalar(b) or not scalar(c) then return false,"INVALID_VALUE" end',"non-scalar payload rejection")
need(remote,'integer(b,1,2147483647)',"Roll request id bounds")
need(remote,'integer(a,1,C.MaxFlowerSlots)',"Plant slot bounds")
need(remote,'integer(b,1,C.MaxBeeSlots)',"Bee slot bounds")
need(remote,'integer(b,1,10000)',"Dissolve quantity bounds")
need(remote,'local ACTIVITY_PHASE={Reach=true}',"Activity checkpoint-only whitelist")
need(remote,'ACTIVITY_PHASE[c]==true',"Activity phase whitelist")
need(remote,'if knownRevision~=nil and not integer(knownRevision,0,2147483647)',"StateRequest revision validation")
need(remote,'if not self:Accept(player) then',"global per-player remote rate limit")
need(remote,'xpcall(function() return self.X:Request(player,action,a,b,c) end,debug.traceback)',"request traceback capture")
need(remote,'[SERVER_ERROR][',"server error diagnostic marker")
need(remote,'message="Server error ["..requestErrorId.."] — see Output"',"client-visible error correlation id")
need(remote,'local finalReason=ok and (reason or (result==false and "ACTION_UNAVAILABLE" or nil)) or "SERVER_ERROR"',"false nil result is not mislabeled SERVER_ERROR")
need(activity,'if not o then return false,"STALE_ACTIVITY" end',"stale activity reason")
need(activity,'if index~=o.Index then return false,"STALE_ACTIVITY" end',"stale activity index reason")

# Server authority / progression invariants behind validated remotes.
need(roll,'not p.Tutorial.FeatureUnlocks.Roll',"Roll progression lock")
need(roll,'os.clock()-(self.Last[player] or -100)<cd',"Roll server cooldown")
need(inventory,'(p.Pollinators.BeeInventory[id] or 0)<1',"Bee ownership validation")
need(inventory,'self:Available(p,id)<n',"Dissolve free-copy validation")
need(garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"Plant proximity validation")
need(garden,'self.X.InventoryService:Available(p,id)<1',"Plant ownership validation")
need(activity,'index~=o.Index',"Activity step-order validation")
need(activity,'o.Expires<workspace:GetServerTimeNow()',"Activity expiry validation")
need(activity,'phase~="Reach"',"Activity checkpoint-only server path")
need(activity,'self.X.U.WithinCheckpoint(player,o.Nodes[o.Index],checkpointRadius,A.CheckpointVerticalTolerance)',"Activity checkpoint distance validation")
need(workshop,'if w.Points<(n.Cost or 0)',"Workshop point cost validation")
need(workshop,'if p.Currencies.Coins<(n.Coins or 0)',"Workshop coin cost validation")
need(trials,'self.X.MapService:Sector(player)~=cfg.Sector',"Trial sector validation")
need(trials,'self.X.U.Near(player,pos,14)',"Trial shrine proximity validation")
need(season,'q.Token~=token',"Season confirmation token validation")
need(season,'q.Revision~=self.X.Revisions[player] or not self.X.U.Equal(q.Before,p)',"Season stale-state validation")

print("remote security contract: PASS")
print(f"Validated routed actions: {len(actions)}")
print("Server authority verified for roll, inventory, planting, activities, Workshop, trials and Season Turn.")
