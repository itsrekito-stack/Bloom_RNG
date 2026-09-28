local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.QuestConfig)
local Bees=require(RS.Config.BeesConfig)
local Effects=require(RS.Shared.WorkshopEffects)

local S={}

local function count(map)
 local n=0
 for _,value in pairs(map or {}) do if value then n+=1 end end
 return n
end

local function rewardText(reward)
 local out={}
 if (reward.Coins or 0)>0 then out[#out+1]=tostring(reward.Coins).." Coins" end
 if (reward.PetalDust or 0)>0 then out[#out+1]=tostring(reward.PetalDust).." Petal Dust" end
 if (reward.WorkshopPoints or 0)>0 then out[#out+1]=tostring(reward.WorkshopPoints).." Workshop Point"..((reward.WorkshopPoints or 0)==1 and "" or "s") end
 if (reward.AncientNectar or 0)>0 then out[#out+1]=tostring(reward.AncientNectar).." Ancient Nectar" end
 return #out>0 and table.concat(out," • ") or "Progression"
end

function S:Init(x)
 self.X=x
end

function S:Progress(profile,quest)
 local kind=quest.Kind
 if kind=="Event" then return math.max(0,math.floor(tonumber(profile.Tutorial.Events[quest.Event]) or 0)) end
 if kind=="HiveLevel" then return math.max(1,math.floor(tonumber(profile.Hive.Level) or 1)) end
 if kind=="FlowerDiscoveries" then return count(profile.FlowerCollection.DiscoveredFlowers) end
 if kind=="BeeDiscoveries" then return count(profile.Pollinators.DiscoveredBees) end
 if kind=="TotalDiscoveries" then return count(profile.FlowerCollection.DiscoveredFlowers)+count(profile.Pollinators.DiscoveredBees) end
 if kind=="GardenSynergies" then return count(profile.GardenSynergies.Discovered) end
 if kind=="WorkshopNodes" then return count(profile.WorkshopV5.Nodes) end
 if kind=="TotalHoney" then return math.max(0,math.floor(tonumber(profile.Hive.TotalHoney) or 0)) end
 if kind=="BestBeeMastery" then
  local best=1
  for id in pairs(profile.Pollinators.DiscoveredBees or {}) do
   local state=Bees.GetMasteryState(profile.Pollinators.BeeMastery[id])
   best=math.max(best,tonumber(state.Level) or 1)
  end
  return best
 end
 return 0
end

function S:ClaimedCount(profile)
 local n=0
 for _,id in ipairs(C.Order) do if profile.Quests.Claimed[id]==true then n+=1 end end
 return n
end

function S:SyncJourney(profile)
 local step=#C.Order+1
 for i,id in ipairs(C.Order) do
  if profile.Quests.Claimed[id]~=true then step=i break end
 end
 profile.Quests.JourneyStep=step
 return step
end

function S:State(profile)
 self:SyncJourney(profile)
 local items={}
 local previousClaimed=true
 for order,id in ipairs(C.Order) do
  local quest=C.Get(id)
  local claimed=profile.Quests.Claimed[id]==true
  local unlocked=previousClaimed
  local current=self:Progress(profile,quest)
  local target=math.max(1,math.floor(tonumber(quest.Target) or 1))
  local complete=current>=target
  items[#items+1]={
   Id=id,Order=order,Title=quest.Title,Description=quest.Text,Kind=quest.Kind,
   Current=math.min(current,target),RawCurrent=current,Target=target,Progress=math.clamp(current/target,0,1),
   Claimed=claimed,Unlocked=unlocked,Claimable=unlocked and complete and not claimed,
   Reward=quest.Reward,RewardText=rewardText(quest.Reward),
  }
  previousClaimed=claimed
 end
 return {Items=items,Completed=self:ClaimedCount(profile),Total=#C.Order,CurrentStep=profile.Quests.JourneyStep}
end

function S:Claim(player,id)
 local profile=self.X:Profile(player)
 if not profile then return false,"PROFILE_LOADING" end
 local quest=C.Get(id)
 if not quest then return false,"INVALID_ITEM" end
 if profile.Quests.Claimed[id]==true then return false,"OWNED" end

 local order=table.find(C.Order,id)
 if not order then return false,"INVALID_ITEM" end
 if order>1 and profile.Quests.Claimed[C.Order[order-1]]~=true then return false,"QUEST_LOCKED" end

 local current=self:Progress(profile,quest)
 local target=math.max(1,math.floor(tonumber(quest.Target) or 1))
 if current<target then return false,"QUEST_INCOMPLETE" end

 local reward=quest.Reward or {}
 local bonus=math.max(1,tonumber(Effects.Value(profile,"LEGACY_4","QuestRewardMultiplier",1)) or 1)
 profile.Currencies.Coins+=math.floor((tonumber(reward.Coins) or 0)*bonus+.5)
 profile.Currencies.PetalDust+=math.floor((tonumber(reward.PetalDust) or 0)*bonus+.5)
 profile.Currencies.AncientNectar+=(tonumber(reward.AncientNectar) or 0)
 local points=math.max(0,math.floor(tonumber(reward.WorkshopPoints) or 0))
 if points>0 then self.X.WorkshopService:Point(player,"Quest_"..id,points) end

 profile.Quests.Claimed[id]=true
 self:SyncJourney(profile)
 self.X:Send(player,"Ceremony",{Kind="Quest",Text=quest.Title.." complete • "..rewardText(reward)})
 return true
end

return S
