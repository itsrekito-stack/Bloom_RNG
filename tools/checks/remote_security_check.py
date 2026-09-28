#!/usr/bin/env python3
from pathlib import Path
import re
ROOT=Path(__file__).resolve().parents[2]
def read(p): return (ROOT/p).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

remote=read("src/ServerScriptService/Services/RemoteService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
quests=read("src/ServerScriptService/Services/QuestService.luau")
season=read("src/ServerScriptService/Services/SeasonService.luau")

actions=set(re.findall(r'action=="([A-Za-z0-9_]+)"',player));actions.add("SeasonCancel")
for action in sorted(actions):
    covered=(f'action=="{action}"' in remote) or re.search(rf'\b{re.escape(action)}=true\b',remote)
    if not covered: raise AssertionError(f"remote action lacks validation: {action}")

need(remote,'if not scalar(a) or not scalar(b) or not scalar(c) then return false,"INVALID_VALUE" end',"scalar payload guard")
need(remote,'integer(b,1,2147483647)',"Roll request id")
need(remote,'integer(a,1,C.MaxFlowerSlots)',"Garden slot bounds")
need(remote,'integer(b,1,C.MaxBeeSlots)',"Bee slot bounds")
need(remote,'or action=="EquipSynergy"', "Equip Synergy schema")
need(remote,'or action=="ClaimQuest"', "Quest claim schema")
need(remote,'if not self:Accept(player) then',"remote rate limit")
need(remote,'xpcall(function() return self.X:Request(player,action,a,b,c) end,debug.traceback)',"request traceback")

need(roll,'not p.Tutorial.FeatureUnlocks.Roll',"Roll lock")
need(roll,'os.clock()-(self.Last[player] or -100)<cd',"Roll cooldown")
need(inventory,'(p.Pollinators.BeeInventory[id] or 0)<1',"Bee ownership")
need(inventory,'function S:EquipTraitSynergy(player,traitId)',"synergy equip")
need(inventory,'if (tonumber(p.Pollinators.BeeInventory[beeId]) or 0)>0 then candidates[#candidates+1]=beeId end',"synergy Bee ownership")
need(inventory,'local target=0',"server chooses attainable synergy breakpoint")
need(inventory,'self.X.GardenSynergyService:Recalculate(player)',"post-equip synergy recalc")
assert 'temp.MenuOpen~=true or temp.MenuName~="Index"' not in inventory, "Equip Synergy must not depend on transient menu state"
need(player,'elseif action=="EquipSynergy" then return self.InventoryService:EquipTraitSynergy(player,a)',"synergy route")
need(player,'elseif action=="ClaimQuest" then return self.QuestService:Claim(player,a)',"quest route")

need(garden,'self.X.U.Near(player,pos,C.InteractionDistance)',"plant proximity")
need(activity,'if not o then return false,"STALE_ACTIVITY" end',"stale activity")
need(workshop,'if w.Points<(n.Cost or 0)',"Workshop point cost")
need(quests,'if current<target then return false,"QUEST_INCOMPLETE" end',"quest completion authority")
need(season,'q.Token~=token',"Season confirmation token")

for token in ("BuildTrialService",'action=="Trial"',"FeatureUnlocks.Trials","Quests.Trials"):
    if token in player or token in remote or token in quests:
        raise AssertionError(f"retired Trial path returned: {token}")

print("remote security contract: PASS")
print(f"Validated routed actions: {len(actions)}; roll/equipment/garden/activities/Workshop/quests/Season remain server-authoritative.")
