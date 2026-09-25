local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Default=require(script.Parent.DefaultProfile)
local Mapping=require(script.Parent.LegacyBloomMapping)
local Domain=require(script.Parent.ProfileDomain)
local S={}
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
 local n=U.Copy(p) local migrate=not(n.Migrations and n.Migrations.BloomReworkV1)
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

