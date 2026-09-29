local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Default=require(script.Parent.DefaultProfile)
local Mapping=require(script.Parent.LegacyBloomMapping)
local Domain=require(script.Parent.ProfileDomain)
local S={}
local function addFlowerXP(m,xp)
 m.Level=math.max(1,math.floor(tonumber(m.Level) or 1));m.XP=math.max(0,tonumber(m.XP) or 0)+(tonumber(xp) or 0)
 while m.Level<C.MasteryCap and m.XP>=m.Level*C.MasteryXP do m.XP-=m.Level*C.MasteryXP;m.Level+=1 end
end
local function addBeeXP(total,xp)
 return Bees.GetMasteryState((tonumber(total) or 0)+(tonumber(xp) or 0)).TotalXP
end
local function reconcile(p,d) for k,v in pairs(d) do if type(p[k])~=type(v) then p[k]=U.Copy(v) elseif type(v)=="table" then reconcile(p[k],v) end end end
local function valid(v,seen,depth)
 if depth>64 then return false,"Depth limit" end
 local t=type(v) if t=="number" then return v==v and math.abs(v)<math.huge,"Invalid number" end
 if t=="string" or t=="boolean" or t=="nil" then return true end
 if t~="table" or seen[v] then return false,"Unsupported/cyclic value" end seen[v]=true
 for k,x in pairs(v) do if type(k)~="string" and type(k)~="number" then return false,"Invalid key" end if type(k)=="number" and (k~=k or math.abs(k)==math.huge) then return false,"Invalid numeric key" end local ok,err=valid(x,seen,depth+1) if not ok then return ok,err end end seen[v]=nil return true
