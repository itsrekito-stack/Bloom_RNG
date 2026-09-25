local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local Pool=require(RS.Config.RollPoolConfig) local S={Last={}} local rng=Random.new()
function S:Init(x) self.X=x end
function S:Charge(player,amount) local p=self.X:Profile(player) if p then p.RollState.BloomCharge=math.min(C.BloomMax,p.RollState.BloomCharge+amount) p.RollState.SpecialRollReady=p.RollState.BloomCharge>=C.BloomMax end end
function S:Odds(player) local p=self.X:Profile(player) if not p then return {} end local t=self.X.Temp[player] return Pool.Build(p,self.X.StatsService:Get(p).Luck+(t.Dew or 0)*.1,t) end
function S:Roll(player,automatic,requestId)
 local p=self.X:Profile(player) if not p or not p.Tutorial.FeatureUnlocks.Roll then return false,"LOCKED" end
 local cd=p.WorkshopV5.Nodes.ROLL_6 and .8 or p.WorkshopV5.Nodes.ROLL_5 and 1.2 or p.WorkshopV5.Nodes.ROLL_1 and 1.4 or C.RollCooldown if os.clock()-(self.Last[player] or -100)<cd then return false,"COOLDOWN" end
 local pool,total=self:Odds(player) if total<=0 then return false,"EMPTY_POOL" end
 local target=rng:NextNumber()*total local item=pool[#pool] for _,v in ipairs(pool) do target=target-v.Weight if target<=0 then item=v break end end
 self.Last[player]=os.clock() local special=p.RollState.SpecialRollReady local new=self.X.InventoryService:Grant(player,item.Kind,item.Id)
 p.RollState.TotalRolls=p.RollState.TotalRolls+1 p.RollState.DiscoveryPity=new and 0 or p.RollState.DiscoveryPity+1
 local temp=self.X.Temp[player] temp.Dew=0
 if special then p.RollState.BloomCharge=(p.WorkshopV5.Nodes.ROLL_2 and 10 or 0)+(p.WorkshopV5.Nodes.BLOOM_4 and 10 or 0) p.RollState.SpecialRollReady=false
  if item.Kind=="FlowerSeed" and p.WorkshopV5.Nodes.BLOOM_1 and rng:NextNumber()<C.SpecialMutationChance+(temp.Crystal and .15 or 0)+(p.WorkshopV5.Nodes.BLOOM_5 and .1 or 0) then temp.SeedMutation={Id=item.Id,Mutation="Radiant"} end temp.Crystal=nil temp.Eclipse=nil self.X:Emit(player,"BloomRoll",1)
 end
 self.X:Emit(player,"Roll",1) if automatic then self.X:Emit(player,"AutoRoll",1) end
 local result={RequestId=requestId,Kind=item.Kind,Id=item.Id,DisplayName=item.DisplayName,Rarity=item.Rarity,Odds=item.Odds,Chance=item.Chance,IsNew=new,IsSpecialRoll=special,Cooldown=cd}
 self.X:Send(player,"Reward",result) if item.Rarity=="Mythic" or item.Rarity=="Celestial" then self.X:Broadcast("RareFeed",{Player=player.DisplayName,Name=item.DisplayName,Rarity=item.Rarity}) end return true
end
function S:Remove(player) self.Last[player]=nil end
return S
