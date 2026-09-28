local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BloomConfig)
local Bees=require(RS.Config.BeesConfig)

local S={}

function S:Init(x)
 self.X=x
end

function S:QuestStatus(profile,nextLevel)
 local rule=C.HiveQuestRequirements[nextLevel]
 if not rule then return true,"No additional quest" end

 if rule.Discoveries then
  local total=self.X.U.Count(profile.FlowerCollection.DiscoveredFlowers)+self.X.U.Count(profile.Pollinators.DiscoveredBees)
  return total>=rule.Discoveries,string.format("Discover %d Flowers or Bees • %d/%d",rule.Discoveries,total,rule.Discoveries)
 end

 if rule.Synergies then
  local total=self.X.U.Count(profile.GardenSynergies.Discovered)
  return total>=rule.Synergies,string.format("Discover %d Garden Synergy • %d/%d",rule.Synergies,total,rule.Synergies)
 end

 if rule.BeeMasteryLevel then
  local best=1
  for id in pairs(profile.Pollinators.DiscoveredBees) do
   best=math.max(best,Bees.GetMasteryState(profile.Pollinators.BeeMastery[id]).Level)
  end
  return best>=rule.BeeMasteryLevel,string.format("Reach Bee Mastery Lv. %d • best Lv. %d",rule.BeeMasteryLevel,best)
 end

 if rule.Activities then
  local total=math.floor(tonumber(profile.Tutorial.Events.ActivityCompleted) or 0)
  return total>=rule.Activities,string.format("Complete %d Activities • %d/%d",rule.Activities,total,rule.Activities)
 end

 if rule.Trials then
  local total=self.X.U.Count(profile.Quests.Trials)
  return total>=rule.Trials,string.format("Complete %d Trial • %d/%d",rule.Trials,total,rule.Trials)
 end

 return true,"Quest complete"
end

function S:PromptText(profile)
 if (profile.Tutorial.Events.FirstGardenSlot or 0)==0 and not profile.Tutorial.Skipped then
  return "Unlock Garden Slot 1"
 end
 local nextLevel=profile.Hive.Level+1
 local cost=C.HiveCosts[nextLevel]
 if not cost then return "Hive MAX" end
 local ready=self:QuestStatus(profile,nextLevel)
 return ready
  and ("Upgrade Hive • "..math.floor(cost).." Honey")
  or ("Hive "..nextLevel.." Quest Required")
end

function S:Interact(player)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local hivePosition=self.X.GardenPlotService:HivePosition(player)
 if not hivePosition or not self.X.U.Near(player,hivePosition,C.InteractionDistance) then return false,"TOO_FAR" end

 if (p.Tutorial.Events.FirstGardenSlot or 0)==0 and not p.Tutorial.Skipped then
  self.X:Emit(player,"FirstGardenSlot",1)
  self.X.GardenPlotService:RefreshCapacity(player)
  self.X:Send(player,"Ceremony",{Kind="GardenSlot",Text="Garden Slot 1 unlocked"})
  return true
 end

 local nextLevel=p.Hive.Level+1
 local cost=C.HiveCosts[nextLevel]
 if not cost then
  self.X:Send(player,"Message","Hive is at max level")
  return false,"HIVE_MAX"
 end

 local questReady,questText=self:QuestStatus(p,nextLevel)
 if not questReady then
  self.X:Send(player,"Message","Hive "..nextLevel.." quest • "..questText)
  return false,"HIVE_QUEST_REQUIRED"
 end

 if p.Hive.Honey<cost then
  self.X:Send(player,"Message",string.format("Hive %d needs %d Honey • %d / %d",nextLevel,cost,math.floor(p.Hive.Honey),cost))
  return false,"HONEY_REQUIRED"
 end

 p.Hive.Honey-=cost
 p.Hive.Level=nextLevel

 local points=C.WorkshopPointHiveMilestones[nextLevel] or 0
 if points>0 then self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..nextLevel,points) end

 self.X.GardenPlotService:RefreshCapacity(player)
 self.X:Emit(player,"HiveUpgrade",1)
 self.X:Send(player,"Ceremony",{Kind="Hive",Text="Hive level "..p.Hive.Level})

 return true
end

return S
