local RS=game:GetService("ReplicatedStorage")

local Bees=require(RS.Config.BeesConfig)
local Flowers=require(RS.Config.FlowersConfig)
local C=require(RS.Config.BloomConfig)
local Activities=require(RS.Config.ActivityConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={AbilitySignatures={}}

local META={
 Luck={Label="Luck",Order=1,IconGroup="WorkshopHex",IconId="Luck"},
 Yield={Label="Pollination Yield",Order=2,IconGroup="System",IconId="Flower"},
 Speed={Label="Bee Speed",Order=3,IconGroup="System",IconId="ArrowRight"},
 Power={Label="Bee Power",Order=4,IconGroup="System",IconId="Upgrade"},
 FlowerGrowth={Label="Flower Growth",Order=5,IconGroup="System",IconId="Garden"},
 Coin={Label="Coins",Order=6,IconGroup="Currencies",IconId="Coins"},
 HiveHoney={Label="Hive Honey",Order=7,IconGroup="System",IconId="Hive"},
 AbilityCooldown={Label="Ability Cooldown",Order=8,IconGroup="WorkshopHex",IconId="AutoRoll",Inverse=true},
 BeeMasteryXP={Label="Bee Mastery XP",Order=9,IconGroup="System",IconId="Bee"},
 Reward={Label="Temporary Rewards",Order=10,IconGroup="System",IconId="Plus"},
 CriticalChance={Label="Critical Chance",Order=11,IconGroup="WorkshopHex",IconId="Luck",Additive=true},
 MutationChance={Label="Mutation Chance",Order=12,IconGroup="WorkshopHex",IconId="Mastery",Additive=true},
 RareWeight={Label="Rare Special-Roll Weight",Order=13,IconGroup="WorkshopHex",IconId="Luck"},
 AbilityReward={Label="Bee Ability Rewards",Order=14,IconGroup="System",IconId="Bee"},
}

local BEE_STAT_MAP={
 LuckMultiplier="Luck",
 PollinatorYieldMultiplier="Yield",
 PollinatorTravelSpeedMultiplier="Speed",
 PollinatorPowerMultiplier="Power",
 FlowerGrowthMultiplier="FlowerGrowth",
 CoinMultiplier="Coin",
 HiveHoneyMultiplier="HiveHoney",
 AbilityCooldownMultiplier="AbilityCooldown",
 BeeMasteryXPMultiplier="BeeMasteryXP",
 CriticalChance="CriticalChance",
}

local function roundPercent(value)
 return math.floor(value*100+.5)
end

local function multiplierText(multiplier,inverse)
 local m=tonumber(multiplier) or 1
 if inverse then
  local reduction=math.max(0,1-m)
  return "-"..tostring(roundPercent(reduction)).."%"
 end
 local delta=m-1
 return (delta>=0 and "+" or "")..tostring(roundPercent(delta)).."%"
end

local function additiveText(value)
 local n=tonumber(value) or 0
 return (n>=0 and "+" or "")..tostring(roundPercent(n)).."%"
end

local function remaining(untilAt,now)
 local value=(tonumber(untilAt) or 0)-now
 return value>0 and value or nil
end

local function source(buckets,stat,group,name,valueText,description,timeLeft)
 if not META[stat] then return end
 local bucket=buckets[stat]
 if not bucket then bucket={} buckets[stat]=bucket end
 table.insert(bucket,{
  Group=group,
  Name=name,
  ValueText=valueText,
  Description=description,
  Remaining=timeLeft,
 })
end

local function abilityDescription(bee)
 local ability=bee and bee.Ability
 if not ability then return "Active bee ability" end
 local parts={}
 local work=tonumber(ability.WorkMultiplier) or 1
 local rewards=tonumber(ability.RewardMultiplier) or 1
 local honey=tonumber(ability.HiveHoneyMultiplier) or 1
 local mastery=tonumber(ability.BeeMasteryXPMultiplier) or 1
 local crit=tonumber(ability.CriticalChanceBonus) or 0
 if work~=1 then table.insert(parts,multiplierText(work,false).." work") end
 if rewards~=1 then table.insert(parts,multiplierText(rewards,false).." rewards") end
 if honey~=1 then table.insert(parts,multiplierText(honey,false).." Hive Honey") end
 if mastery~=1 then table.insert(parts,multiplierText(mastery,false).." Bee Mastery XP") end
 if crit>0 then table.insert(parts,additiveText(crit).." crit chance") end
 if #parts==0 then return tostring(ability.Description or ability.Name or "Active bee ability") end
 return table.concat(parts," • ")
end

function S:Init(x)
 self.X=x
end

function S:ActivityBoostMultiplier(player,kind,key)
 local cfg=Activities.Types[kind]
 local boost=cfg and cfg.Boost
 local temp=self.X.Temp[player]
 local active=temp and temp.ActivityBoosts and (temp.ActivityBoosts[kind] or 0)>os.clock()
 if not active or not boost then return 1 end
 return tonumber(boost[key]) or 1
end

function S:RollLuck(player,profile)
 local p=profile or self.X:Profile(player)
 if not p then return 1 end
 local temp=self.X.Temp[player] or {}
 local base=self.X.StatsService:Get(p).Luck or 1
 local solar=self:ActivityBoostMultiplier(player,"SolarBloom","LuckMultiplier")
 local earned=base*solar+(tonumber(temp.Dew) or 0)*.1
 local requested=tonumber(p.Settings and p.Settings.EffectiveLuck) or 0
 local effective=requested>0 and math.min(earned,math.max(1,requested)) or earned
 if (tonumber(temp.ServerBloomLuckRolls) or 0)>0 then effective*=100 end
 return effective
end

function S:ConsumeServerBloomRoll(player)
 local temp=self.X.Temp[player]
 local rolls=temp and math.max(0,math.floor(tonumber(temp.ServerBloomLuckRolls) or 0)) or 0
 if rolls<=0 then return false end
 temp.ServerBloomLuckRolls=math.max(0,rolls-1)
 return true
end

function S:ApplyActivity(player,kind)
 local cfg=Activities.Types[kind]
 local boost=cfg and cfg.Boost
 if not boost then return false end
 local temp=self.X.Temp[player]
 if not temp then return false end
 temp.ActivityBoosts=temp.ActivityBoosts or {}
 local duration=math.max(0,tonumber(boost.Duration) or 0)
 if duration<=0 then return false end
 temp.ActivityBoosts[kind]=os.clock()+duration
 self.X:MarkStateDirty(player)
 local label=tostring(boost.Label or kind)
 local description=tostring(boost.Description or "Temporary activity boost")
 self.X:Send(player,"Message",label.." • "..description.." • +"..tostring(cfg.Charge or 0).." Bloom Charge")
 return true
end

function S:Tick(player)
 local temp=self.X.Temp[player]
 if not temp then return false end
 local now=os.clock()
 local changed=false

 if temp.ActivityBoosts then
  for kind,untilAt in pairs(temp.ActivityBoosts) do
   if (tonumber(untilAt) or 0)<=now then
    temp.ActivityBoosts[kind]=nil
    changed=true
   end
  end
 end

 for _,key in ipairs({"NeighbourUntil","BlessingUntil","TemporaryMutationUntil","SwiftUntil"}) do
  local untilAt=tonumber(temp[key]) or 0
  if untilAt>0 and untilAt<=now then
   temp[key]=nil
   changed=true
  end
 end

 local active={}
 local states=self.X.PollinatorService and self.X.PollinatorService.States[player] or {}
 for slot,state in pairs(states or {}) do
  if (tonumber(state.ActiveUntil) or 0)>now then
   table.insert(active,tostring(slot)..":"..tostring(state.Id)..":"..tostring(math.floor((state.ActiveUntil or 0)*10)))
  end
 end
 table.sort(active)
 local signature=table.concat(active,"|")
 if self.AbilitySignatures[player]~=signature then
  self.AbilitySignatures[player]=signature
  changed=true
 end

 return changed
end

function S:Snapshot(player,profile)
 local p=profile or self.X:Profile(player)
 local temp=self.X.Temp[player]
 if not p or not temp then return {Items={}} end
 local now=os.clock()
 local stats=self.X.StatsService:Get(p)
 local buckets={}

 local equippedCounts={}
 for _,beeId in pairs(p.Pollinators.EquippedBeeSlots or {}) do
  if type(beeId)=="string" then equippedCounts[beeId]=(equippedCounts[beeId] or 0)+1 end
 end

 for beeId,count in pairs(equippedCounts) do
  local bee=Bees.Get(beeId)
  if bee and type(bee.Passive)=="table" then
   for key,value in pairs(bee.Passive) do
    local stat=BEE_STAT_MAP[key]
    local meta=stat and META[stat]
    local numeric=tonumber(value)
    if stat and numeric then
     if meta.Additive then
      source(buckets,stat,"Bees",bee.DisplayName.." ×"..count,additiveText(numeric*count),nil,nil)
     else
      local combined=numeric^count
      if math.abs(combined-1)>.0001 then
       source(buckets,stat,"Bees",bee.DisplayName.." ×"..count,multiplierText(combined,meta.Inverse),nil,nil)
      end
     end
    end
   end
   local mastery=Bees.GetMasteryState(p.Pollinators.BeeMastery[beeId])
   local masteryLuck=tonumber(mastery.LuckMultiplier) or 1
   if masteryLuck>1.0001 then
    source(buckets,"Luck","Bee Mastery",bee.DisplayName.." • Lv."..tostring(mastery.Level),multiplierText(masteryLuck,false),"Bee Mastery permanently improves this equipped Bee's roll luck.",nil)
   end
  end
 end

 for _,slot in ipairs(p.Garden.Slots or {}) do
  local id=slot.SpeciesId
  local flower=type(id)=="string" and Flowers.GetSpecies(id) or nil
  if flower then
   local mastery=p.FlowerCollection.FlowerMastery[id]
   local level=math.max(1,math.floor(tonumber(mastery and mastery.Level) or 1))
   local buff=Flowers.GetLevelBuff(id,level)
   local stat=buff and BEE_STAT_MAP[buff.Stat]
   local meta=stat and META[stat]
   if buff and stat and meta then
    source(buckets,stat,"Flowers",flower.DisplayName.." • Lv."..tostring(level),multiplierText(buff.Multiplier,meta.Inverse),"Planted Flower passive. Raise its Flower Level to strengthen this bonus.",nil)
   end
  end
 end

 local _,activeTraits=Bees.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)
 for _,trait in ipairs(activeTraits) do
  for key,value in pairs(trait.Bonus or {}) do
   local stat=BEE_STAT_MAP[key]
   local meta=stat and META[stat]
   local numeric=tonumber(value)
   if stat and numeric then
    local valueText=meta.Additive and additiveText(numeric) or multiplierText(numeric,meta.Inverse)
    source(buckets,stat,"Bee Trait",trait.Name.." • "..tostring(trait.Count).." bees",valueText,trait.Description,nil)
   end
  end
 end

 local solarCfg=Activities.Types.SolarBloom and Activities.Types.SolarBloom.Boost
 local solarUntil=temp.ActivityBoosts and temp.ActivityBoosts.SolarBloom
 local solarRemaining=remaining(solarUntil,now)
 local solarMultiplier=1
 if solarRemaining and solarCfg then
  solarMultiplier=tonumber(solarCfg.LuckMultiplier) or 1
  source(buckets,"Luck","Activity",tostring(solarCfg.Label or "Solar Bloom"),multiplierText(solarMultiplier,false),tostring(solarCfg.Description or ""),solarRemaining)
 end

 local dew=math.max(0,tonumber(temp.Dew) or 0)
 if dew>0 then
  source(buckets,"Luck","Activity","Dew Luck ×"..tostring(dew),additiveText(dew*.1),"Consumed by your next roll.",nil)
 end

 if (tonumber(temp.ServerBloomLuckRolls) or 0)>0 then
  source(buckets,"Luck","Server","Server Bloom","×100","Applies to your next Roll, then expires.",nil)
 end

 local swiftRemaining=remaining(temp.SwiftUntil,now)
 if swiftRemaining then
  source(buckets,"Speed","Flower Effect","Swift Window",multiplierText(1.2,false),"Sunflower pollination speed window.",swiftRemaining)
 end

 local rewardMultiplier=1
 local neighbourRemaining=remaining(temp.NeighbourUntil,now)
 if neighbourRemaining then
  rewardMultiplier*=1.15
  source(buckets,"Reward","Activity","Neighbour Boost",multiplierText(1.15,false),"Temporary reward multiplier.",neighbourRemaining)
 end
 local blessingRemaining=remaining(temp.BlessingUntil,now)
 if blessingRemaining then
  rewardMultiplier*=1.05
  source(buckets,"Reward","Social","Hive Blessing",multiplierText(1.05,false),"Temporary reward multiplier from another player.",blessingRemaining)
 end
 local mutationRemaining=remaining(temp.TemporaryMutationUntil,now)
 if mutationRemaining then
  rewardMultiplier*=1.10
  source(buckets,"Reward","Season","Crystal Mutation",multiplierText(1.10,false),"Temporary delivery reward multiplier.",mutationRemaining)
 end

 local coinWorkshop=E.Value(p,"ECONOMY_6","CoinYield",1)
 if coinWorkshop~=1 then
  source(buckets,"Coin","Workshop","ECONOMY_6",multiplierText(coinWorkshop,false),"Permanent Workshop coin yield.",nil)
 end
 local masteryWorkshop=E.Value(p,"BEES_3","BeeXP",1)
 if masteryWorkshop~=1 then
  source(buckets,"BeeMasteryXP","Workshop","BEES_3",multiplierText(masteryWorkshop,false),"Permanent Workshop Bee Mastery XP.",nil)
 end
 local cooldownWorkshop=E.Value(p,"BEES_4","TraitCooldown",1)
 if cooldownWorkshop~=1 then
  source(buckets,"AbilityCooldown","Workshop","BEES_4",multiplierText(cooldownWorkshop,true),"Permanent Workshop ability cooldown reduction.",nil)
 end
 local abilityRewardWorkshop=E.Value(p,"BEES_6","AbilityYield",1)
 if abilityRewardWorkshop~=1 then
  source(buckets,"AbilityReward","Workshop","BEES_6",multiplierText(abilityRewardWorkshop,false),"Rewards produced while a bee ability is active.",nil)
 end

 if temp.Crystal and p.WorkshopV5.Nodes.BLOOM_1 then
  source(buckets,"MutationChance","Activity","Crystal Resonance",additiveText(.15),"Applies to your next Bloom Roll.",nil)
 end

 local rareWeight=1
 if p.RollState.SpecialRollReady then
  rareWeight*=C.SpecialRareMultiplier
  source(buckets,"RareWeight","Bloom","Bloom Ready",multiplierText(C.SpecialRareMultiplier,false),"Your next Bloom Roll boosts Rare+ weight and undiscovered rewards.",nil)
 end
 if temp.Eclipse then
  local eclipse=1.5*E.Value(p,"EXPLORATION_5","EclipseWeight",1)
  rareWeight*=eclipse
  source(buckets,"RareWeight","Activity","Eclipse",multiplierText(eclipse,false),"Mythic+ weight on the next special roll.",nil)
 end
 if temp.Signature and p.WorkshopV5.Nodes.BLOOM_6 then
  local signature=E.Value(p,"BLOOM_6","SignatureWeight",1)
  rareWeight*=signature
  source(buckets,"RareWeight","Garden","Signature Garden",multiplierText(signature,false),"Mythic+ weight on the next special roll.",nil)
 end

 local totals={
  Luck=self:RollLuck(player,p),
  Yield=stats.Yield or 1,
  Speed=(stats.Speed or 1)*(swiftRemaining and 1.2 or 1),
  Power=stats.Power or 1,
  FlowerGrowth=stats.FlowerGrowth or 1,
  Coin=(stats.Coin or 1)*coinWorkshop,
  HiveHoney=stats.HiveHoney or 1,
  AbilityCooldown=(stats.AbilityCooldown or 1)*cooldownWorkshop,
  BeeMasteryXP=(stats.BeeMasteryXP or 1)*masteryWorkshop,
  Reward=rewardMultiplier,
  CriticalChance=stats.CriticalChance or 0,
  MutationChance=(temp.Crystal and p.WorkshopV5.Nodes.BLOOM_1) and .15 or 0,
  RareWeight=rareWeight,
  AbilityReward=abilityRewardWorkshop,
 }

 local items={}
 local luckSummary=nil
 for id,meta in pairs(META) do
  local total=totals[id]
  local src=buckets[id] or {}
  local active=false
  local valueText=""
  if meta.Additive then
   active=(tonumber(total) or 0)>.0001
   valueText=additiveText(total or 0)
  else
   active=math.abs((tonumber(total) or 1)-1)>.0001
   valueText=multiplierText(total or 1,meta.Inverse)
  end
  table.sort(src,function(a,b)
   if a.Group==b.Group then return a.Name<b.Name end
   return a.Group<b.Group
  end)
  local item={
   Id=id,
   Label=meta.Label,
   Order=meta.Order,
   IconGroup=meta.IconGroup,
   IconId=meta.IconId,
   ValueText=valueText,
   Total=total,
   Sources=src,
  }
  if id=="Luck" then
   local bonus=math.max(0,math.floor(((tonumber(total) or 1)-1)*100+.5))
   item.ValueText=bonus==0 and "0%" or ("+"..tostring(bonus).."%")
   item.LuckBonusPercent=bonus
   luckSummary=item
  elseif active or #src>0 then
   table.insert(items,item)
  end
 end

 if solarRemaining and solarCfg then
  table.insert(items,{
   Id="SolarBloom",
   Label="Solar Bloom",
   Order=90,
   IconGroup="System",
   IconId="Flower",
   ValueText=tostring(math.max(1,math.ceil(solarRemaining))).."s",
   Remaining=solarRemaining,
   Description=tostring(solarCfg.Description or "").." • +"..tostring(Activities.Types.SolarBloom.Charge or 0).." Bloom Charge on completion",
   Sources={{
    Group="Activity",
    Name="Solar Bloom",
    ValueText=multiplierText(solarMultiplier,false).." Luck",
    Description="Complete all Solar Bloom checkpoints to refresh this boost.",
    Remaining=solarRemaining,
   }},
  })
 end

 local abilitySources={}
 for slot,state in pairs(self.X.PollinatorService.States[player] or {}) do
  local timeLeft=remaining(state.ActiveUntil,now)
  if timeLeft then
   local bee=Bees.Get(state.Id)
   if bee then
    table.insert(abilitySources,{
     Group="Bee Ability",
     Name=bee.DisplayName.." • "..tostring(bee.Ability and bee.Ability.Name or "Ability"),
     ValueText=tostring(math.max(1,math.ceil(timeLeft))).."s",
     Description=abilityDescription(bee),
     Remaining=timeLeft,
     Slot=slot,
    })
   end
  end
 end
 if #abilitySources>0 then
  table.sort(abilitySources,function(a,b) return tostring(a.Name)<tostring(b.Name) end)
  table.insert(items,{
   Id="BeeAbilities",
   Label="Active Bee Abilities",
   Order=91,
   IconGroup="System",
   IconId="Bee",
   ValueText=tostring(#abilitySources),
   Total=#abilitySources,
   Sources=abilitySources,
  })
 end

 table.sort(items,function(a,b)
  if a.Order==b.Order then return a.Label<b.Label end
  return a.Order<b.Order
 end)
 return {Items=items,Luck=luckSummary or {Id="Luck",Label="Luck",Order=0,IconGroup="WorkshopHex",IconId="Luck",ValueText="0%",Total=1,LuckBonusPercent=0,Sources={}}}
end

function S:Remove(player)
 self.AbilitySignatures[player]=nil
end

return S
