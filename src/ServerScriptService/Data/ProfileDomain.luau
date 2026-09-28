-- Active-domain checks run on a candidate copy; rejection never mutates the caller.
local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local F=require(RS.Config.FlowersConfig)
local B=require(RS.Config.BeesConfig)
local W=require(RS.Config.WorkshopConfig)
local R=require(RS.Config.RarityConfig)
local L=require(RS.Config.LocationsConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local Seasons=require(RS.Config.SeasonConfig)
local Features=require(RS.Config.FeatureUnlockConfig)
local Tutorial=require(RS.Config.TutorialConfig)
local GardenSynergy=require(RS.Config.GardenSynergyConfig)
local Rules=require(RS.Shared.GardenRules)
local SYNERGY_IDS={} for _,recipe in ipairs(GardenSynergy.Recipes) do SYNERGY_IDS[recipe.Id]=true end
local TRAIT_IDS={} for id in pairs(B.Traits) do TRAIT_IDS[id]=true end
local D={}
local MAX_SAFE=9007199254740991 -- representation bound, not a gameplay progression cap
function D.Archive(p,path,key,value)
 if value==nil then return end
 if type(p.LegacyArchive)~="table" then
  p.LegacyArchive={PreviousArchive=p.LegacyArchive}
 end
 local archive=p.LegacyArchive
 if type(archive.DomainV1)~="table" then archive.DomainV1={Previous=archive.DomainV1} end
 local bucket=archive.DomainV1[path]
 if type(bucket)~="table" then bucket={Previous=bucket};archive.DomainV1[path]=bucket end
 key=tostring(key)
 if bucket[key]==nil then bucket[key]=U.Copy(value) end
end
local function number(p,t,key,path,default,integer,max)
 local old=t[key]
 local value=old
 if type(value)~="number" then value=default or 0 end
 if value~=value or math.abs(value)==math.huge then error("NONFINITE:"..path.."."..key) end
 if math.abs(value)>MAX_SAFE then error("UNSAFE_NUMBER:"..path.."."..key) end
 value=math.max(0,value)
 if integer then value=math.floor(value) end
 if max then value=math.min(max,value) end
 if old~=value then D.Archive(p,path,key,old) end
 t[key]=value
 return value
end
local function map(p,t,path,registry,kind)
 for key,value in pairs(t) do
  if type(key)~="string" or (registry and not registry[key]) then
   D.Archive(p,path,key,value);t[key]=nil
  elseif kind=="flag" then
   if type(value)~="boolean" then D.Archive(p,path,key,value);t[key]=nil end
  elseif kind=="count" then number(p,t,key,path,0,true)
  else number(p,t,key,path,0,false) end
 end
end
local function fields(p,t,path,names,integer)
 for _,key in ipairs(names) do number(p,t,key,path,0,integer) end
end
function D.Apply(p)
 fields(p,p.Currencies,"Currencies",{"Coins","PetalDust","AncientNectar"},false)
 number(p,p.Hive,"Level","Hive",1,true,#C.HiveCosts)
 if p.Hive.Level<1 then p.Hive.Level=1 end
 fields(p,p.Hive,"Hive",{"Honey","TotalHoney"},false)
 local w=p.WorkshopV5
 number(p,w,"Points","WorkshopV5",0,true)
 map(p,w.Nodes,"WorkshopV5.Nodes",W.Nodes,"flag")
 map(p,w.LegacyNodes,"WorkshopV5.LegacyNodes",W.Nodes,"flag")
 for id,value in pairs(w.Nodes) do
  if not value then w.Nodes[id]=nil
  elseif W.Nodes[id].Permanent then w.LegacyNodes[id]=true end
 end
 for id,value in pairs(w.LegacyNodes) do
  if not value then w.LegacyNodes[id]=nil
  elseif not W.Nodes[id].Permanent then D.Archive(p,"WorkshopV5.LegacyNodes",id,value);w.LegacyNodes[id]=nil end
 end
 -- Sources use dynamic season/hive/collection/trial ids. Preserve every string
 -- source but require boolean claims; never refund/re-grant points during repair.
 map(p,w.ClaimedSources,"WorkshopV5.ClaimedSources",nil,"flag")
 local f=p.FlowerCollection
 map(p,f.OwnedSeedCopies,"FlowerCollection.OwnedSeedCopies",F.Species,"count")
 for _,key in ipairs({"DiscoveredFlowers","LockedFlowers","FavoriteFlowers"}) do map(p,f[key],"FlowerCollection."..key,F.Species,"flag") end
 for id,count in pairs(f.OwnedSeedCopies) do if count>0 then f.DiscoveredFlowers[id]=true end end
 for id,m in pairs(f.FlowerMastery) do
  if not F.Species[id] then D.Archive(p,"FlowerCollection.FlowerMastery",id,m);f.FlowerMastery[id]=nil
  else
   if type(m)~="table" then D.Archive(p,"FlowerCollection.FlowerMastery",id,m);m={};f.FlowerMastery[id]=m end
   number(p,m,"Level","FlowerMastery."..id,1,true,C.MasteryCap);m.Level=math.max(1,m.Level)
   number(p,m,"XP","FlowerMastery."..id,0,false)
  end
 end
 local b=p.Pollinators
 map(p,b.BeeInventory,"Pollinators.BeeInventory",B.Bees,"count")
 map(p,b.DiscoveredBees,"Pollinators.DiscoveredBees",B.Bees,"flag")
 for id,count in pairs(b.BeeInventory) do if count>0 then b.DiscoveredBees[id]=true end end
 for id,m in pairs(b.BeeMastery) do
  if type(m)=="table" and B.Bees[id] then
   D.Archive(p,"Pollinators.BeeMastery",id,m)
   number(p,m,"XP","BeeMastery."..id,0,false);number(p,m,"Level","BeeMastery."..id,0,true)
   b.BeeMastery[id]=m.XP+m.Level*25
  end
 end
 map(p,b.BeeMastery,"Pollinators.BeeMastery",B.Bees,"number")
 local capacity=Rules.FlowerCapacity(p)
 local slots,planted={},{}
 for key,slot in pairs(p.Garden.Slots) do
  local index=tonumber(key)
  if index and index%1==0 and index>C.MaxFlowerSlots then
   if Rules.HasState(slot) or type(slot)~="table" then D.Archive(p,"Garden.OverflowSlots",key,slot) end
  elseif not index or index%1~=0 or index<1 then
   if Rules.HasState(slot) or type(slot)~="table" then error("INVALID_GARDEN_SLOT:"..tostring(key)) end
  else
   if slots[index] and not U.Equal(slots[index],slot) then error("CONFLICTING_GARDEN_SLOT:"..index) end
   slots[index]=slot
  end
 end
 for i=1,C.MaxFlowerSlots do
  local slot=slots[i] or {}
  if type(slot)~="table" then error("INVALID_GARDEN_SLOT:"..i) end
  if Rules.HasState(slot) then
   if i>capacity then error("GARDEN_CAPACITY_CONFLICT:"..i) end
   if type(slot.SpeciesId)~="string" or not F.Species[slot.SpeciesId] then error("UNKNOWN_PLANTED_FLOWER:"..i) end
   local id=slot.SpeciesId
   planted[id]=(planted[id] or 0)+1
   if planted[id]>(f.OwnedSeedCopies[id] or 0) then error("GARDEN_OWNERSHIP_CONFLICT:"..i) end
   number(p,slot,"Level","Garden.Slots."..i,1,true,C.MasteryCap);slot.Level=math.max(1,slot.Level)
   fields(p,slot,"Garden.Slots."..i,{"XP","TotalPollination"},false)
   if slot.Mutation==nil then slot.Mutation="" elseif type(slot.Mutation)~="string" then error("INVALID_MUTATION:"..i) end
   -- Unknown mutation strings/extra slot metadata are retained, not erased.
  end
  slots[i]=slot
 end
 p.Garden.Slots=slots;p.Garden.UnlockedSlots=capacity
 number(p,p.Garden,"Revision","Garden",0,true)
 local equipped,used={},{}
 local beeCapacity=Rules.BeeCapacity(p)
 for i=1,beeCapacity do
  local id=b.EquippedBeeSlots[i] or b.EquippedBeeSlots[tostring(i)]
  if type(id)=="string" and B.Bees[id] and (used[id] or 0)<(b.BeeInventory[id] or 0) then
   equipped[i]=id;used[id]=(used[id] or 0)+1
  end
 end
 for key,id in pairs(b.EquippedBeeSlots) do
  if equipped[tonumber(key)]~=id then D.Archive(p,"Pollinators.EquippedBeeSlots",key,id) end
 end
 b.EquippedBeeSlots=equipped
 fields(p,p.RollState,"RollState",{"TotalRolls","DiscoveryPity"},true)
 number(p,p.RollState,"BloomCharge","RollState",0,false,C.BloomMax)
 p.RollState.SpecialRollReady=p.RollState.BloomCharge>=C.BloomMax
 for _,key in ipairs({"ReducedEffects","ShowOtherPollinators","HideOtherPlayersTokens","RareFeed","AutoDissolve"}) do
  if type(p.Settings[key])~="boolean" then D.Archive(p,"Settings",key,p.Settings[key]);p.Settings[key]=false end
 end
 number(p,p.Settings,"TokenSoundVolume","Settings",.5,false,1)
 number(p,p.Settings,"EffectiveLuck","Settings",0,false,1000000)
 map(p,p.Settings.DissolveRarities,"Settings.DissolveRarities",R.Rank,"flag")
 number(p,p.Season,"Count","Season",0,true)
 if p.Season.ActiveCard~="" and not table.find(Seasons.Cards,p.Season.ActiveCard) then D.Archive(p,"Season","ActiveCard",p.Season.ActiveCard);p.Season.ActiveCard="" end
 for key,id in pairs(p.Season.Keepsakes) do
  local valid=(key=="Flower" or key=="Flower2") and F.Species[id] or key=="Bee" and B.Bees[id]
  if not valid then D.Archive(p,"Season.Keepsakes",key,id);p.Season.Keepsakes[key]=nil end
 end
 map(p,p.Season.CompletedGoals,"Season.CompletedGoals",Trials,"flag")
 map(p,p.Quests.Trials,"Quests.Trials",Trials,"flag")
 map(p,p.Quests.Claimed,"Quests.Claimed",nil,"flag")
 number(p,p.Quests,"JourneyStep","Quests",1,true);p.Quests.JourneyStep=math.max(1,p.Quests.JourneyStep)
 number(p,p.Tutorial,"Step","Tutorial",1,true,#Tutorial.Steps+1);p.Tutorial.Step=math.max(1,p.Tutorial.Step)
 number(p,p.Tutorial,"Version","Tutorial",Tutorial.Version,true)
 map(p,p.Tutorial.Events,"Tutorial.Events",nil,"number")
 map(p,p.Tutorial.FeatureUnlocks,"Tutorial.FeatureUnlocks",Features,"flag")
 local sectors={Center=true};for id in pairs(L.Sectors) do sectors[id]=true end
 map(p,p.World.UnlockedSectors,"World.UnlockedSectors",sectors,"flag")
 map(p,p.World.LandmarkDiscoveries,"World.LandmarkDiscoveries",nil,"flag")
 map(p,p.World.EventStats,"World.EventStats",nil,"number")
 map(p,p.GardenSynergies.Discovered,"GardenSynergies.Discovered",nil,"flag")
 map(p,p.GardenSynergies.Mastery,"GardenSynergies.Mastery",nil,"number")
 map(p,p.Index.Read.Flowers,"Index.Read.Flowers",F.Species,"flag")
 map(p,p.Index.Read.Bees,"Index.Read.Bees",B.Bees,"flag")
 map(p,p.Index.Read.Synergies,"Index.Read.Synergies",SYNERGY_IDS,"flag")
 map(p,p.Index.Read.Traits,"Index.Read.Traits",TRAIT_IDS,"flag")
 for _,key in ipairs({"StarterBeeGranted"}) do
  if p[key]~=nil and type(p[key])~="boolean" then D.Archive(p,"Profile",key,p[key]);p[key]=false end
 end
 if p.Tutorial.Skipped~=nil and type(p.Tutorial.Skipped)~="boolean" then D.Archive(p,"Tutorial","Skipped",p.Tutorial.Skipped);p.Tutorial.Skipped=false end
 return true
end
return D
