local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Default=require(script.Parent.DefaultProfile)
local Mapping=require(script.Parent.LegacyBloomMapping)
local S={}
local function reconcile(p,d) for k,v in pairs(d) do if type(p[k])~=type(v) then p[k]=U.Copy(v) elseif type(v)=="table" then reconcile(p[k],v) end end end
local function valid(v,seen,depth)
 if depth>64 then return false,"Depth limit" end
 local t=type(v) if t=="number" then return v==v and math.abs(v)<math.huge,"Invalid number" end
 if t=="string" or t=="boolean" or t=="nil" then return true end
 if t~="table" or seen[v] then return false,"Unsupported/cyclic value" end seen[v]=true
 for k,x in pairs(v) do if type(k)~="string" and type(k)~="number" then return false,"Invalid key" end local ok,err=valid(x,seen,depth+1) if not ok then return ok,err end end seen[v]=nil return true
end
function S.Validate(p) if type(p)~="table" then return false,"Profile must be a table" end return valid(p,{},0) end
function S.CreateDefault() return U.Copy(Default) end
function S.Reconcile(p) if type(p)~="table" then return false,"Profile must be a table" end reconcile(p,Default) return true end
function S.Prepare(p)
 local ok,err=S.Validate(p) if not ok then return false,err end
 local n=U.Copy(p) local migrate=not(n.Migrations and n.Migrations.BloomReworkV1)
 -- Do not seed defaults into a returning player's empty garden or add starter inventory twice.
 local savedSlots=type(n.Garden)=="table" and type(n.Garden.Slots)=="table" and U.Copy(n.Garden.Slots)
 local savedCopies=type(n.FlowerCollection)=="table" and type(n.FlowerCollection.OwnedSeedCopies)=="table" and U.Copy(n.FlowerCollection.OwnedSeedCopies)
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
  n.LegacyArchive={AncientSeeds=legacyCurrencies.AncientSeeds or 0,ResearchNodes=p.ResearchNodes,WorkshopV2=p.WorkshopV2}
  n.World.UnlockedSectors.SunnyOrchard=legacySectors.StarterOrchard or false
  for _,id in ipairs({"CrystalGreenhouse","TwilightGrove"}) do n.World.UnlockedSectors[id]=legacySectors[id]==true or false end
  n.WorkshopV5.Points=math.max(n.WorkshopV5.Points,U.Number(legacyWorkshop.Points))
  n.Migrations.BloomSummary={PetalDust=dust,Version=C.SchemaVersion}
  -- Existing physical flowers are granted enough ownership to preserve their planted layout.
  local counts={} for _,slot in pairs(n.Garden.Slots) do if type(slot)=="table" and Flowers.Exists(slot.SpeciesId) then counts[slot.SpeciesId]=(counts[slot.SpeciesId] or 0)+1 end end
  for id,count in pairs(counts) do f.OwnedSeedCopies[id]=math.max(f.OwnedSeedCopies[id] or 0,count) f.DiscoveredFlowers[id]=true end
 end
 for _,k in ipairs({"Coins","PetalDust","AncientNectar"}) do n.Currencies[k]=U.Number(n.Currencies[k]) end
 n.Hive.Level=math.clamp(math.floor(U.Number(n.Hive.Level,1)),1,#C.HiveCosts)
 n.Garden.UnlockedSlots=math.clamp(math.floor(U.Number(n.Garden.UnlockedSlots,3)),3,C.MaxFlowerSlots)
 for id,count in pairs(n.FlowerCollection.OwnedSeedCopies) do n.FlowerCollection.OwnedSeedCopies[id]=math.floor(U.Number(count)) end
 for i=1,C.MaxFlowerSlots do local slot=n.Garden.Slots[i] or n.Garden.Slots[tostring(i)] or {} n.Garden.Slots[tostring(i)]=nil if type(slot)~="table" then slot={} end
  if i>n.Garden.UnlockedSlots or not Flowers.Exists(slot.SpeciesId) then slot={} else slot.Level=math.clamp(U.Number(slot.Level,1),1,C.MasteryCap) slot.XP=U.Number(slot.XP) slot.TotalPollination=U.Number(slot.TotalPollination) slot.Mutation=type(slot.Mutation)=="string" and slot.Mutation or "" end
  n.Garden.Slots[i]=slot
 end
 for id,count in pairs(n.Pollinators.BeeInventory) do n.Pollinators.BeeInventory[id]=Bees.Exists(id) and math.floor(U.Number(count)) or nil end
 local equipped={} local equippedCounts={}
 for i=1,C.MaxBeeSlots do local id=n.Pollinators.EquippedBeeSlots[i] or n.Pollinators.EquippedBeeSlots[tostring(i)]
  if type(id)=="string" and Bees.Exists(id) and (equippedCounts[id] or 0)<(n.Pollinators.BeeInventory[id] or 0) then equipped[i]=id equippedCounts[id]=(equippedCounts[id] or 0)+1 end
 end n.Pollinators.EquippedBeeSlots=equipped
 for id,m in pairs(n.Pollinators.BeeMastery) do if type(m)=="table" then n.Pollinators.BeeMastery[id]=U.Number(m.XP)+U.Number(m.Level)*25 else n.Pollinators.BeeMastery[id]=U.Number(m) end end
 for id,m in pairs(n.FlowerCollection.FlowerMastery) do if type(m)~="table" then m={Level=1,XP=0} n.FlowerCollection.FlowerMastery[id]=m end m.Level=math.clamp(U.Number(m.Level,1),1,C.MasteryCap) m.XP=U.Number(m.XP) end
 local planted={} for _,slot in ipairs(n.Garden.Slots) do if slot.SpeciesId then local id=slot.SpeciesId planted[id]=(planted[id] or 0)+1 if planted[id]>(n.FlowerCollection.OwnedSeedCopies[id] or 0) then table.clear(slot) end end end
 n.RollState.TotalRolls=math.floor(U.Number(n.RollState.TotalRolls)) n.RollState.DiscoveryPity=math.floor(U.Number(n.RollState.DiscoveryPity))
 n.RollState.BloomCharge=U.Number(n.RollState.BloomCharge,0,C.BloomMax) n.RollState.SpecialRollReady=n.RollState.BloomCharge>=C.BloomMax
 n.SchemaVersion=C.SchemaVersion
 for _,key in ipairs({"StarterFruitGranted","ClaimedIndexMilestones","Inventory","DiscoveredFruits","EquippedFruitIds","LockedFruits","FruitMastery","FruitCombos","ResearchNodes","WorkshopV2","WorkshopLevels","ActiveLocationTheme","OwnedLocations","UnlockedSectors","TutorialProgress","TutorialVersion","TutorialStep","TutorialSkipped"}) do n[key]=nil end
 n.Currencies.FruitDust=nil n.Currencies.AncientSeeds=nil n.Garden.OwnedFlowerTypes=nil
 n.Migrations.BloomReworkV1=true
 ok,err=S.Validate(n) if not ok then return false,err end
 table.clear(p) for k,v in pairs(n) do p[k]=v end return true
end
S.Create=S.CreateDefault S.Sanitize=S.Prepare
return S
