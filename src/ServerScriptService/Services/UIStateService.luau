local RS=game:GetService("ReplicatedStorage")
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Workshop=require(RS.Config.WorkshopConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local Locations=require(RS.Config.LocationsConfig)
local Bloom=require(RS.Config.BloomConfig)
local Rarity=require(RS.Config.RarityConfig)
local Effects=require(RS.Shared.WorkshopEffects)

local S={}

local REASONS={
 PERSISTENCE_BUSY="A save is already running. Please try again shortly",
 PERSISTENCE_UNCONFIRMED="The save could not be confirmed. Please rejoin safely",
 RESPEC_GARDEN_OCCUPIED="Respec would remove occupied flower beds. Keep these capacity upgrades",
 GARDEN_PROGRESS_PROTECTED="This flower has progression. Replacing it would lose that progress",
 PROFILE_LOADING="Profile is still loading",
 SERVER_ERROR="Server error",
 RATE_LIMITED="Too many requests, try again",
 LOCKED="Feature is still locked",
 FEATURE_LOCKED="Feature is still locked",
 INVALID_ACTION="Unknown action",
 INVALID_ITEM="Item not found",
 INVALID_SLOT="Unavailable slot",
 INVALID_NODE="Node not found",
 INVALID_SETTING="Setting not found",
 INVALID_VALUE="Invalid value",
 NOT_DISCOVERED="Discover this item first",
 NOT_OWNED="You do not own this item",
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
}

local function masteryCost(profile,id)
 local mastery=profile.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
 local discount=1-Effects.Value(profile,"ECONOMY_5","StudyDiscount",0)
 return math.ceil((mastery.Level or 1)*5*discount)
end

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
   local cost=masteryCost(profile,id)
   local locked=profile.FlowerCollection.LockedFlowers[id]==true
   local favorite=profile.FlowerCollection.FavoriteFlowers[id]==true
   table.insert(flowers,{
    Id=id,
    DisplayName=data.DisplayName,
    Rarity=data.Rarity,
    Count=count,
    Planted=planted,
    Free=free,
    Mastery={Level=mastery.Level or 1,XP=mastery.XP or 0,NextXP=(mastery.Level or 1)*Bloom.MasteryXP,Cost=cost},
    Favorite=favorite,
    Protected=locked,
    CanDissolve=free>0 and count>1 and not locked and not favorite,
    CanUpgrade=(mastery.Level or 1)<Bloom.MasteryCap and profile.Currencies.PetalDust>=cost,
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
   local free=math.max(0,count-equipped)
   table.insert(bees,{
    Id=id,
    DisplayName=bee.DisplayName,
    Rarity=bee.Rarity,
    Count=count,
    Equipped=equipped,
    Free=free,
    CanDissolve=free>0 and count>1,
    DissolveValue=Bloom.BeeDustPerCopy,
    Traits=bee.Traits,
    Ability=bee.Ability and bee.Ability.Name or "",
    Mastery=mastery,
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
 local canRespec=false
 for id,node in pairs(Workshop.Nodes) do
  local reason=workshopReason(profile,node)
  local owned=id=="CORE" or profile.WorkshopV5.Nodes[id]==true
  local parentOwned=node.Parent=="CORE" or (node.Parent and profile.WorkshopV5.Nodes[node.Parent]==true) or node.Parent==nil
  local revealed=owned or id=="CORE" or parentOwned
  if id~="CORE" and profile.WorkshopV5.Nodes[id] and not node.Permanent then canRespec=true end
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
 return {Points=profile.WorkshopV5.Points,Nodes=nodes,CanRespec=canRespec}
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
 local current=self.X.MapService:Sector(player)
 local list={}
 for id,cfg in pairs(Trials) do
  local unlocked=profile.World.UnlockedSectors[cfg.Sector]==true
  local location=Locations.Sectors[cfg.Sector]
  local startPos=location and self.X.Origin+location.Center+Vector3.new(0,2,30) or nil
  local nearShrine=startPos~=nil and self.X.U.Near(player,startPos,14)
  local reason=nil
  if self.X.BuildTrialService.Active[player] then reason="TRIAL_RUNNING"
  elseif not profile.Tutorial.FeatureUnlocks.Trials then reason="TRIAL_LOCKED"
  elseif cfg.Advanced and not Effects.Feature(profile,"LEGACY_4","AdvancedTrials") then reason="ADVANCED_TRIAL_LOCKED"
  elseif not unlocked then reason="SECTOR_LOCKED"
  elseif current~=cfg.Sector then reason="WRONG_SECTOR"
  elseif not nearShrine then reason="TOO_FAR"
  end
  local startHint
  if reason=="TRIAL_RUNNING" then startHint="Finish the active trial first"
  elseif reason=="TRIAL_LOCKED" then startHint="Unlock Build Trials through progression"
  elseif reason=="ADVANCED_TRIAL_LOCKED" then startHint="Unlock Advanced Trials in the Workshop"
  elseif reason=="SECTOR_LOCKED" then startHint="Unlock "..(location and location.Name or cfg.Sector).." at its world gate first"
  elseif reason=="WRONG_SECTOR" then startHint="Travel to "..(location and location.Name or cfg.Sector).." and find its Garden Trials shrine"
  elseif reason=="TOO_FAR" then startHint="Go to the Garden Trials shrine in "..(location and location.Name or cfg.Sector)
  else startHint="At shrine — ready to start" end
  table.insert(list,{
   Id=id,
   Name=cfg.Name,
   Sector=cfg.Sector,
   Advanced=cfg.Advanced==true,
   Completed=profile.Quests.Trials[id]==true,
   CanStart=reason==nil,
   NearShrine=nearShrine,
   Reason=reason,
   ReasonText=reason and self:ReasonText(reason) or nil,
   StartHint=startHint,
   Target=cfg.Target,
   Event=cfg.Event,
   Seconds=cfg.Seconds,
  })
 end
 table.sort(list,function(a,b)
  if a.Sector==b.Sector then return a.Name<b.Name end
  return a.Sector<b.Sector
 end)

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

function S:Settings(profile)
 return {
  AutoDissolveUnlocked=profile.WorkshopV5.Nodes.ECONOMY_1==true,
  DissolveFiltersUnlocked=profile.WorkshopV5.Nodes.ECONOMY_2==true,
 }
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
 }
end

return S

