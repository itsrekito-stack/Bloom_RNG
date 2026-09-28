#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
rules=read("src/ReplicatedStorage/Shared/GardenRules.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
flower_progress=read("src/ServerScriptService/Services/FlowerProgressionService.luau")
synergy=read("src/ServerScriptService/Services/GardenSynergyService.luau")
recipes=read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau")
domain=read("src/ServerScriptService/Data/ProfileDomain.luau")
presentation=read("src/StarterPlayer/StarterPlayerScripts/Controllers/GardenPresentationController.luau")
activity_cfg=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
activity_service=read("src/ServerScriptService/Services/GardenActivityService.luau")

need(bloom,"MaxFlowerSlots=7","garden hard cap is seven flowers")
need(bloom,"StartingSlots=0","fresh garden starts at zero slots")
need(bloom,"GardenSlotHiveMilestones={2,3,4,5,6,7}","static Hive garden milestones")
need(rules,"local first=(events.FirstGardenSlot or 0)>0 or tutorial.Skipped==true","tutorial owns first Garden slot")
need(rules,"milestoneCount(p.Hive.Level,C.GardenSlotHiveMilestones)","Hive milestones own later Garden slots")
if "WorkshopEffects" in rules or "GARDEN_1" in rules:
    raise AssertionError("Workshop capacity dependency returned")

need(inventory,'f.OwnedSeedCopies[id]=1',"first Flower unlock creates one owned species")
need(inventory,'f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1',"Flower obtained count is tracked")
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"Flower duplicates advance species progression")
need(flower_progress,"function S:AddDuplicate(player,id,count)","duplicate-driven Flower progression entry point")
need(flower_progress,"count*C.FlowerDuplicateXP","duplicate Flower XP comes from config")
need(inventory,'function S:Dissolve()',"obsolete flower dissolve endpoint remains safely rejected")
need(inventory,'return false,"ACTION_UNAVAILABLE"',"copy-stock actions are rejected")

need(garden,"local mastery=self.X.FlowerProgressionService:State(p,slot.SpeciesId)","Garden renders species-wide Flower level")
need(garden,"slot.TotalPollination=math.max(0,tonumber(slot.TotalPollination) or 0)+amount","pollination telemetry remains slot-local")
if "self.X.FlowerProgressionService:Add(player,slot.SpeciesId,amount)" in garden:
    raise AssertionError("routine pollination still advances Flower Level")
need(garden,'if slotIndex~=i and existing.SpeciesId==id then return false,"ALREADY_PLANTED" end',"same Flower species cannot occupy two Garden slots")
need(garden,'slot={SpeciesId=id,TotalPollination=0,Mutation=""}',"Garden slot no longer owns Level/XP")
if "Rules.HasProgress(old)" in garden:
    raise AssertionError("replacement is still blocked by obsolete slot progression")

need(synergy,"local best,bestSlots=nil,nil","synergy evaluation chooses a single winner")
need(synergy,'(recipe.Strength or 0)>(best.Strength or 0)',"stronger valid synergy replaces weaker nested one")
need(synergy,"p.Garden.ActiveSynergy=best.Id","authoritative active synergy is persisted")
need(synergy,"function S:Hint(profile)","near-complete hidden synergy hint exists")
need(synergy,"return candidates[1] and {FlowerId=candidates[1].FlowerId} or nil","hint reveals only owned Flower suggestion")
need(recipes,'Id="MeadowRing",Name="Sevenfold Garden"',"seven-flower high-tier synergy ships")
need(recipes,'Species={"Daisy","Tulip","Sunflower","Clover","CrystalRose","FrostLily","PrismBloom"}',"seven-flower synergy matches garden cap")
need(recipes,"Levels={","synergies can require per-Flower levels")
need(recipes,"Strength=","synergy strength hierarchy exists")

need(domain,'error("DUPLICATE_GARDEN_SPECIES:"..id)',"profile validation rejects duplicated planted species")
need(domain,'D.Archive(p,"Garden.LegacySlotProgress"', "legacy slot Level/XP is archived")
need(domain,'D.Archive(p,"Garden.OverflowSlots"', "overflow slots are archived safely")

need(recipes,'((i-1)/Bloom.MaxFlowerSlots)*math.pi*2',"seven slots share one deterministic ring")
need(garden,'for i=1,C.MaxFlowerSlots do',"all configured Garden slots are built")
need(garden,'self.X.FlowerService.Build(i,f,pos)',"physical Flower models follow authoritative slots")
need(garden,'flowerVisualScale(mastery.Level,growth)',"world Flower scale follows species level")
if 'Instance.new("Beam")' in presentation or 'LocalSynergyLines' in presentation:
    raise AssertionError("persistent Garden beam clutter returned")
if '"Open Garden"' in garden:
    raise AssertionError("world Flower slots must not create Open Garden prompts")
need(activity_cfg,'PollenTrail={Life=35,Steps=7,Charge=8,CheckpointRadius=4.5}',"Pollen Trail has seven ground checkpoints")
need(activity_service,'local side=math.sin(t*math.pi*3)*4',"Pollen Trail spreads checkpoints laterally")

print("garden progression contract: PASS")
print("Seven-slot Hive progression, species-wide Flower levels, safe replacement and strongest-only Synergy are wired.")
