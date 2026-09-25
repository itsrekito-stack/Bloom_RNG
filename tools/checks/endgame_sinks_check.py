#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/BloomConfig.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
mastery=read("src/ServerScriptService/Services/FlowerProgressionService.luau")
workshop=read("src/ReplicatedStorage/Config/WorkshopConfig.luau")
workshop_service=read("src/ServerScriptService/Services/WorkshopService.luau")
season_plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
season_service=read("src/ServerScriptService/Services/SeasonService.luau")

# Flower duplicates already have a useful sink.
need(cfg,"DustPerCopy=3","flower duplicate dust value")
need(inventory,"function S:Available(p,id)","free flower copy accounting")
need(inventory,'if self:Available(p,id)<n then return false,"NO_FREE_COPY" end',"planted flower protection")
need(inventory,'if (f.OwnedSeedCopies[id] or 0)-n<1 then return false,"LAST_COPY" end',"flower last-copy protection")
need(inventory,"p.Currencies.PetalDust+=n*C.DustPerCopy","flower duplicate converts to Petal Dust")
need(inventory,"self.X.FlowerProgressionService:Add(player,id,n)","flower duplicate also advances Flower Mastery")
need(mastery,"p.Currencies.PetalDust-=cost","Petal Dust has a Flower Mastery sink")

# Bee duplicates now have a symmetric late-game dismantle path.
need(cfg,"BeeDustPerCopy=5","bee duplicate dust value")
need(inventory,"function S:AvailableBee(p,id)","free bee copy accounting")
need(inventory,"for _,beeId in pairs(p.Pollinators.EquippedBeeSlots) do","equipped bee copy accounting")
need(inventory,'if self:AvailableBee(p,id)<n then return false,"NO_FREE_COPY" end',"equipped bee protection")
need(inventory,'if (inv.BeeInventory[id] or 0)-n<1 then return false,"LAST_COPY" end',"bee last-copy protection")
need(inventory,"inv.BeeInventory[id]-=n","bee duplicate removal")
need(inventory,"p.Currencies.PetalDust+=n*C.BeeDustPerCopy","bee duplicate converts to Petal Dust")
need(inventory,'*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1)',"season duplicate bonus applies")
need(inventory,'*E.Value(p,"ECONOMY_3","DustYield",1)',"Workshop duplicate bonus applies")

# The mutation is reachable only through the validated server request.
need(remote,'action=="Dissolve" or action=="DissolveBee"',"bee dismantle remote schema")
need(player,'elseif action=="DissolveBee" then',"bee dismantle server route")
need(player,'return self.InventoryService:DissolveBee(player,a,b)',"bee dismantle service call")

# UI availability mirrors the server free-copy rules.
need(state,"Free=free","free bee copies projected")
need(state,"CanDissolve=free>0 and count>1","bee dismantle availability")
need(state,"DissolveValue=Bloom.BeeDustPerCopy","bee dismantle reward projected")
need(client,'controller:Send("DissolveBee",item.Id,1)',"Inventory V2 bee dismantle action")
need(client,'"DISMANTLE ×1  •  +"..tostring(item.DissolveValue or 0).." DUST"',"Inventory V2 dismantle reward copy")

# Coins and Petal Dust remain useful after the first progression pass.
need(workshop,"Coins=i*30","Workshop Coin cost scales with node depth")
need(workshop,'Dust=(branch=="ECONOMY" or branch=="BLOOM") and i*3 or 0',"Workshop Petal Dust sink branches")
need(workshop_service,"p.Currencies.Coins-=(n.Coins or 0)","Workshop Coin spend")
need(workshop_service,"p.Currencies.PetalDust-=(n.Dust or 0)","Workshop Petal Dust spend")
need(season_plan,"after.Currencies.Coins=0","Season Coin reset")
need(season_plan,"if not after.WorkshopV5.LegacyNodes[id] then","Season resets non-Legacy Workshop purchases")
need(season_plan,"after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)","Season refunds points only")
if "after.Currencies.PetalDust=0" in season_plan:
    raise AssertionError("Petal Dust should persist across Season Turn")

seasonal_coin_sink=sum(i*30 for i in range(1,7))*6
seasonal_dust_sink=sum(i*3 for i in range(1,7))*2
if seasonal_coin_sink!=3780:
    raise AssertionError(f"unexpected repeatable Workshop Coin sink: {seasonal_coin_sink}")
if seasonal_dust_sink!=126:
    raise AssertionError(f"unexpected repeatable Workshop Dust sink: {seasonal_dust_sink}")

# Ancient Nectar remains a long-term currency after the permanent Legacy tree is complete.
need(cfg,"NectarDistillCost=1","post-Legacy Nectar distill cost")
need(cfg,"NectarDistillDust=10","post-Legacy Nectar distill reward")
need(season_service,"function S:LegacyComplete(p)","Legacy completion gate")
need(season_service,'for i=1,6 do if not p.WorkshopV5.Nodes["LEGACY_"..i] then return false end end',"all six Legacy nodes required")
need(season_service,'if not self:LegacyComplete(p) then return false,"LEGACY_REQUIRED" end',"distill blocked before full Legacy")
need(season_service,'if p.Currencies.AncientNectar<cost then return false,"NECTAR_REQUIRED" end',"distill Nectar affordability")
need(season_service,"p.Currencies.AncientNectar-=cost","repeatable Ancient Nectar spend")
need(season_service,"p.Currencies.PetalDust+=Bloom.NectarDistillDust","distill reward")
need(remote,"DistillNectar=true","fixed-argument distill remote schema")
need(player,'elseif action=="DistillNectar" then return self.SeasonService:DistillNectar(player)',"distill server route")
need(state,"NectarDistill={","distill state projection")
need(state,"Unlocked=nectarUnlocked","distill unlock projection")
need(client,'controller:Send("DistillNectar")',"Inventory V2 distill action")
need(client,'"COMPLETE LEGACY TO DISTILL"',"pre-Legacy UI guidance")

# Full LEGACY_6 raises the Season reward to 7 Nectar; distillation creates a bounded useful conversion.
post_legacy_nectar_per_season=5+2
post_legacy_dust_per_season=post_legacy_nectar_per_season*10
if post_legacy_dust_per_season!=70:
    raise AssertionError(f"unexpected post-Legacy distill capacity: {post_legacy_dust_per_season} Dust/Season")
if post_legacy_dust_per_season>=seasonal_dust_sink:
    raise AssertionError("Nectar distillation should supplement, not fully replace, the seasonal Petal Dust sink")

print("endgame sinks: PASS")
print(f"Duplicate sinks protected; seasonal Workshop sinks {seasonal_coin_sink} Coins / {seasonal_dust_sink} Dust; post-Legacy Nectar can distill into up to {post_legacy_dust_per_season} Dust per base Season.")

