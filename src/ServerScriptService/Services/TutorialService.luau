local RS=game:GetService("ReplicatedStorage")
local T=require(RS.Config.TutorialConfig)
local Features=require(RS.Config.FeatureUnlockConfig)
local Bloom=require(RS.Config.BloomConfig)
local Workshop=require(RS.Config.WorkshopConfig)
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)

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

local function hasFlower(profile)
 return next(profile.FlowerCollection.DiscoveredFlowers or {})~=nil
end

local function hasBee(profile)
 return next(profile.Pollinators.DiscoveredBees or {})~=nil
end

local function hasPlanted(profile)
 for _,slot in ipairs(profile.Garden.Slots or {}) do
  if slot.SpeciesId then return true end
 end
 return false
end

function S:Init(x)
 self.X=x
end

function S:LegacyStepComplete(p,step)
 local events=p.Tutorial.Events
 if step.Id=="GardenSlot" then return (events.FirstGardenSlot or 0)>0 or (tonumber(p.Garden.UnlockedSlots) or 0)>0 end
 if step.Id=="FirstFlowerRoll" then return (events.TutorialFlowerRoll or 0)>0 or (events.SeedReward or 0)>0 or hasFlower(p) end
 if step.Id=="Plant" then return (events.Plant or 0)>0 or hasPlanted(p) end
 if step.Id=="FirstBeeRoll" then return (events.TutorialBeeRoll or 0)>0 or (events.StarterBee or 0)>0 or hasBee(p) end
 if step.Id=="EquipBee" then
  if (events.EquipBee or 0)>0 then return true end
  for _,id in pairs(p.Pollinators.EquippedBeeSlots or {}) do if type(id)=="string" and id~="" then return true end end
  return false
 end
 if step.Id=="FillBloom" then return (events.BloomReady or 0)>0 or p.RollState.SpecialRollReady==true or (tonumber(p.RollState.BloomCharge) or 0)>=Bloom.BloomMax end
 if step.Id=="BloomRoll" then return (events.BloomRoll or 0)>0 end
 if step.Id=="InventoryExplain" then return (events.InventoryReviewed or 0)>0 or (events.SatchelOpen or 0)>0 end
 if step.Id=="PollenSpark" then return (events.PollenSpark or 0)>0 end
 if step.Id=="HiveUpgrade" then return p.Hive.Level>=2 or (events.HiveUpgrade or 0)>0 end
 if step.Id=="WorkshopPurchase" then return next(p.WorkshopV5.Nodes)~=nil or (events.WorkshopPurchase or 0)>0 end
 if step.Id=="Synergy" then return (events.Synergy or 0)>0 or next(p.GardenSynergies.Discovered or {})~=nil end
 if step.Id=="Quests" then return (events.QuestsOpen or 0)>0 end
 return (events[step.Event] or 0)>0
end

function S:Migrate(player,p)
 local t=p.Tutorial
 if t.Version==T.Version then return false end

 local wasComplete=t.Skipped or t.Events.TutorialComplete or t.Step>#T.Steps
 t.Version=T.Version
 if wasComplete then
  t.Step=#T.Steps+1
  t.Events.TutorialComplete=math.max(1,t.Events.TutorialComplete or 0)
  print("[Tutorial] migrated completed profile to v"..T.Version.." player="..playerName(player))
  return true
 end

 for _,step in ipairs(T.Steps) do
  if self:LegacyStepComplete(p,step) then t.Events[completionKey(step)]=1 else break end
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
  if rule.Node then t.FeatureUnlocks[id]=unlocked==true
  elseif unlocked then t.FeatureUnlocks[id]=true end
 end
end

function S:Assist(player,p)
 local step=currentStep(p)
 if not step then return end
 local t=p.Tutorial

 if step.Id=="FillBloom" and not t.Events.TutorialAssistBloom then
  local deliveryCharge=(Bloom.Charge and Bloom.Charge.Delivery) or 2
  local target=math.max(0,Bloom.BloomMax-deliveryCharge)
  if (tonumber(p.RollState.BloomCharge) or 0)<target then p.RollState.BloomCharge=target end
  p.RollState.SpecialRollReady=(tonumber(p.RollState.BloomCharge) or 0)>=Bloom.BloomMax
  t.Events.TutorialAssistBloom=1
  self.X:MarkStateDirty(player)
 elseif step.Id=="PollenSpark" then
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
  if Flowers.Species.Tulip and not p.FlowerCollection.DiscoveredFlowers.Tulip then
   self.X.InventoryService:Grant(player,"FlowerSeed","Tulip")
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

 local current=T.Steps[t.Step]
 if current and not t.Events[completionKey(current)] and (t.Events[current.Event] or 0)>0 then
  t.Events[completionKey(current)]=1
  self.X:MarkStateDirty(player)
 end

 local old=t.Step
 while T.Steps[t.Step] and t.Events[completionKey(T.Steps[t.Step])] do t.Step+=1 end
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
  print(string.format("[Tutorial] waiting step=%d id=%s event=%s player=%s",t.Step,step.Id,step.Event,playerName(player)))
 end
 self:Assist(player,p)
end

function S:Tick(player)
 local p=self.X:Profile(player)
 if not p then return false end
 self:Refresh(player)
 local step=currentStep(p)
 if not step then return false end

 if step.Id=="FillBloom" and (p.RollState.SpecialRollReady==true or (tonumber(p.RollState.BloomCharge) or 0)>=Bloom.BloomMax) then
  p.RollState.SpecialRollReady=true
  self.X:Emit(player,"BloomReady",1)
  return true
 elseif step.Id=="PollenSpark" then
  self.X.GardenActivityService:EnsureTutorialSpark(player)

 end
 return false
end

function S:Skip(player)
 local p=self.X:Profile(player)
 if not p then return end
 local f=p.FlowerCollection
 if not f.DiscoveredFlowers.Daisy then
  f.DiscoveredFlowers.Daisy=true
  f.OwnedSeedCopies.Daisy=1
  f.ObtainedFlowers.Daisy=math.max(1,f.ObtainedFlowers.Daisy or 0)
  f.FlowerMastery.Daisy=f.FlowerMastery.Daisy or {Level=1,XP=0}
 end
 local bees=p.Pollinators
 if not bees.DiscoveredBees.WorkerBee then
  bees.DiscoveredBees.WorkerBee=true
  bees.BeeInventory.WorkerBee=1
  bees.BeeObtained.WorkerBee=math.max(1,bees.BeeObtained.WorkerBee or 0)
  bees.BeeMastery.WorkerBee=bees.BeeMastery.WorkerBee or 0
 end
 p.Tutorial.Events.FirstGardenSlot=math.max(1,p.Tutorial.Events.FirstGardenSlot or 0)
 p.Tutorial.Version=T.Version
 p.Tutorial.Step=#T.Steps+1
 p.Tutorial.Skipped=true
 p.Pollinators.EquippedBeeSlots[1]="WorkerBee"
 for id,r in pairs(Features) do if not r.Node then p.Tutorial.FeatureUnlocks[id]=true end end
 self.LastWaiting[player]=nil
 self.X.GardenPlotService:RefreshCapacity(player)
 self.X.GardenSynergyService:Recalculate(player)
end

function S:Replay(player)
 self.X:Send(player,"Replay",T.Steps)
end

function S:Remove(player)
 self.LastWaiting[player]=nil
end

return S
