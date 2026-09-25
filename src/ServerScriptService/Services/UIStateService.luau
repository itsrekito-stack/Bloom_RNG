local RS=game:GetService("ReplicatedStorage")
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Workshop=require(RS.Config.WorkshopConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local Locations=require(RS.Config.LocationsConfig)
local Bloom=require(RS.Config.BloomConfig)
local Rarity=require(RS.Config.RarityConfig)

local S={}

local REASONS={
 PROFILE_LOADING="Профиль ещё загружается",
 SERVER_ERROR="Ошибка сервера",
 RATE_LIMITED="Слишком много запросов, попробуй ещё раз",
 LOCKED="Функция пока закрыта",
 FEATURE_LOCKED="Функция пока закрыта",
 INVALID_ACTION="Неизвестное действие",
 INVALID_ITEM="Предмет не найден",
 INVALID_SLOT="Недоступный слот",
 INVALID_NODE="Узел не найден",
 INVALID_SETTING="Настройка не найдена",
 INVALID_VALUE="Некорректное значение",
 NOT_DISCOVERED="Сначала открой этот предмет",
 NOT_OWNED="Предмет не принадлежит игроку",
 NO_FREE_COPY="Нет свободной копии",
 LAST_COPY="Последнюю копию растворить нельзя",
 PROTECTED="Предмет защищён",
 FAVORITE="Избранный предмет нельзя растворить",
 OWNED="Улучшение уже куплено",
 PARENT_REQUIRED="Сначала купи предыдущий узел",
 HIVE_REQUIRED="Нужен более высокий уровень улья",
 SEASON_REQUIRED="Эта ветка открывается после первого сезона",
 POINTS_REQUIRED="Недостаточно Workshop Points",
 COINS_REQUIRED="Недостаточно Coins",
 DUST_REQUIRED="Недостаточно Petal Dust",
 NECTAR_REQUIRED="Недостаточно Ancient Nectar",
 MASTERY_MAX="Mastery уже максимального уровня",
 TOO_FAR="Подойди ближе к объекту",
 WRONG_SECTOR="Перейди в нужную локацию",
 SECTOR_LOCKED="Сначала открой эту локацию",
 TRIAL_LOCKED="Испытания пока закрыты",
 TRIAL_RUNNING="Испытание уже запущено",
 COOLDOWN="Подожди окончание перезарядки",
 EMPTY_POOL="В рулетке нет доступных наград",
 SEASON_PREVIEW_OPEN="Сначала закончи подтверждение сезона",
 FILTER_LOCKED="Сначала открой фильтры в Workshop",
 AUTO_DISSOLVE_LOCKED="Сначала открой Auto Dissolve в Workshop",
 NO_CHANGES="Нет улучшений для сброса",
}

local function masteryCost(profile,id)
 local mastery=profile.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
 local discount=profile.WorkshopV5.Nodes.ECONOMY_5 and .8 or 1
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
 return REASONS[reason] or tostring(reason or "Действие недоступно")
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
   table.insert(bees,{
    Id=id,
    DisplayName=bee.DisplayName,
    Rarity=bee.Rarity,
    Count=count,
    Equipped=equippedCounts[id] or 0,
    Traits=bee.Traits,
    Ability=bee.Ability and bee.Ability.Name or "",
   })
  end
 end
 table.sort(bees,function(a,b)
  local aa=Bees.Get(a.Id) local bb=Bees.Get(b.Id)
  return (aa and aa.SortOrder or 999)<(bb and bb.SortOrder or 999)
 end)

 return {
  Flowers=flowers,
  Bees=bees,
  FlowerCapacity=self.X.StatsService:FlowerCapacity(profile),
  BeeCapacity=self.X.StatsService:BeeCapacity(profile),
  Traits=Bees.GetTraitState(profile.Pollinators.EquippedBeeSlots),
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
  sectors[id]={
   Id=id,
   Name=cfg.Name,
   Unlocked=profile.World.UnlockedSectors[id]==true,
   HiveRequired=cfg.Hive,
   Current=current==id,
   CanUnlock=profile.World.UnlockedSectors[id]~=true and profile.Hive.Level>=cfg.Hive,
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
  local reason=nil
  if self.X.BuildTrialService.Active[player] then reason="TRIAL_RUNNING"
  elseif not profile.Tutorial.FeatureUnlocks.Trials then reason="TRIAL_LOCKED"
  elseif not unlocked then reason="SECTOR_LOCKED"
  elseif current~=cfg.Sector then reason="WRONG_SECTOR"
  else
   local location=Locations.Sectors[cfg.Sector]
   local startPos=location and self.X.Origin+location.Center+Vector3.new(0,2,30) or nil
   if not startPos or not self.X.U.Near(player,startPos,14) then reason="TOO_FAR" end
  end
  table.insert(list,{
   Id=id,
   Name=cfg.Name,
   Sector=cfg.Sector,
   Completed=profile.Quests.Trials[id]==true,
   CanStart=reason==nil,
   Reason=reason,
   ReasonText=reason and self:ReasonText(reason) or nil,
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
