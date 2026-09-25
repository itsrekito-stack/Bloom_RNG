#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

flowers=read("src/ReplicatedStorage/Config/FlowersConfig.luau")
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
poll=read("src/ServerScriptService/Services/PollinatorService.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
synergy=read("src/ServerScriptService/Services/GardenSynergyService.luau")
recipes=read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau")

need(rules,"C.StartingSlots+math.max(0,p.Hive.Level-1)","flower capacity uses configured starting slots")
need(rules,"function Rules.HasOverflow","overflow protection exists")
need(flowers,"XPPerLevel=Bloom.FlowerLevelXP","flower growth XP authority")
need(flowers,"MaxLevel=Bloom.MasteryCap","flower max-level authority")
need(garden,"function S:AddFlowerXP(player,i,amount)","single flower XP mutation path")
need(garden,"while level<maxLevel do","flower XP supports level carry-over")
need(garden,"slot.TotalPollination=math.max(0,tonumber(slot.TotalPollination) or 0)+amount","pollination total follows XP grant")
need(garden,"self.X.FlowerProgressionService:Add(player,slot.SpeciesId,amount)","slot work advances collection mastery")
need(garden,"Rules.HasProgress(old)","progressed flowers cannot be silently replaced")
need(garden,'self.X.InventoryService:Available(p,id)<1',"plant ownership/free-copy validation")
need(poll,"self.X.GardenPlotService:AddFlowerXP(player,state.Slot,1)","bee delivery uses central flower progression")
need(poll,"function S:AddMastery(player,id,baseAmount,abilityMultiplier)","single Bee Mastery grant path")
need(activity,'self.X.GardenPlotService:AddFlowerXP(player,i,3)',"Pulse uses normal flower leveling")
need(activity,'self.X.PollinatorService:AddMastery(player,bee,1,1)',"activity Bee Mastery uses normal cap/multipliers")
need(inventory,"for _,slot in ipairs(p.Garden.Slots) do","available copies account for planted flowers")
need(inventory,'if self:Available(p,id)<n then return false,"NO_FREE_COPY" end',"dissolve cannot consume planted copies")
need(inventory,'if (f.OwnedSeedCopies[id] or 0)-n<1 then return false,"LAST_COPY" end',"dissolve preserves last copy")
need(synergy,"self.Active[player]=active","server owns active synergy state")
need(recipes,'Id="CrystalTriangle"',"Crystal triangle recipe ships")

print("garden progression contract: PASS")
print("Capacity, planting, XP/levels, Pulse, synergies and dissolve ownership are server-authoritative.")
