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

print("endgame duplicate sinks: PASS")
print("Flower and bee extra copies both have protected server-authoritative Petal Dust sinks.")
