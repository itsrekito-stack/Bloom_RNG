local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BloomConfig)
local Pool=require(RS.Config.RollPoolConfig)
local T=require(RS.Config.TutorialConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={Last={}}
local rng=Random.new()

function S:Init(x)
 self.X=x
end

function S:Charge(player,amount)
 local p=self.X:Profile(player)
 if p then
  p.RollState.BloomCharge=math.min(C.BloomMax,p.RollState.BloomCharge+amount)
  p.RollState.SpecialRollReady=p.RollState.BloomCharge>=C.BloomMax
 end
end

local function tutorialPoolKind(profile)
 local step=T.Steps[profile.Tutorial.Step]
 if not step then return nil end
 if step.Id=="FirstFlowerRoll" then return "FlowerSeed" end
 if step.Id=="FirstBeeRoll" then return "Bee" end
 return nil
end

local function tutorialRollAllowed(profile)
 local step=T.Steps[profile.Tutorial.Step]
 if not step then return true end
 return step.Id=="FirstFlowerRoll" or step.Id=="FirstBeeRoll" or step.Id=="BloomRoll"
end

function S:Odds(player)
 local p=self.X:Profile(player)
 if not p then return {} end
 local t=self.X.Temp[player]
 local luck=self.X.BoostService and self.X.BoostService:RollLuck(player,p) or (self.X.StatsService:Get(p).Luck+(t.Dew or 0)*.1)
 local pool,total=Pool.Build(p,luck,t)
 local kind=tutorialPoolKind(p)
 if not kind then return pool,total end

 local filtered={}
 local filteredTotal=0
 for _,item in ipairs(pool) do
  if item.Kind==kind then
   table.insert(filtered,item)
   filteredTotal+=item.Weight
  end
 end
 if filteredTotal<=0 then return {},0 end
 for _,item in ipairs(filtered) do
  item.Chance=item.Weight/filteredTotal
  item.Odds=filteredTotal/item.Weight
 end
 return filtered,filteredTotal
end

local function tutorialReward(pool,stepId)
 if stepId=="FirstFlowerRoll" then
  for _,item in ipairs(pool) do if item.Kind=="FlowerSeed" and item.Id=="Daisy" then return item end end
  for _,item in ipairs(pool) do if item.Kind=="FlowerSeed" then return item end end
 elseif stepId=="FirstBeeRoll" then
  for _,item in ipairs(pool) do if item.Kind=="Bee" and item.Id=="WorkerBee" then return item end end
  for _,item in ipairs(pool) do if item.Kind=="Bee" then return item end end
 end
 return nil
end

function S:Roll(player,automatic,requestId)
 local p=self.X:Profile(player)
 if not p or not p.Tutorial.FeatureUnlocks.Roll then return false,"LOCKED" end
 if not tutorialRollAllowed(p) then return false,"TUTORIAL_ROLL_LOCKED" end
 if T.Steps[p.Tutorial.Step] and automatic then return false,"TUTORIAL_SINGLE_ROLL" end

 local cd=E.Value(p,"ROLL_6","RollCooldown",E.Value(p,"ROLL_5","RollCooldown",E.Value(p,"ROLL_1","RollCooldown",C.RollCooldown)))
 if os.clock()-(self.Last[player] or -100)<cd then return false,"COOLDOWN" end

 local pool,total=self:Odds(player)
 if total<=0 then return false,"EMPTY_POOL" end

 local tutorialStep=T.Steps[p.Tutorial.Step]
 local item=tutorialStep and tutorialReward(pool,tutorialStep.Id) or nil
 if not item then
  local target=rng:NextNumber()*total
  item=pool[#pool]
  for _,candidate in ipairs(pool) do
   target-=candidate.Weight
   if target<=0 then item=candidate break end
  end
 end

 self.Last[player]=os.clock()
 local special=p.RollState.SpecialRollReady
 local serverBloomLuck=self.X.BoostService and self.X.BoostService.ConsumeServerBloomRoll and self.X.BoostService:ConsumeServerBloomRoll(player) or false
 local new=self.X.InventoryService:Grant(player,item.Kind,item.Id)

 p.RollState.TotalRolls+=1
 p.RollState.DiscoveryPity=new and 0 or math.min(C.DiscoveryThreshold,p.RollState.DiscoveryPity+1)

 local temp=self.X.Temp[player]
 temp.Dew=0

 if special then
  local reserve=E.Value(p,"ROLL_2","Reserve",0)+E.Value(p,"BLOOM_4","Reserve",0)
  p.RollState.BloomCharge=math.clamp(reserve,0,math.max(0,C.BloomMax-1))
  p.RollState.SpecialRollReady=false
  if item.Kind=="FlowerSeed"
   and p.WorkshopV5.Nodes.BLOOM_1
   and rng:NextNumber()<C.SpecialMutationChance+(temp.Crystal and .15 or 0)+E.Value(p,"BLOOM_5","MutationChance",0)
  then
   temp.SeedMutation={Id=item.Id,Mutation="Radiant"}
  end
  temp.Crystal=nil
  temp.Eclipse=nil
  self.X:Emit(player,"BloomRoll",1)
 end

 if tutorialStep and tutorialStep.Id=="FirstFlowerRoll" and item.Kind=="FlowerSeed" then
  self.X:Emit(player,"TutorialFlowerRoll",1)
 elseif tutorialStep and tutorialStep.Id=="FirstBeeRoll" and item.Kind=="Bee" then
  self.X:Emit(player,"TutorialBeeRoll",1)
 end

 self.X:Emit(player,"Roll",1)
 if automatic then self.X:Emit(player,"AutoRoll",1) end

 local result={
  RequestId=requestId,
  Kind=item.Kind,
  Id=item.Id,
  DisplayName=item.DisplayName,
  Rarity=item.Rarity,
  Odds=item.Odds,
  Chance=item.Chance,
  IsNew=new,
  IsSpecialRoll=special,
  ServerBloomLuck=serverBloomLuck,
  Cooldown=cd,
 }
 self.X:Send(player,"Reward",result)
 if item.Rarity=="Mythic" or item.Rarity=="Celestial" then
  self.X:Broadcast("RareFeed",{Player=player.DisplayName,Name=item.DisplayName,Rarity=item.Rarity})
 end
 return true
end

function S:Remove(player)
 self.Last[player]=nil
end

return S
