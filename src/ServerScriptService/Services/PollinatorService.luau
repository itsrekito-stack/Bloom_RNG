local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local B=require(RS.Config.BeesConfig) local R=require(RS.Config.RarityConfig) local E=require(RS.Shared.WorkshopEffects) local S={States={}}
function S:Init(x) self.X=x end
function S:AddMastery(player,id,baseAmount,abilityMultiplier)
 local p=self.X:Profile(player) local bee=type(id)=="string" and B.Get(id) or nil if not p or not bee then return false end
 local amount=tonumber(baseAmount) or 0 if amount<=0 then return false end
 local before=B.GetMasteryState(p.Pollinators.BeeMastery[id]) if before.IsMax then p.Pollinators.BeeMastery[id]=before.MaxXP return false end
 local stats=self.X.StatsService:Get(p) local gain=amount*E.Value(p,"BEES_3","BeeXP",1)*(stats.BeeMasteryXP or 1)*(tonumber(abilityMultiplier) or 1)
 if gain<=0 then return false end
 local total=math.min(before.MaxXP,before.TotalXP+gain) p.Pollinators.BeeMastery[id]=total
 local after=B.GetMasteryState(total) if after.Level>before.Level then self.X:Send(player,"Message",bee.DisplayName.." Mastery Lv. "..after.Level.." • "..after.LevelRewardText) end
 return true
end
function S:Tick(player,dt)
 local p=self.X:Profile(player) local t=self.X.Temp[player] if not p or not p.StarterBeeGranted then return end local states=self.States[player] or {} self.States[player]=states local stats=self.X.StatsService:Get(p)
 local flowerSlots={} for i,s in ipairs(p.Garden.Slots) do if s.SpeciesId then table.insert(flowerSlots,i) end end if #flowerSlots==0 then return end
 for index,id in pairs(p.Pollinators.EquippedBeeSlots) do if type(index)=="number" and index<=self.X.StatsService:BeeCapacity(p) then local bee=B.Get(id) if bee then
  local mastery=B.GetMasteryState(p.Pollinators.BeeMastery[id])
  local state=states[index] if not state or state.Id~=id then state={Id=id,Elapsed=0,AbilityAt=os.clock()+bee.Ability.Cooldown,Slot=flowerSlots[(index-1)%#flowerSlots+1]} states[index]=state end
  if not p.Garden.Slots[state.Slot] or not p.Garden.Slots[state.Slot].SpeciesId then state.Slot=flowerSlots[1] end
  if t.Hotspot and (t.HotspotUntil or 0)>os.clock() then local best=math.huge for _,i in ipairs(flowerSlots) do local d=(self.X.GardenPlotService:Position(player,i)-t.Hotspot).Magnitude if d<best then best=d state.Slot=i end end end
  local slot=p.Garden.Slots[state.Slot] local speed=stats.Speed*mastery.WorkSpeedMultiplier*((t.SwiftUntil or 0)>os.clock() and 1.2 or 1)*(p.Season.ActiveCard=="TwilightSeason" and .9 or 1)
  state.Elapsed=state.Elapsed+dt*speed self.X:EmitOnce(player,"Work")
  if t.OverchargeBee==id then state.AbilityAt=math.min(state.AbilityAt,os.clock()+1) t.OverchargeBee=nil end
  if os.clock()>=state.AbilityAt then state.AbilityAt=os.clock()+bee.Ability.Cooldown*stats.AbilityCooldown*mastery.AbilityCooldownMultiplier*E.Value(p,"BEES_4","TraitCooldown",1) state.ActiveUntil=os.clock()+bee.Ability.Duration self.X:Emit(player,"Ability",1)
   if R.Rank[bee.Rarity]>=3 and (E.Feature(p,"BEES_2","GuaranteedAbilityToken") or p.Season.ActiveCard=="SummerSwarm" or Random.new():NextNumber()<.6) then self.X.GardenActivityService:Offer(player,"Overcharge",self.X.GardenPlotService:Position(player,state.Slot),nil,id) end
  end
  if state.Elapsed>=C.DeliverySeconds then state.Elapsed=state.Elapsed-C.DeliverySeconds
   local bonus=((t.TemporaryMutationUntil or 0)>os.clock() and 1.1 or 1)*((t.NeighbourUntil or 0)>os.clock() and 1.15 or 1)*((t.BlessingUntil or 0)>os.clock() and 1.05 or 1)
   local active=(state.ActiveUntil or 0)>os.clock() local yield=C.HoneyPerDelivery*stats.Yield*mastery.YieldMultiplier*bonus*(active and (bee.Ability.RewardMultiplier or 1)*E.Value(p,"BEES_6","AbilityYield",1)*(p.Season.ActiveCard=="TwilightSeason" and 1.15 or 1) or 1)
   p.Hive.Honey=p.Hive.Honey+yield p.Hive.TotalHoney=p.Hive.TotalHoney+yield p.Currencies.Coins=p.Currencies.Coins+C.CoinsPerDelivery*stats.Yield*mastery.YieldMultiplier*bonus*E.Value(p,"ECONOMY_6","CoinYield",1)
   self.X.GardenPlotService:AddFlowerXP(player,state.Slot,1)
   self:AddMastery(player,id,1,active and (bee.Ability.BeeMasteryXPMultiplier or 1) or 1)
   self.X.RollService:Charge(player,C.Charge.Delivery*(p.Season.ActiveCard=="SummerSwarm" and .75 or 1)) self.X:Emit(player,"Delivery",1) self.X.SocialService:Contribute(player,1)
   for synergy in pairs(self.X.GardenSynergyService.Active[player] or {}) do p.GardenSynergies.Mastery[synergy]=(p.GardenSynergies.Mastery[synergy] or 0)+E.Value(p,"GARDEN_6","SynergyXP",1) end
   state.Slot=flowerSlots[(table.find(flowerSlots,state.Slot) or 1)%#flowerSlots+1]
   if not p.Tutorial.Events.PollenSpark then self.X.GardenActivityService:Offer(player,"PollenSpark",self.X.GardenPlotService:Position(player,state.Slot)) end
  end
 end end end
 if os.clock()>=(t.NextActivity or 0) then t.NextActivity=os.clock()+C.ActivityInterval*E.Value(p,"EXPLORATION_4","WildInterval",1)*(p.Season.ActiveCard=="SpringResonance" and .8 or 1) local kinds={"PollenSpark","NectarBud","DewDrop","PollenTrail","CrossPollination","BloomSurge","PollenWind"} t.ActivityIndex=(t.ActivityIndex or 0)%#kinds+1 self.X.GardenActivityService:Offer(player,kinds[t.ActivityIndex],self.X.GardenPlotService:Position(player,flowerSlots[1])) end
end
function S:Remove(player) self.States[player]=nil end
return S
