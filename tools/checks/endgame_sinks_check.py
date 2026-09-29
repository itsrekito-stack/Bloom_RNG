#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/BloomConfig.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
workshop_service=read("src/ServerScriptService/Services/WorkshopService.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
season_service=read("src/ServerScriptService/Services/SeasonService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")

# Duplicates are progression, not disposable stock.
need(cfg,"FlowerDuplicateXP=25","Flower duplicate progression value")
need(cfg,"BeeDuplicateXP=20","Bee duplicate progression value")
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"Flower duplicate -> Level")
need(inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP*E.BranchProduct(p,"DUPLICATES","DuplicateXPMultiplier",1))',"Bee duplicate -> Mastery")
need(inventory,'function S:Dissolve()',"old Flower sink fails closed")
need(inventory,'function S:DissolveBee()',"old Bee sink fails closed")
if inventory.count('return false,"ACTION_UNAVAILABLE"')<2:
    raise AssertionError("legacy dismantle endpoints are not fail-closed")
if 'controller:Send("DissolveBee",item.Id,1)' in client:
    raise AssertionError("obsolete Bee dismantle UI returned")

# Coins and Petal Dust remain sinks in the authored Workshop.
need(workshop,"local COINS_BY_INDEX={100,250,700,1800,4500,10000}","Workshop Coin sink curve")
need(workshop,"Coins=COINS_BY_INDEX[i] or 0","Workshop nodes consume depth Coin curve")
need(workshop,'local DUST_BRANCHES={ECONOMY=true,BLOOM=true,FORTUNE=true,MASTERY=true,DISCOVERY=true,RARITY=true,DUPLICATES=true,MUTATION=true}',"Workshop Dust sink branches")
need(workshop_service,"p.Currencies.Coins-=(n.Coins or 0)","Workshop Coin spend")
need(workshop_service,"p.Currencies.PetalDust-=(n.Dust or 0)","Workshop Dust spend")
need(season_plan,"after.Currencies.Coins=0","Season Coin reset")
need(season_plan,"if not after.WorkshopV5.LegacyNodes[id] then","Season resets non-Legacy Workshop purchases")
need(season_plan,"after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)","Season refunds Workshop Points")
if "after.Currencies.PetalDust=0" in season_plan:
    raise AssertionError("Petal Dust must persist across Season Turn")

coin_curve=[100,250,700,1800,4500,10000]
seasonal_coin_sink=sum(coin_curve)*27
seasonal_dust_sink=sum([3,5,8,10,13,15])*8
if seasonal_coin_sink!=468450 or seasonal_dust_sink!=432:
    raise AssertionError("Workshop sink arithmetic changed unexpectedly")

# Ancient Nectar remains useful after permanent Legacy completion.
need(cfg,"NectarDistillCost=1","post-Legacy Nectar distill cost")
need(cfg,"NectarDistillDust=10","post-Legacy Nectar distill reward")
need(season_service,"function S:LegacyComplete(p)","Legacy completion gate")
need(season_service,'if not self:LegacyComplete(p) then return false,"LEGACY_REQUIRED" end',"distill blocked before Legacy")
need(season_service,"p.Currencies.AncientNectar-=cost","repeatable Nectar spend")
need(season_service,"p.Currencies.PetalDust+=Bloom.NectarDistillDust","Nectar distill reward")
need(remote,"DistillNectar=true","distill remote schema")
need(player,'elseif action=="DistillNectar" then return self.SeasonService:DistillNectar(player)',"distill server route")
need(state,"NectarDistill={","distill state projection")
need(client,'controller:Send("DistillNectar")',"Inventory distill action")

post_legacy_dust_per_season=(5+2)*10
if post_legacy_dust_per_season>=seasonal_dust_sink:
    raise AssertionError("Nectar distillation should supplement, not replace, seasonal Dust sinks")

print("endgame sinks: PASS")
print(f"Duplicates feed Level/Mastery; repeatable Workshop sinks remain {seasonal_coin_sink} Coins / {seasonal_dust_sink} Dust, with bounded post-Legacy Nectar conversion.")
