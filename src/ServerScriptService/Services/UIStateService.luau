local RS=game:GetService("ReplicatedStorage")
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Workshop=require(RS.Config.WorkshopConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local Locations=require(RS.Config.LocationsConfig)
local Bloom=require(RS.Config.BloomConfig)
local Rarity=require(RS.Config.RarityConfig)
local Effects=require(RS.Shared.WorkshopEffects)
local RollPool=require(RS.Config.RollPoolConfig)
local GardenSynergy=require(RS.Config.GardenSynergyConfig)

local S={}

local REASONS={
 PERSISTENCE_BUSY="A save is already running. Please try again shortly",
 PERSISTENCE_UNCONFIRMED="The save could not be confirmed. Please rejoin safely",
 RESPEC_GARDEN_OCCUPIED="Respec would remove occupied flower beds. Keep these capacity upgrades",
 GARDEN_PROGRESS_PROTECTED="This flower has progression. Replacing it would lose that progress",
 PROFILE_LOADING="Profile is still loading",
 NOT_STUDIO="This developer action is available only in Roblox Studio",
 SERVER_ERROR="Server error",
 ACTION_UNAVAILABLE="Action is currently unavailable",
 STALE_ACTIVITY="",
 ACTIVITY_EXPIRED="",
 ACTIVITY_CHANGED="",
 RATE_LIMITED="Too many requests, try again",
 LOCKED="Feature is still locked",
 FEATURE_LOCKED="Feature is still locked",
 INVALID_ACTION="Unknown action",
 INVALID_ITEM="Item not found",
 INVALID_SLOT="Unavailable slot",
 TUTORIAL_TARGET="Follow the highlighted tutorial target",
 INVALID_NODE="Node not found",
 INVALID_SETTING="Setting not found",
 INVALID_VALUE="Invalid value",
 NOT_DISCOVERED="Discover this item first",
 NOT_OWNED="You do not own this item",
 ALREADY_EQUIPPED="This Bee species is already equipped",
 NO_LOWER_RARITY_BEE="All equipped Bees are equally or more rare",
 ALREADY_PLANTED="This Flower species is already planted",
 NO_FREE_COPY="No free copy available",
 LAST_COPY="You cannot dissolve your last copy",
 PROTECTED="Item is protected",
 FAVORITE="Favorite items cannot be dissolved",
 OWNED="Upgrade already purchased",
 PARENT_REQUIRED="Purchase the previous node first",
 HIVE_REQUIRED="A higher Hive level is required",
 SEASON_REQUIRED="This branch unlocks after your first Season",
 POINTS_REQUIRED="Not enough Workshop Points",
 COINS_REQUIRED="Not enough Coins",
 DUST_REQUIRED="Not enough Petal Dust",
 NECTAR_REQUIRED="Not enough Ancient Nectar",
 LEGACY_REQUIRED="Complete all Legacy Workshop nodes first",
 MASTERY_MAX="Mastery is already at max level",
 TOO_FAR="Move closer to the object",
 WRONG_SECTOR="Move to the required location",
 SECTOR_LOCKED="Unlock this location first",
 TRIAL_LOCKED="Trials are still locked",
 ADVANCED_TRIAL_LOCKED="Unlock Advanced Trials in the Workshop",
 TRIAL_RUNNING="A trial is already running",
 ACTIVITY_UNAVAILABLE="Trial route could not spawn. Try again",
 COOLDOWN="Wait for the cooldown to finish",
 EMPTY_POOL="No rewards are available in the roulette",
 SEASON_PREVIEW_OPEN="Finish the Season confirmation first",
 FILTER_LOCKED="Unlock filters in the Workshop first",
 AUTO_DISSOLVE_LOCKED="Unlock Auto Dissolve in the Workshop first",
 NO_CHANGES="No upgrades available to reset",
 TUTORIAL_ROLL_LOCKED="Complete the tutorial to roll again",
 TUTORIAL_SINGLE_ROLL="Tutorial rolls are single-use",
 USE_GARDEN_MENU="Plant Flowers from the Garden menu",
 MENU_REQUIRED="Open the Garden menu to edit planting",
}

local function plantedCount(profile,id)
 local count=0
 for _,slot in ipairs(profile.Garden.Slots) do
  if slot.SpeciesId==id then count+=1 end
 end
 return count
end

local function workshopReason(profile,node)
 if not node or not node.Id then return "INVALID_NODE" end
 if node.Id=="CORE" then return "OWNED" end
 local state=profile.WorkshopV5
 if state.Nodes[node.Id] then return "OWNED" end
 if not profile.Tutorial.FeatureUnlocks.Workshop then return "FEATURE_LOCKED" end
 if node.Parent and node.Parent~="CORE" and not state.Nodes[node.Parent] then return "PARENT_REQUIRED" end
 if profile.Hive.Level<(node.Hive or 0) then return "HIVE_REQUIRED" end
 if node.Branch=="LEGACY" and profile.Season.Count==0 then return "SEASON_REQUIRED" end
 if state.Points<(node.Cost or 0) then return "POINTS_REQUIRED" end
 if profile.Currencies.Coins<(node.Coins or 0) then return "COINS_REQUIRED" end
 if profile.Currencies.PetalDust<(node.Dust or 0) then return "DUST_REQUIRED" end
 if profile.Currencies.AncientNectar<(node.Nectar or 0) then return "NECTAR_REQUIRED" end
 return nil
end

function S:Init(x)
 self.X=x
end

function S:ReasonText(reason)
 return REASONS[reason] or tostring(reason or "Action unavailable")
end

function S:Inventory(player,profile)
 local flowers={}
 for id,count in pairs(profile.FlowerCollection.OwnedSeedCopies) do
  local data=Flowers.Species[id]
  if data and count>0 then
   local planted=plantedCount(profile,id)
   local free=math.max(0,count-planted)
   local mastery=profile.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
   local locked=profile.FlowerCollection.LockedFlowers[id]==true
   local favorite=profile.FlowerCollection.FavoriteFlowers[id]==true
   table.insert(flowers,{
    Id=id,
    DisplayName=data.DisplayName,
    Rarity=data.Rarity,
    Count=1,
    Obtained=profile.FlowerCollection.ObtainedFlowers[id] or 1,
    Planted=planted,
    Free=free,
    Mastery={Level=mastery.Level or 1,XP=mastery.XP or 0,NextXP=(mastery.Level or 1)*Bloom.MasteryXP},
    Favorite=favorite,
    Protected=locked,
    CanDissolve=false,
    CanUpgrade=false,
    Odds=RollPool.FormatBaseOdds("FlowerSeed",id),
   })
  end
 end
 table.sort(flowers,function(a,b)
  if a.Rarity==b.Rarity then return a.DisplayName<b.DisplayName end
  return (Rarity.Rank[a.Rarity] or 0)<(Rarity.Rank[b.Rarity] or 0)
 end)

 local bees={}
 local equippedCounts={}
 for slot,id in pairs(profile.Pollinators.EquippedBeeSlots) do
  if type(slot)=="number" and type(id)=="string" then
   equippedCounts[id]=(equippedCounts[id] or 0)+1
  end
 end
 for id,count in pairs(profile.Pollinators.BeeInventory) do
  local bee=Bees.Get(id)
  if bee and count>0 then
   local mastery=Bees.GetMasteryState(profile.Pollinators.BeeMastery[id])
   local equipped=equippedCounts[id] or 0
   local free=equipped>0 and 0 or 1
   table.insert(bees,{
    Id=id,
    DisplayName=bee.DisplayName,
    Rarity=bee.Rarity,
    Count=1,
    Obtained=profile.Pollinators.BeeObtained[id] or 1,
    Equipped=equipped,
    Free=free,
    CanDissolve=false,
    DissolveValue=0,
    Traits=bee.Traits,
    Ability=bee.Ability and bee.Ability.Name or "",
    Mastery=mastery,
    Odds=RollPool.FormatBaseOdds("Bee",id),
   })
  end
 end
 table.sort(bees,function(a,b)
  local aa=Bees.Get(a.Id) local bb=Bees.Get(b.Id)
  return (aa and aa.SortOrder or 999)<(bb and bb.SortOrder or 999)
 end)

 local nectarUnlocked=self.X.SeasonService:LegacyComplete(profile)
 return {
  Flowers=flowers,
  Bees=bees,
  FlowerCapacity=self.X.StatsService:FlowerCapacity(profile),
  BeeCapacity=self.X.StatsService:BeeCapacity(profile),
  EquippedBeeSlots=self.X.U.Copy(profile.Pollinators.EquippedBeeSlots),
  Keepsakes=self.X.U.Copy(profile.Season.Keepsakes),
  Traits=Bees.GetTraitState(profile.Pollinators.EquippedBeeSlots),
  NectarDistill={
   Unlocked=nectarUnlocked,
   CanDistill=nectarUnlocked and profile.Currencies.AncientNectar>=Bloom.NectarDistillCost,
   Cost=Bloom.NectarDistillCost,
   Dust=Bloom.NectarDistillDust,
  },
 }
end

function S:Workshop(player,profile)
 local nodes={}
 for id,node in pairs(Workshop.Nodes) do
  local reason=workshopReason(profile,node)
  local owned=id=="CORE" or profile.WorkshopV5.Nodes[id]==true
  local parentOwned=node.Parent=="CORE" or (node.Parent and profile.WorkshopV5.Nodes[node.Parent]==true) or node.Parent==nil
  local revealed=owned or id=="CORE" or parentOwned
  nodes[id]={
   Id=id,
   Owned=owned,
   Revealed=revealed,
   Available=revealed and reason==nil,
   Reason=revealed and reason or "PARENT_REQUIRED",
   ReasonText=revealed and reason and self:ReasonText(reason) or nil,
   Parent=node.Parent,
   Hive=revealed and (node.Hive or 0) or nil,
   Cost=revealed and (node.Cost or 0) or nil,
   Coins=revealed and (node.Coins or 0) or nil,
   Dust=revealed and (node.Dust or 0) or nil,
   Nectar=revealed and (node.Nectar or 0) or nil,
   Permanent=revealed and node.Permanent==true or false,
  }
 end
 return {Points=profile.WorkshopV5.Points,Nodes=nodes,CanRespec=false}
end

function S:Map(player,profile)
 local current=self.X.MapService:Sector(player)
 local sectors={}
 for _,id in ipairs(Locations.Order) do
  local cfg=Locations.Sectors[id]
  local unlocked=profile.World.UnlockedSectors[id]==true
  local hiveReady=profile.Hive.Level>=cfg.Hive
  local prerequisiteReady=not cfg.Requires or profile.World.UnlockedSectors[cfg.Requires]==true
  local gate=self.X.MapService.Gates[id]
  local nearGate=gate~=nil and self.X.U.Near(player,gate.Position,Bloom.InteractionDistance)
  local hint
  if unlocked then
   hint="Unlocked"
  elseif not prerequisiteReady then
   local required=Locations.Sectors[cfg.Requires]
   hint="Unlock "..(required and required.Name or cfg.Requires).." first"
  elseif not hiveReady then
   hint="Reach Hive "..cfg.Hive
  elseif nearGate then
   hint="Use the world gate prompt to unlock"
  else
   hint="Hive ready — go to the "..cfg.Name.." gate"
  end
  sectors[id]={
   Id=id,
   Name=cfg.Name,
   Unlocked=unlocked,
   Requires=cfg.Requires,
   PrerequisiteReady=prerequisiteReady,
   HiveRequired=cfg.Hive,
   HiveReady=hiveReady,
   NearGate=nearGate,
   Current=current==id,
   CanUnlock=not unlocked and prerequisiteReady and hiveReady and nearGate,
   UnlockHint=hint,
  }
 end
 return {
  CurrentSector=current,
  Sectors=sectors,
  LandmarkCount=self.X.U.Count(profile.World.LandmarkDiscoveries),
  Pulse=self.X.SocialService.Pulse,
 }
end

function S:Trials(player,profile)
 local list={}
 for id,cfg in pairs(Trials) do
  local reason=nil
  if self.X.BuildTrialService.Active[player] then reason="TRIAL_RUNNING"
  elseif not profile.Tutorial.FeatureUnlocks.Trials then reason="TRIAL_LOCKED"
  elseif cfg.Advanced and not Effects.Feature(profile,"LEGACY_4","AdvancedTrials") then reason="ADVANCED_TRIAL_LOCKED"
  end
  local startHint
  if reason=="TRIAL_RUNNING" then startHint="Finish the active trial first"
  elseif reason=="TRIAL_LOCKED" then startHint="Unlock Trials through Hive progression"
  elseif reason=="ADVANCED_TRIAL_LOCKED" then startHint="Unlock Advanced Trials in the Workshop"
  else startHint="Ready to start from Quests" end
  table.insert(list,{
   Id=id,
   Name=cfg.Name,
   Sector="Center",
   Advanced=cfg.Advanced==true,
   Completed=profile.Quests.Trials[id]==true,
   CanStart=reason==nil,
   NearShrine=true,
   Reason=reason,
   ReasonText=reason and self:ReasonText(reason) or nil,
   StartHint=startHint,
   Target=cfg.Target,
   Event=cfg.Event,
   Seconds=cfg.Seconds,
   RewardText=(profile.Quests.Trials[id] and "Repeat • 5 Coins" or (cfg.Advanced and "First clear • 3 Workshop Points" or "First clear • 2 Workshop Points")),
  })
 end
 table.sort(list,function(a,b) return a.Name<b.Name end)

 local active=self.X.BuildTrialService.Active[player]
 local activePublic=nil
 if active then
  local cfg=Trials[active.Id]
  activePublic={
   Id=active.Id,
   Advanced=active.Advanced==true,
   Counts=self.X.U.Copy(active.Counts or {}),
   TimeLeft=math.max(0,(cfg and cfg.Seconds or 0)-(os.clock()-(active.Start or os.clock()))),
  }
 end
 return {Items=list,Active=activePublic}
end
local function sortedFlowerIds()
 local ids={} for id in pairs(Flowers.Species) do table.insert(ids,id) end
 table.sort(ids,function(a,b)
  local x,y=Flowers.Species[a],Flowers.Species[b]
  local wx,wy=tonumber(x.DropWeight)or 0,tonumber(y.DropWeight)or 0
  if wx==wy then return tostring(x.DisplayName)<tostring(y.DisplayName) end
  return wx>wy
 end)
 return ids
end
local function sortedBeeIds()
 local ids={} for id in pairs(Bees.Bees) do table.insert(ids,id) end
 table.sort(ids,function(a,b)
  local x,y=Bees.Get(a),Bees.Get(b)
  return (x and x.SortOrder or 999)<(y and y.SortOrder or 999)
 end)
 return ids
end
local function traitDiscovered(profile,traitId)
 for beeId in pairs(profile.Pollinators.DiscoveredBees or {}) do
  local bee=Bees.Get(beeId)
  if bee and table.find(bee.Traits or {},traitId) then return true end
 end
 return false
end
local function progress(items)
 local unlocked=0 for _,item in ipairs(items) do if item.Unlocked then unlocked+=1 end end
 return {Unlocked=unlocked,Total=#items,Percent=#items>0 and math.floor(unlocked/#items*100+.5) or 0}
end

function S:Index(player,profile)
 local read=profile.Index and profile.Index.Read or {Flowers={},Bees={},Synergies={},Traits={}}
 local flowers={}
 for slot,id in ipairs(sortedFlowerIds()) do
  if profile.FlowerCollection.DiscoveredFlowers[id] then
   local cfg=Flowers.Species[id]
   local mastery=profile.FlowerCollection.FlowerMastery[id] or {Level=1}
   flowers[#flowers+1]={Slot=slot,Unlocked=true,Id=id,Name=cfg.DisplayName,Odds=RollPool.FormatBaseOdds("FlowerSeed",id),Level=mastery.Level or 1,New=read.Flowers[id]~=true}
  else
   flowers[#flowers+1]={Slot=slot,Unlocked=false}
  end
 end
 local bees={}
 for slot,id in ipairs(sortedBeeIds()) do
  if profile.Pollinators.DiscoveredBees[id] then
   local cfg=Bees.Get(id)
   bees[#bees+1]={Slot=slot,Unlocked=true,Id=id,Name=cfg.DisplayName,Odds=RollPool.FormatBaseOdds("Bee",id),Obtained=profile.Pollinators.BeeObtained[id] or 1,Mastery=Bees.GetMasteryState(profile.Pollinators.BeeMastery[id]),Traits=self.X.U.Copy(cfg.Traits or {}),Ability=cfg.Ability and self.X.U.Copy(cfg.Ability) or nil,New=read.Bees[id]~=true}
  else
   bees[#bees+1]={Slot=slot,Unlocked=false}
  end
 end
 local synergies={}
 for slot,recipe in ipairs(GardenSynergy.Recipes) do
  if profile.GardenSynergies.Discovered[recipe.Id] then
   synergies[#synergies+1]={Slot=slot,Unlocked=true,Id=recipe.Id,Name=recipe.Name or recipe.Id,Species=self.X.U.Copy(recipe.Species or {}),LevelRequirements=self.X.U.Copy(recipe.Levels or {}),Effect=self.X.U.Copy(recipe.Effect or {}),Tier=recipe.Tier or 1,Strength=recipe.Strength or 0,New=read.Synergies[recipe.Id]~=true}
  else
   synergies[#synergies+1]={Slot=slot,Unlocked=false}
  end
 end
 local traitIds={} for id in pairs(Bees.Traits) do table.insert(traitIds,id) end
 table.sort(traitIds,function(a,b)return tostring(Bees.Traits[a].Name)<tostring(Bees.Traits[b].Name)end)
 local traits={}
 for slot,id in ipairs(traitIds) do
  if traitDiscovered(profile,id) then
   local cfg=Bees.Traits[id]
   traits[#traits+1]={Slot=slot,Unlocked=true,Id=id,Name=cfg.Name,Description=cfg.Description,Breakpoints=self.X.U.Copy(cfg.Breakpoints or {}),BeeIds=Bees.GetTraitBees(id),BiomeModifiers={},New=read.Traits[id]~=true}
  else
   traits[#traits+1]={Slot=slot,Unlocked=false}
  end
 end
 return {
  Flowers={Items=flowers,Progress=progress(flowers)},
  Bees={Items=bees,Progress=progress(bees)},
  Synergies={Items=synergies,Progress=progress(synergies)},
  Traits={Items=traits,Progress=progress(traits)},
 }
end

function S:MarkIndexRead(profile,category,id)
 local read=profile.Index and profile.Index.Read
 if not read or type(read[category])~="table" then return false,"INVALID_VALUE" end
 local allowed=false
 if category=="Flowers" then allowed=Flowers.Exists(id) and profile.FlowerCollection.DiscoveredFlowers[id]==true
 elseif category=="Bees" then allowed=Bees.Exists(id) and profile.Pollinators.DiscoveredBees[id]==true
 elseif category=="Synergies" then allowed=profile.GardenSynergies.Discovered[id]==true
 elseif category=="Traits" then allowed=Bees.Traits[id]~=nil and traitDiscovered(profile,id)
 end
 if not allowed then return false,"NOT_DISCOVERED" end
 read[category][id]=true
 return true
end

function S:Settings(profile)
 return {
  EffectiveLuck=tonumber(profile.Settings.EffectiveLuck) or 0,
 }
end

function S:QuestTracker(profile)
 local nextLevel=(tonumber(profile.Hive.Level) or 1)+1
 local cost=Bloom.HiveUpgradeCost(nextLevel)
 local ready,text,current,target=self.X.HiveService:QuestStatus(profile,nextLevel)
 local objective=tostring(text or "Hive quest")
 objective=objective:match("^(.-) •") or objective
 return {Hive={
  Title="Hive "..tostring(nextLevel).." Quest",
  Text=objective,
  Current=tonumber(current) or (ready and 1 or 0),
  Target=math.max(1,tonumber(target) or 1),
  Complete=ready==true,
  Level=nextLevel,
 }}
end

function S:Snapshot(player)
 local profile=self.X:Profile(player)
 if not profile then return nil end
 return {
  Version=1,
  Inventory=self:Inventory(player,profile),
  Workshop=self:Workshop(player,profile),
  Map=self:Map(player,profile),
  Trials=self:Trials(player,profile),
  Settings=self:Settings(profile),
  QuestTracker=self:QuestTracker(profile),
  Garden={ActiveSynergy=profile.Garden.ActiveSynergy or "",Hint=Effects.Feature(profile,"GARDEN_5","PatternHints") and self.X.GardenSynergyService:Hint(profile) or nil},
  Index=self:Index(player,profile),
  Boosts=self.X.BoostService and self.X.BoostService:Snapshot(player,profile) or {Items={}},
 }
end

return S

