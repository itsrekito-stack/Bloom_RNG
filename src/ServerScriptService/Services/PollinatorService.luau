local RS=game:GetService("ReplicatedStorage")

local C=require(RS.Config.BloomConfig)
local B=require(RS.Config.BeesConfig)
local R=require(RS.Config.RarityConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={States={}}
local rng=Random.new()

local function flowerSlots(profile)
 local out={}
 for i,slot in ipairs(profile.Garden.Slots) do
  if slot.SpeciesId then table.insert(out,i) end
 end
 return out
end

local function offsetSlot(slots,current,offset)
 if #slots==0 then return nil end
 local index=table.find(slots,current) or 1
 return slots[((index-1+(offset or 0))%#slots)+1]
end

local function tempRewardBonus(temp)
 local now=os.clock()
 return ((temp.TemporaryMutationUntil or 0)>now and 1.1 or 1)
  *((temp.NeighbourUntil or 0)>now and 1.15 or 1)
  *((temp.BlessingUntil or 0)>now and 1.05 or 1)
end

function S:Init(x)
 self.X=x
end

function S:AddMastery(player,id,baseAmount,abilityMultiplier)
 local p=self.X:Profile(player)
 local bee=type(id)=="string" and B.Get(id) or nil
 if not p or not bee then return false end
 local amount=tonumber(baseAmount) or 0
 if amount<=0 then return false end

 local before=B.GetMasteryState(p.Pollinators.BeeMastery[id])
 if before.IsMax then
  p.Pollinators.BeeMastery[id]=before.MaxXP
  return false
 end

 local stats=self.X.StatsService:Get(p)
 local gain=amount
  *E.Value(p,"BEES_3","BeeXP",1)
  *(stats.BeeMasteryXP or 1)
  *(tonumber(abilityMultiplier) or 1)
 if gain<=0 then return false end

 local total=math.min(before.MaxXP,before.TotalXP+gain)
 p.Pollinators.BeeMastery[id]=total
 local after=B.GetMasteryState(total)
 if after.Level>before.Level then
  self.X:Send(player,"Message",bee.DisplayName.." Mastery Lv. "..after.Level.." • "..after.LevelRewardText)
 end
 return true
end

function S:AwardEconomy(player,profile,stats,mastery,deliveryUnits,tempBonus,rewardMultiplier,hiveMultiplier,criticalChanceBonus)
 local units=math.max(0,tonumber(deliveryUnits) or 0)
 if units<=0 then return end

 local critChance=math.clamp((stats.CriticalChance or 0)+(tonumber(criticalChanceBonus) or 0),0,1)
 local critical=critChance>0 and rng:NextNumber()<critChance and (stats.CriticalMultiplier or 1) or 1
 local reward=(stats.Yield or 1)
  *(mastery.YieldMultiplier or 1)
  *(tempBonus or 1)
  *(rewardMultiplier or 1)
  *critical

 local honey=C.HoneyPerDelivery*units*reward*(stats.HiveHoney or 1)*(hiveMultiplier or 1)
 local coins=C.CoinsPerDelivery*units*reward*(stats.Coin or 1)*E.Value(profile,"ECONOMY_6","CoinYield",1)
 profile.Hive.Honey+=honey
 profile.Hive.TotalHoney+=honey
 profile.Currencies.Coins+=coins
end

function S:ApplySpecialWork(player,profile,stats,mastery,slots,current,targetCount,workSeconds,rewardMultiplier,hiveMultiplier)
 local units=math.max(0,tonumber(workSeconds) or 0)/math.max(.01,C.DeliverySeconds)
 if units<=0 or #slots==0 then return end
 local count=math.min(#slots,math.max(1,math.floor(tonumber(targetCount) or 1)))
 local workUnits=units*(stats.Power or 1)*(stats.FlowerGrowth or 1)
 local bonus=tempRewardBonus(self.X.Temp[player])

 for offset=0,count-1 do
  local target=offsetSlot(slots,current,offset)
  if target then
   self.X.GardenPlotService:AddFlowerXP(player,target,workUnits)
   self:AwardEconomy(player,profile,stats,mastery,units,bonus,rewardMultiplier,hiveMultiplier,0)
  end
 end
end

function S:ApplySecondaryWork(player,slots,current,workAmount,stats,ability,active)
 if #slots<2 or workAmount<=0 then return end

 if (stats.SplashChance or 0)>0 and rng:NextNumber()<stats.SplashChance then
  local target=offsetSlot(slots,current,1)
  if target and target~=current then
   self.X.GardenPlotService:AddFlowerXP(player,target,workAmount*(stats.SplashPercent or 0))
  end
 end

 if (stats.DualPollinationChance or 0)>0 and rng:NextNumber()<stats.DualPollinationChance then
  local target=offsetSlot(slots,current,#slots>2 and 2 or 1)
  if target and target~=current then
   self.X.GardenPlotService:AddFlowerXP(player,target,workAmount*(stats.DualPollinationPercent or 0))
  end
 end

 if active and (tonumber(ability.ExtraTargetCount) or 0)>0 then
  local count=math.min(#slots-1,math.max(0,math.floor(tonumber(ability.ExtraTargetCount) or 0)))
  local percent=math.max(0,tonumber(ability.ExtraTargetPercent) or 0)*(stats.ClonePower or 1)
  for offset=1,count do
   local target=offsetSlot(slots,current,offset)
   if target and target~=current then
    self.X.GardenPlotService:AddFlowerXP(player,target,workAmount*percent)
   end
  end
 end
end

function S:ActivateAbility(player,profile,state,bee,mastery,stats,slots)
 local ability=bee.Ability
 local now=os.clock()
 local cooldown=(tonumber(ability.Cooldown) or 0)
  *(stats.AbilityCooldown or 1)
  *mastery.AbilityCooldownMultiplier
  *E.Value(profile,"BEES_4","TraitCooldown",1)
 state.AbilityAt=now+math.max(.1,cooldown)
 state.ActiveUntil=now+math.max(0,tonumber(ability.Duration) or 0)*(stats.AbilityDuration or 1)

 local tickCount=math.max(0,math.floor(tonumber(ability.TickCount) or 0))
 if tickCount>0 then
  state.AbilityTicksRemaining=tickCount
  state.AbilityTickInterval=math.max(.1,tonumber(ability.TickInterval) or 1)
  state.NextAbilityTick=now+state.AbilityTickInterval
  state.AbilityTickSlot=state.Slot
 else
  state.AbilityTicksRemaining=nil
  state.NextAbilityTick=nil
  state.AbilityTickSlot=nil
 end

 if (tonumber(ability.BurstTargets) or 0)>0 and (tonumber(ability.BurstWorkSeconds) or 0)>0 then
  self:ApplySpecialWork(
   player,profile,stats,mastery,slots,state.Slot,
   ability.BurstTargets,ability.BurstWorkSeconds,
   ability.BurstRewardMultiplier or 1,ability.BurstHiveMultiplier or 1
  )
 end

 self.X:Emit(player,"Ability",1)
 if (R.Rank[bee.Rarity] or 0)>=3
  and (E.Feature(profile,"BEES_2","GuaranteedAbilityToken")
   or profile.Season.ActiveCard=="SummerSwarm"
   or rng:NextNumber()<C.AbilityTokenChance)
 then
  self.X.GardenActivityService:Offer(player,"Overcharge",self.X.GardenPlotService:Position(player,state.Slot),nil,bee.Id)
 end
end

function S:ProcessAbilityTicks(player,profile,state,bee,mastery,stats,slots)
 local remaining=tonumber(state.AbilityTicksRemaining) or 0
 local nextTick=tonumber(state.NextAbilityTick)
 if remaining<=0 or not nextTick then return end

 local now=os.clock()
 local ability=bee.Ability
 local guard=0
 while remaining>0 and now>=nextTick and guard<20 do
  guard+=1
  local target=state.AbilityTickSlot
  if not target or not profile.Garden.Slots[target] or not profile.Garden.Slots[target].SpeciesId then
   target=state.Slot
  end
  self:ApplySpecialWork(
   player,profile,stats,mastery,slots,target,1,
   ability.TickWorkSeconds or 0,
   ability.TickRewardMultiplier or 1,
   ability.TickHiveMultiplier or 1
  )
  remaining-=1
  nextTick+=math.max(.1,tonumber(state.AbilityTickInterval) or 1)
 end

 state.AbilityTicksRemaining=remaining>0 and remaining or nil
 state.NextAbilityTick=remaining>0 and nextTick or nil
 if remaining<=0 then state.AbilityTickSlot=nil end
end

function S:Deliver(player,profile,temp,state,bee,mastery,stats,slots)
 local ability=bee.Ability
 local now=os.clock()
 local active=(state.ActiveUntil or 0)>now
 local workAmount=(stats.Power or 1)*(stats.FlowerGrowth or 1)

 if active then
  local abilityWork=tonumber(ability.WorkMultiplier) or 1
  if ability.Visual=="Clone" then
   abilityWork=1+(abilityWork-1)*(stats.ClonePower or 1)
  end
  workAmount*=math.max(0,abilityWork)
 end

 self.X.GardenPlotService:AddFlowerXP(player,state.Slot,workAmount)
 self:ApplySecondaryWork(player,slots,state.Slot,workAmount,stats,ability,active)

 local rewardMultiplier=1
 local hiveMultiplier=1
 local criticalChanceBonus=0
 if active then
  rewardMultiplier=(tonumber(ability.RewardMultiplier) or 1)
   *E.Value(profile,"BEES_6","AbilityYield",1)
   *(profile.Season.ActiveCard=="TwilightSeason" and 1.15 or 1)
  hiveMultiplier=tonumber(ability.HiveHoneyMultiplier) or 1
  criticalChanceBonus=tonumber(ability.CriticalChanceBonus) or 0
 end

 self:AwardEconomy(
  player,profile,stats,mastery,1,tempRewardBonus(temp),
  rewardMultiplier,hiveMultiplier,criticalChanceBonus
 )
 self:AddMastery(player,bee.Id,1,active and (ability.BeeMasteryXPMultiplier or 1) or 1)
 self.X.RollService:Charge(player,C.Charge.Delivery*(profile.Season.ActiveCard=="SummerSwarm" and .75 or 1))
 self.X:Emit(player,"Delivery",1)
 self.X.SocialService:Contribute(player,1)

 for synergy in pairs(self.X.GardenSynergyService.Active[player] or {}) do
  profile.GardenSynergies.Mastery[synergy]=(profile.GardenSynergies.Mastery[synergy] or 0)+E.Value(profile,"GARDEN_6","SynergyXP",1)
 end

 state.Slot=offsetSlot(slots,state.Slot,1) or state.Slot
 if not profile.Tutorial.Events.PollenSpark then
  self.X.GardenActivityService:Offer(player,"PollenSpark",self.X.GardenPlotService:Position(player,state.Slot))
 end
end

function S:Tick(player,dt)
 local profile=self.X:Profile(player)
 local temp=self.X.Temp[player]
 if not profile or not profile.StarterBeeGranted or not temp then return end

 local slots=flowerSlots(profile)
 if #slots==0 then return end

 local states=self.States[player] or {}
 self.States[player]=states
 local capacity=self.X.StatsService:BeeCapacity(profile)
 for index,state in pairs(states) do
  local equipped=profile.Pollinators.EquippedBeeSlots[index]
  if type(index)~="number" or index>capacity or equipped~=state.Id then states[index]=nil end
 end
 local stats=self.X.StatsService:Get(profile)

 for index,id in pairs(profile.Pollinators.EquippedBeeSlots) do
  if type(index)=="number" and index<=capacity then
   local bee=B.Get(id)
   if bee then
    local mastery=B.GetMasteryState(profile.Pollinators.BeeMastery[id])
    local state=states[index]
    if not state or state.Id~=id then
     local initialCooldown=(tonumber(bee.Ability.Cooldown) or 0)
      *(stats.AbilityCooldown or 1)
      *mastery.AbilityCooldownMultiplier
      *E.Value(profile,"BEES_4","TraitCooldown",1)
     state={Id=id,Elapsed=0,AbilityAt=os.clock()+math.max(.1,initialCooldown),Slot=slots[(index-1)%#slots+1]}
     states[index]=state
    end

    if not profile.Garden.Slots[state.Slot] or not profile.Garden.Slots[state.Slot].SpeciesId then
     state.Slot=slots[1]
    end

    if temp.Hotspot and (temp.HotspotUntil or 0)>os.clock() then
     local best=math.huge
     for _,slotIndex in ipairs(slots) do
      local d=(self.X.GardenPlotService:Position(player,slotIndex)-temp.Hotspot).Magnitude
      if d<best then best=d state.Slot=slotIndex end
     end
    end

    local now=os.clock()
    if temp.OverchargeBee==id then
     state.AbilityAt=math.min(state.AbilityAt,now+1)
     temp.OverchargeBee=nil
    end

    if now>=state.AbilityAt then
     self:ActivateAbility(player,profile,state,bee,mastery,stats,slots)
    end

    self:ProcessAbilityTicks(player,profile,state,bee,mastery,stats,slots)

    local speed=(stats.Speed or 1)
     *mastery.WorkSpeedMultiplier
     *((temp.SwiftUntil or 0)>now and 1.2 or 1)
     *(profile.Season.ActiveCard=="TwilightSeason" and .9 or 1)
    state.Elapsed+=dt*speed
    self.X:EmitOnce(player,"Work")

    local deliveryGuard=0
    while state.Elapsed>=C.DeliverySeconds and deliveryGuard<8 do
     deliveryGuard+=1
     state.Elapsed-=C.DeliverySeconds
     self:Deliver(player,profile,temp,state,bee,mastery,stats,slots)
    end
   end
  end
 end

 if os.clock()>=(temp.NextActivity or 0) then
  temp.NextActivity=os.clock()
   +C.ActivityInterval
   *E.Value(profile,"EXPLORATION_4","WildInterval",1)
   *(profile.Season.ActiveCard=="SpringResonance" and .8 or 1)
  local kinds={"PollenSpark","NectarBud","DewDrop","PollenTrail","CrossPollination","BloomSurge","PollenWind"}
  temp.ActivityIndex=(temp.ActivityIndex or 0)%#kinds+1
  self.X.GardenActivityService:Offer(player,kinds[temp.ActivityIndex],self.X.GardenPlotService:Position(player,slots[1]))
 end
end

function S:Remove(player)
 self.States[player]=nil
end

return S
