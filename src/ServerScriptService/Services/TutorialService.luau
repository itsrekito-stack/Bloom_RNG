local RS=game:GetService("ReplicatedStorage")
local T=require(RS.Config.TutorialConfig)
local Features=require(RS.Config.FeatureUnlockConfig)
local Bloom=require(RS.Config.BloomConfig)
local Workshop=require(RS.Config.WorkshopConfig)
local Flowers=require(RS.Config.FlowersConfig)

local S={LastWaiting={}}

local function currentStep(profile)
 return T.Steps[profile.Tutorial.Step]
end

local function playerName(player)
 return tostring(player and (player.Name or player.UserId) or "?")
end

local function completionKey(step)
 return "TutorialStep_"..step.Id
end

function S:Init(x)
 self.X=x
end

function S:LegacyStepComplete(p,step)
 local events=p.Tutorial.Events
 if step.Id=="HiveIntro" then return p.StarterBeeGranted or (events.StarterBee or 0)>0 or (events.Wake or 0)>0 end
 if step.Id=="StarterBee" then return p.StarterBeeGranted or (events.StarterBee or 0)>0 end
 if step.Id=="HiveUpgrade" then return p.Hive.Level>=2 or (events.HiveUpgrade or 0)>0 end
 if step.Id=="WorkshopPurchase" then return next(p.WorkshopV5.Nodes)~=nil or (events.WorkshopPurchase or 0)>0 end
 if step.Id=="SunnyVisit" then return (events.SunnyVisit or 0)>0 end
 return (events[step.Event] or 0)>0
end

function S:Migrate(player,p)
 local t=p.Tutorial
 if t.Version==T.Version then return false end

 local wasComplete=t.Events.TutorialComplete or t.Step>#T.Steps
 t.Version=T.Version
 if wasComplete then
  t.Step=#T.Steps+1
  t.Events.TutorialComplete=math.max(1,t.Events.TutorialComplete or 0)
  print("[Tutorial] migrated completed profile to v"..T.Version.." player="..playerName(player))
  return true
 end

 for _,step in ipairs(T.Steps) do
  if self:LegacyStepComplete(p,step) then
   t.Events[completionKey(step)]=1
  else
   break
  end
 end
 t.Step=1
 print("[Tutorial] migrated to v"..T.Version.." player="..playerName(player))
 return true
end

function S:RecordEvent(player,event)
 local p=self.X:Profile(player)
 if not p then return false end
 self:Migrate(player,p)
 local step=currentStep(p)
 if not step or step.Event~=event then return false end
 local key=completionKey(step)
 if p.Tutorial.Events[key] then return false end
 p.Tutorial.Events[key]=1
 self.X:MarkStateDirty(player)
 return true
end

function S:ApplyUnlocks(p)
 local t=p.Tutorial
 for id,rule in pairs(Features) do
  local unlocked=rule.Step and t.Step>=rule.Step
   or rule.Event and (t.Events[rule.Event] or 0)>0
   or rule.Node and p.WorkshopV5.Nodes[rule.Node]==true
  if rule.Node then
   t.FeatureUnlocks[id]=unlocked==true
  elseif unlocked then
   t.FeatureUnlocks[id]=true
  end
 end
end

function S:Assist(player,p)
 local step=currentStep(p)
 if not step then return end
 local t=p.Tutorial

 if step.Id=="PollenSpark" then
  self.X.GardenActivityService:EnsureTutorialSpark(player)
 elseif step.Id=="HiveUpgrade" and not t.Events.TutorialAssistHive then
  local need=Bloom.HiveCosts[p.Hive.Level+1]
  if need and p.Hive.Honey<need then p.Hive.Honey=need end
  t.Events.TutorialAssistHive=1
  self.X.GardenPlotService:RefreshHivePrompt(player)
  self.X:MarkStateDirty(player)
 elseif step.Id=="WorkshopPurchase" and not t.Events.TutorialAssistWorkshop then
  local node=Workshop.Nodes.ROLL_1
  if node then
   p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)
   p.Currencies.Coins=math.max(p.Currencies.Coins,node.Coins or 0)
  end
  t.Events.TutorialAssistWorkshop=1
  self.X:MarkStateDirty(player)
 elseif step.Id=="Synergy" and not t.Events.TutorialAssistSynergy then
  if Flowers.Species.Tulip and self.X.InventoryService:Available(p,"Tulip")<1 then
   p.FlowerCollection.DiscoveredFlowers.Tulip=true
   p.FlowerCollection.OwnedSeedCopies.Tulip=(p.FlowerCollection.OwnedSeedCopies.Tulip or 0)+1
  end
  t.Events.TutorialAssistSynergy=1
  self.X:MarkStateDirty(player)
 end
end

function S:Refresh(player)
 local p=self.X:Profile(player)
 if not p then return end
 local t=p.Tutorial
 self:Migrate(player,p)

 local old=t.Step
 while T.Steps[t.Step] and t.Events[completionKey(T.Steps[t.Step])] do
  t.Step+=1
 end

 self:ApplyUnlocks(p)

 if t.Step~=old then
  local completed=T.Steps[old]
  print(string.format("[Tutorial] step %d -> %d event=%s player=%s",old,t.Step,completed and completed.Event or "migration",playerName(player)))
  self.LastWaiting[player]=nil
 end

 if t.Step>#T.Steps then
  if not t.Events.TutorialComplete then self.X:EmitOnce(player,"TutorialComplete") end
  return
 end

 local step=T.Steps[t.Step]
 local waitKey=tostring(t.Step)..":"..step.Event
 if self.LastWaiting[player]~=waitKey then
  self.LastWaiting[player]=waitKey
  print(string.format("[Tutorial] waiting step=%d id=%s event=%s player=%s",t.Step,step.Id,step.Event,player.Name))
 end
 self:Assist(player,p)
end

function S:Tick(player)
 local p=self.X:Profile(player)
 if not p then return false end
 self:Refresh(player)
 local step=currentStep(p)
 if not step then return false end

 if step.Id=="HiveIntro" then
  local pos=self.X.GardenPlotService:HivePosition(player)
  if pos and self.X.U.Near(player,pos,6.5) then
   self.X:EmitOnce(player,"HiveApproach")
   return true
  end
 elseif step.Id=="StarterBee" and p.StarterBeeGranted then
  self.X:EmitOnce(player,"StarterBee")
  return true
 elseif step.Id=="PollenSpark" then
  self.X.GardenActivityService:EnsureTutorialSpark(player)
 end
 return false
end

function S:Skip(player)
 local p=self.X:Profile(player)
 if not p then return end
 if not p.StarterBeeGranted then self.X.HiveService:Interact(player) end
 p.Tutorial.Version=T.Version
 p.Tutorial.Step=#T.Steps+1
 p.Tutorial.Skipped=true
 for id,r in pairs(Features) do if not r.Node then p.Tutorial.FeatureUnlocks[id]=true end end
 self.LastWaiting[player]=nil
end

function S:Replay(player)
 self.X:Send(player,"Replay",T.Steps)
end

function S:Remove(player)
 self.LastWaiting[player]=nil
end

return S