end
function S.Validate(p) if type(p)~="table" then return false,"Profile must be a table" end return valid(p,{},0) end
function S.CreateDefault() return U.Copy(Default) end
function S.Reconcile(p) if type(p)~="table" then return false,"Profile must be a table" end reconcile(p,Default) return true end
local function prepareProfile(p)
 local ok,err=S.Validate(p) if not ok then return false,err end
 if type(p.SchemaVersion)=="number" and p.SchemaVersion>C.SchemaVersion then return false,"FUTURE_SCHEMA" end
 local n=U.Copy(p) local migrate=not(n.Migrations and n.Migrations.BloomReworkV1) local visionMigrate=not(n.Migrations and n.Migrations.GameVisionV1) local journeyMigrate=not(n.Migrations and n.Migrations.JourneyNoTrialV1) local trialsCleanup=not(n.Migrations and n.Migrations.TrialsRuntimeCleanupV2)
 -- Do not seed defaults into a returning player's empty garden or add starter inventory twice.
 local savedSlots=type(n.Garden)=="table" and type(n.Garden.Slots)=="table" and U.Copy(n.Garden.Slots)
 local savedCopies=type(n.FlowerCollection)=="table" and type(n.FlowerCollection.OwnedSeedCopies)=="table" and U.Copy(n.FlowerCollection.OwnedSeedCopies)
 local function preserveReplaced(source,defaults,path)
  for key,value in pairs(defaults) do
   if source[key]~=nil and type(source[key])~=type(value) then Domain.Archive(n,path,key,source[key])
   elseif type(value)=="table" and type(source[key])=="table" then preserveReplaced(source[key],value,path.."."..tostring(key)) end
  end
 end
 preserveReplaced(n,Default,"Profile")
 reconcile(n,Default)
 if savedSlots then n.Garden.Slots=savedSlots end
 if savedCopies then n.FlowerCollection.OwnedSeedCopies=savedCopies end
 if trialsCleanup then
  if n.Quests and n.Quests.Trials~=nil then Domain.Archive(n,"TrialsRuntimeCleanupV2","CompletedTrials",U.Copy(n.Quests.Trials)) n.Quests.Trials=nil end
  if n.Tutorial and n.Tutorial.FeatureUnlocks and n.Tutorial.FeatureUnlocks.Trials~=nil then Domain.Archive(n,"TrialsRuntimeCleanupV2","FeatureUnlock",n.Tutorial.FeatureUnlocks.Trials) n.Tutorial.FeatureUnlocks.Trials=nil end
  if n.Season and n.Season.CompletedGoals~=nil then Domain.Archive(n,"TrialsRuntimeCleanupV2","SeasonCompletedGoals",U.Copy(n.Season.CompletedGoals)) n.Season.CompletedGoals=nil end
  n.Migrations.TrialsRemovedV1=true
  n.Migrations.TrialsRuntimeCleanupV2=true
 end
 if migrate then
  local legacyCurrencies=type(p.Currencies)=="table" and p.Currencies or {}
  local legacyWorkshop=type(p.WorkshopV2)=="table" and p.WorkshopV2 or {}
  local legacySectors=type(p.UnlockedSectors)=="table" and p.UnlockedSectors or {}
  local f=n.FlowerCollection local dust=U.Number(legacyCurrencies.FruitDust)
  for id,count in pairs(type(p.Inventory)=="table" and p.Inventory or {}) do
   count=math.floor(U.Number(count)) local target=Mapping[id]
   if target then f.OwnedSeedCopies[target]=(f.OwnedSeedCopies[target] or 0)+count else dust=dust+count*C.UnknownCopyDust end
  end
  for id,discovered in pairs(type(p.DiscoveredFruits)=="table" and p.DiscoveredFruits or {}) do if discovered and Mapping[id] then f.DiscoveredFlowers[Mapping[id]]=true end end
  for id,m in pairs(type(p.FruitMastery)=="table" and p.FruitMastery or {}) do
   local target=Mapping[id] if target then local level=type(m)=="table" and m.Level or m
    local previous=f.FlowerMastery[target] or {Level=1,XP=0}
    previous.Level=math.max(previous.Level,math.clamp(U.Number(level,1),1,C.MasteryCap)) f.FlowerMastery[target]=previous
   end
  end
  for _ in pairs(type(p.FruitCombos)=="table" and type(p.FruitCombos.Discovered)=="table" and p.FruitCombos.Discovered or {}) do dust=dust+C.ComboCompensation end
  n.Currencies.PetalDust=U.Number(n.Currencies.PetalDust)+dust
  -- AncientSeeds provenance is ambiguous: archive, do not turn it into earned Nectar.
  if type(n.LegacyArchive)~="table" then n.LegacyArchive={PreviousArchive=n.LegacyArchive} end
  n.LegacyArchive.AncientSeeds=n.LegacyArchive.AncientSeeds or legacyCurrencies.AncientSeeds or 0
  n.LegacyArchive.ResearchNodes=n.LegacyArchive.ResearchNodes or U.Copy(p.ResearchNodes)
  n.LegacyArchive.WorkshopV2=n.LegacyArchive.WorkshopV2 or U.Copy(p.WorkshopV2)
  n.World.UnlockedSectors.SunnyOrchard=legacySectors.StarterOrchard or false
  for _,id in ipairs({"CrystalGreenhouse","TwilightGrove"}) do n.World.UnlockedSectors[id]=legacySectors[id]==true or false end
  n.WorkshopV5.Points=math.max(n.WorkshopV5.Points,U.Number(legacyWorkshop.Points))
  n.Migrations.BloomSummary={PetalDust=dust,Version=C.SchemaVersion}
  -- Existing physical flowers are granted enough ownership to preserve their planted layout.
  local counts={} for _,slot in pairs(n.Garden.Slots) do if type(slot)=="table" and Flowers.Exists(slot.SpeciesId) then counts[slot.SpeciesId]=(counts[slot.SpeciesId] or 0)+1 end end
  for id,count in pairs(counts) do f.OwnedSeedCopies[id]=math.max(f.OwnedSeedCopies[id] or 0,count) f.DiscoveredFlowers[id]=true end
 end
 if journeyMigrate then
  local oldStep=math.max(1,math.floor(tonumber(n.Quests and n.Quests.JourneyStep) or 1))
  local claimed=n.Quests and n.Quests.Claimed or {}
  if oldStep>=16 then
   claimed.Journey_14=claimed.Journey_15==true or nil
   claimed.Journey_15=nil
   n.Quests.JourneyStep=15
  elseif oldStep==15 then
   claimed.Journey_14=nil
   n.Quests.JourneyStep=14
  end
  n.Migrations.JourneyNoTrialV1=true
 end
 if visionMigrate then
  local f=n.FlowerCollection
  f.ObtainedFlowers=type(f.ObtainedFlowers)=="table" and f.ObtainedFlowers or {}
  local plantedSeen={}
  for key,slot in pairs(type(n.Garden.Slots)=="table" and n.Garden.Slots or {}) do
   if type(slot)=="table" and Flowers.Exists(slot.SpeciesId) then
    local id=slot.SpeciesId
    f.DiscoveredFlowers[id]=true
    f.OwnedSeedCopies[id]=math.max(1,math.floor(tonumber(f.OwnedSeedCopies[id]) or 0))
    f.ObtainedFlowers[id]=math.max(1,math.floor(tonumber(f.ObtainedFlowers[id]) or 0))
    local m=f.FlowerMastery[id] or {Level=1,XP=0}
    f.FlowerMastery[id]=m
    local slotLevel=math.max(1,math.floor(tonumber(slot.Level) or 1))
    local slotXP=math.max(0,tonumber(slot.XP) or 0)
    if slotLevel>(tonumber(m.Level) or 1) or (slotLevel==(tonumber(m.Level) or 1) and slotXP>(tonumber(m.XP) or 0)) then
     m.Level=slotLevel;m.XP=slotXP
    end
    local index=tonumber(key)
    if plantedSeen[id] or not index or index%1~=0 or index<1 or index>C.MaxFlowerSlots then
     Domain.Archive(n,"GameVisionV1.GardenSlots",key,slot)
     n.Garden.Slots[key]={}
    else
     plantedSeen[id]=true
    end
   end
  end
  for id,count in pairs(f.OwnedSeedCopies) do
   local owned=math.max(0,math.floor(tonumber(count) or 0))
   if owned>0 and Flowers.Exists(id) then
    f.DiscoveredFlowers[id]=true
    f.ObtainedFlowers[id]=math.max(math.floor(tonumber(f.ObtainedFlowers[id]) or 0),owned)
    local m=f.FlowerMastery[id] or {Level=1,XP=0}
    f.FlowerMastery[id]=m
    if owned>1 then addFlowerXP(m,(owned-1)*C.FlowerDuplicateXP) end
    f.OwnedSeedCopies[id]=1
   end
  end
  local b=n.Pollinators
  b.BeeObtained=type(b.BeeObtained)=="table" and b.BeeObtained or {}
  for id,count in pairs(b.BeeInventory) do
   local owned=math.max(0,math.floor(tonumber(count) or 0))
   if owned>0 and Bees.Exists(id) then
    b.DiscoveredBees[id]=true
    b.BeeObtained[id]=math.max(math.floor(tonumber(b.BeeObtained[id]) or 0),owned)
    if owned>1 then b.BeeMastery[id]=addBeeXP(b.BeeMastery[id],(owned-1)*C.BeeDuplicateXP) end
    b.BeeInventory[id]=1
   end
  end
  local oldUnlocked=math.max(0,math.floor(tonumber(n.Garden.UnlockedSlots) or 0))
  local hasPlanted=next(plantedSeen)~=nil
  if oldUnlocked>0 or hasPlanted then n.Tutorial.Events.FirstGardenSlot=math.max(1,tonumber(n.Tutorial.Events.FirstGardenSlot) or 0) end
  local hiveLevel=tonumber(n.Hive.Level)
  if type(hiveLevel)~="number" or hiveLevel~=hiveLevel or math.abs(hiveLevel)==math.huge then hiveLevel=1 end
  hiveLevel=math.max(1,math.floor(hiveLevel))
  local capacity=(n.Tutorial.Events.FirstGardenSlot or 0)>0 and 1 or 0
  for _,required in ipairs(C.GardenSlotHiveMilestones or {}) do if hiveLevel>=required then capacity+=1 end end
  capacity=math.min(C.MaxFlowerSlots,capacity)
  for key,slot in pairs(n.Garden.Slots) do
   local index=tonumber(key)
   if index and index%1==0 and index>capacity and type(slot)=="table" and next(slot)~=nil then
    Domain.Archive(n,"GameVisionV1.CapacityOverflow",key,slot)
    n.Garden.Slots[key]={}
   end
  end
  n.Garden.UnlockedSlots=capacity
  n.Garden.ActiveSynergy=""
  Domain.Archive(n,"GameVisionV1","StarterBeeGranted",n.StarterBeeGranted)
  n.StarterBeeGranted=nil
  n.Migrations.GameVisionV1=true
 end
 Domain.Apply(n)
 n.SchemaVersion=C.SchemaVersion
 for _,key in ipairs({"StarterFruitGranted","ClaimedIndexMilestones","Inventory","DiscoveredFruits","EquippedFruitIds","LockedFruits","FruitMastery","FruitCombos","ResearchNodes","WorkshopV2","WorkshopLevels","ActiveLocationTheme","OwnedLocations","UnlockedSectors","TutorialProgress","TutorialVersion","TutorialStep","TutorialSkipped"}) do Domain.Archive(n,"LegacyFields",key,n[key]);n[key]=nil end
 Domain.Archive(n,"LegacyCurrencies","FruitDust",n.Currencies.FruitDust)
 Domain.Archive(n,"LegacyCurrencies","AncientSeeds",n.Currencies.AncientSeeds)
 Domain.Archive(n,"LegacyGarden","OwnedFlowerTypes",n.Garden.OwnedFlowerTypes)
 n.Currencies.FruitDust=nil n.Currencies.AncientSeeds=nil n.Garden.OwnedFlowerTypes=nil
 n.Migrations.BloomReworkV1=true
 ok,err=S.Validate(n) if not ok then return false,err end
 table.clear(p) for k,v in pairs(n) do p[k]=v end return true
end
function S.Prepare(p)
 local ok,result,reason=pcall(prepareProfile,p)
 if not ok then return false,tostring(result) end
 return result,reason
end
S.Create=S.CreateDefault S.Sanitize=S.Prepare
return S

