local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local Pool=require(RS.Config.RollPoolConfig) local T=require(RS.Config.TutorialConfig) local E=require(RS.Shared.WorkshopEffects) local S={Last={}} local rng=Random.new()
function S:Init(x) self.X=x end
function S:Charge(player,amount) local p=self.X:Profile(player) if p then p.RollState.BloomCharge=math.min(C.BloomMax,p.RollState.BloomCharge+amount) p.RollState.SpecialRollReady=p.RollState.BloomCharge>=C.BloomMax end end
function S:Odds(player) local p=self.X:Profile(player) if not p then return {} end local t=self.X.Temp[player] local luck=self.X.BoostService and self.X.BoostService:RollLuck(player,p) or (self.X.StatsService:Get(p).Luck+(t.Dew or 0)*.1) return Pool.Build(p,luck,t) end
function S:Roll(player,automatic,requestId)
 local p=self.X:Profile(player) if not p or not p.Tutorial.FeatureUnlocks.Roll then return false,"LOCKED" end
 local cd=E.Value(p,"ROLL_6","RollCooldown",E.Value(p,"ROLL_5","RollCooldown",E.Value(p,"ROLL_1","RollCooldown",C.RollCooldown))) if os.clock()-(self.Last[player] or -100)<cd then return false,"COOLDOWN" end
 local pool,total=self:Odds(player) if total<=0 then return false,"EMPTY_POOL" end
 local item=nil
 local tutorialStep=T.Steps[p.Tutorial.Step]
 if tutorialStep and (tutorialStep.Id=="Roll" or tutorialStep.Id=="FirstSeed") and (p.Tutorial.Events.SeedReward or 0)==0 then
  for _,v in ipairs(pool) do
   if v.Kind=="FlowerSeed" and v.Id=="Sunflower" then item=v break end
  end
  if not item then for _,v in ipairs(pool) do if v.Kind=="FlowerSeed" then item=v break end end end
 end
 if not item then
  local target=rng:NextNumber()*total item=pool[#pool]
  for _,v in ipairs(pool) do target=target-v.Weight if target<=0 then item=v break end end
 end
 self.Last[player]=os.clock() local special=p.RollState.SpecialRollReady local new=self.X.InventoryService:Grant(player,item.Kind,item.Id)
 p.RollState.TotalRolls=p.RollState.TotalRolls+1 p.RollState.DiscoveryPity=new and 0 or math.min(C.DiscoveryThreshold,p.RollState.DiscoveryPity+1)
 local temp=self.X.Temp[player] temp.Dew=0
 if special then local reserve=E.Value(p,"ROLL_2","Reserve",0)+E.Value(p,"BLOOM_4","Reserve",0) p.RollState.BloomCharge=math.clamp(reserve,0,math.max(0,C.BloomMax-1)) p.RollState.SpecialRollReady=false
  if item.Kind=="FlowerSeed" and p.WorkshopV5.Nodes.BLOOM_1 and rng:NextNumber()<C.SpecialMutationChance+(temp.Crystal and .15 or 0)+E.Value(p,"BLOOM_5","MutationChance",0) then temp.SeedMutation={Id=item.Id,Mutation="Radiant"} end temp.Crystal=nil temp.Eclipse=nil self.X:Emit(player,"BloomRoll",1)
 end
 self.X:Emit(player,"Roll",1) if automatic then self.X:Emit(player,"AutoRoll",1) end
 local result={RequestId=requestId,Kind=item.Kind,Id=item.Id,DisplayName=item.DisplayName,Rarity=item.Rarity,Odds=item.Odds,Chance=item.Chance,IsNew=new,IsSpecialRoll=special,Cooldown=cd}
 self.X:Send(player,"Reward",result) if item.Rarity=="Mythic" or item.Rarity=="Celestial" then self.X:Broadcast("RareFeed",{Player=player.DisplayName,Name=item.DisplayName,Rarity=item.Rarity}) end return true
end
function S:Remove(player) self.Last[player]=nil end
return S
