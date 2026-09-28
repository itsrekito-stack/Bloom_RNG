local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Config.FlowersConfig)
local G=require(RS.Config.GardenSynergyConfig)
local C=require(RS.Config.BloomConfig)
local T=require(RS.Config.TutorialConfig)
local Rules=require(RS.Shared.GardenRules)

local S={Plots={},Used={},EditorSessions={}}
local FLOWER_SCALE_CAP=.55

local function horizontalCylinder(part,material)
 part.Shape=Enum.PartType.Cylinder
 part.CFrame=CFrame.new(part.Position)*CFrame.Angles(0,0,math.rad(90))
 if material then part.Material=material end
end

local function flowerVisualScale(level,growth)
 local scalePerLevel=tonumber(growth.ScalePerLevel) or .025
 return 1+math.min(FLOWER_SCALE_CAP,math.max(0,(level-1)*scalePerLevel))
end

function S:Init(x)
 self.X=x
end

function S:OpenEditor(player)
 local p=self.X:Profile(player)
 if not p or not p.Tutorial.FeatureUnlocks.Garden then return false,"LOCKED" end
 self.EditorSessions[player]=workspace:GetServerTimeNow()+600
 return true
end

function S:CloseEditor(player)
 self.EditorSessions[player]=nil
end

function S:Position(player,slot)
 local plot=self.Plots[player]
 return plot and plot.Origin+G.Position(slot)
end

function S:HivePosition(player)
 local plot=self.Plots[player]
 return plot and plot.Origin+G.Layout.HiveOffset
end

function S:HivePromptText(p)
 if self.X and self.X.HiveService then return self.X.HiveService:PromptText(p) end
 if (p.Tutorial.Events.FirstGardenSlot or 0)==0 and not p.Tutorial.Skipped then return "Unlock Garden Slot 1" end
 local cost=C.HiveUpgradeCost(p.Hive.Level+1)
 return "Upgrade Hive • "..math.floor(cost).." Honey"
end

function S:RefreshHivePrompt(player)
 local p=self.X:Profile(player)
 local plot=self.Plots[player]
 if not p or not plot then return false end
 local hive=plot.Model:FindFirstChild("Hive")
 local prompt=hive and hive:FindFirstChildOfClass("ProximityPrompt")
 if not prompt then return false end
 prompt.ActionText=self:HivePromptText(p)
 prompt.ObjectText="Hive • Level "..p.Hive.Level
 return true
end

function S:AddFlowerXP(player,i,amount)
 local p=self.X:Profile(player)
 if not p or type(i)~="number" or i%1~=0 or type(amount)~="number" or amount~=amount or amount<=0 then return false end
 local slot=p.Garden.Slots[i]
 local flower=slot and slot.SpeciesId and F.Species[slot.SpeciesId]
 if not flower then return false end
 local mastery=self.X.FlowerProgressionService:State(p,slot.SpeciesId)
 local growth=flower.GrowthProfile or {ScalePerLevel=.025}
 slot.TotalPollination=math.max(0,tonumber(slot.TotalPollination) or 0)+amount

 local plot=self.Plots[player]
 local model=plot and plot.Flowers[i]
 if model then
  model:ScaleTo(flowerVisualScale(mastery.Level,growth))
  local levelText=model:FindFirstChild("LevelText",true)
  local fill=model:FindFirstChild("ProgressFill",true)
  if levelText then levelText.Text=flower.DisplayName.." • LV."..mastery.Level end
  if fill then fill.Size=UDim2.fromScale(mastery.Level>=C.MasteryCap and 1 or math.clamp(mastery.XP/math.max(1,mastery.Level*C.MasteryXP),0,1),1) end
 end
 return true
end

function S:Build(player)
 local p=self.X:Profile(player)
 if not p then return end
 local plot=self.Plots[player]

 if not plot then
  local i=1
  while self.Used[i] do i+=1 end
  self.Used[i]=true

  local a=(i-1)%12*math.pi*2/12
  local r=105+math.floor((i-1)/12)*60
  local origin=self.X.Origin+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)

  local m=Instance.new("Model")
  m.Name="Garden_"..player.UserId
  m:SetAttribute("OwnerUserId",player.UserId)
  m.Parent=self.X.World

  plot={Index=i,Origin=origin,Model=m,Flowers={}}
  self.Plots[player]=plot

  local ground=self.X:Part(m,"Ground",origin-Vector3.new(0,.5,0),Vector3.new(1,33,33),Color3.fromRGB(85,145,80),true)
  horizontalCylinder(ground,Enum.Material.Grass)

  local border=self.X:Part(m,"Border",origin+Vector3.new(0,.025,0),Vector3.new(.05,25,25),Color3.fromRGB(190,154,111),false)
  horizontalCylinder(border,Enum.Material.Sandstone)
  border.CanQuery=false

  local soil=self.X:Part(m,"Soil",origin+Vector3.new(0,.045,0),Vector3.new(.05,23,23),Color3.fromRGB(105,76,52),false)
  horizontalCylinder(soil,Enum.Material.Ground)
  soil.CanQuery=false

  local hivePosition=self:HivePosition(player)
  local hiveBasePosition=origin+Vector3.new(G.Layout.HiveOffset.X,.06,G.Layout.HiveOffset.Z)
  local hiveBase=self.X:Part(m,"HiveBase",hiveBasePosition,Vector3.new(.12,4.3,4.3),Color3.fromRGB(118,112,102),false)
  horizontalCylinder(hiveBase,Enum.Material.Slate)
  hiveBase.CanQuery=false

  local hive=self.X:Part(m,"Hive",hivePosition,Vector3.new(4,4.1,4.1),Color3.fromRGB(224,169,56),true)
  horizontalCylinder(hive,Enum.Material.WoodPlanks)

  local entrance=self.X:Part(m,"HiveEntrance",hivePosition+Vector3.new(0,-.22,-2.05),Vector3.new(.85,.85,.85),Color3.fromRGB(61,47,37),false)
  entrance.Shape=Enum.PartType.Ball
  entrance.Material=Enum.Material.SmoothPlastic
  entrance.CanQuery=false

  self.X:Prompt(hive,self:HivePromptText(p),function(who)
   if who==player then
    self.X.HiveService:Interact(player)
   else
    self.X.SocialService:Bless(who,player)
   end
  end)
 end

 if plot.Content then plot.Content:Destroy() end
 plot.Flowers={}
 local content=Instance.new("Folder")
 content.Name="Flowers"
 content.Parent=plot.Model
 plot.Content=content

 for i=1,C.MaxFlowerSlots do
  local pos=self:Position(player,i)
  local unlocked=i<=p.Garden.UnlockedSlots
  local pad=self.X:Part(
   content,
   "Slot_"..i,
   pos-Vector3.new(0,.015,0),
   Vector3.new(.03,3.6,3.6),
   unlocked and Color3.fromRGB(140,101,65) or Color3.fromRGB(72,70,68),
   false
  )
  local ghost=i==C.MaxFlowerSlots and not unlocked
  horizontalCylinder(pad,unlocked and Enum.Material.Ground or (ghost and Enum.Material.ForceField or Enum.Material.Slate))
  pad.Transparency=ghost and .62 or 0
  if ghost then
   pad.Color=Color3.fromRGB(80,190,235)
  end
  pad.CanQuery=unlocked
  pad:SetAttribute("OwnerUserId",player.UserId)
  pad:SetAttribute("SlotId",i)
  pad:SetAttribute("GhostSlot",ghost)

  if unlocked then
   local slot=p.Garden.Slots[i]
   local f=slot and F.Species[slot.SpeciesId]
   if f then
    local growth=f.GrowthProfile or {}
    local mastery=self.X.FlowerProgressionService:State(p,slot.SpeciesId)
    local flower=self.X.FlowerService.Build(i,f,pos)
    flower.Parent=content
    flower:ScaleTo(flowerVisualScale(mastery.Level,growth))
    local levelText=flower:FindFirstChild("LevelText",true)
    local fill=flower:FindFirstChild("ProgressFill",true)
    if levelText then levelText.Text=f.DisplayName.." • LV."..mastery.Level end
    if fill then fill.Size=UDim2.fromScale(mastery.Level>=C.MasteryCap and 1 or math.clamp(mastery.XP/math.max(1,mastery.Level*C.MasteryXP),0,1),1) end
    plot.Flowers[i]=flower
   end
  end
 end

 self.X.GardenSynergyService:Recalculate(player)
 self:RefreshHivePrompt(player)
end

function S:Plant(player,i,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if not self.X.U.Integer(i,p.Garden.UnlockedSlots) then return false,"INVALID_SLOT" end
 local tutorialStep=T.Steps[p.Tutorial.Step]
 if tutorialStep and tutorialStep.Id=="Plant" and i~=(tutorialStep.Slot or 1) then return false,"TUTORIAL_TARGET" end
 if tutorialStep and tutorialStep.Id=="Synergy" and (i~=(tutorialStep.Slot or 2) or id~="Tulip") then return false,"TUTORIAL_TARGET" end
 local pos=self:Position(player,i)
 if not pos or not self.X.U.Near(player,pos,C.InteractionDistance) then return false,"TOO_FAR" end
 if id~="" and (type(id)~="string" or not F.Exists(id)) then return false,"INVALID_ITEM" end
 local old=p.Garden.Slots[i]
 if old.SpeciesId==id then return true end
 if id~="" then
  for slotIndex,existing in ipairs(p.Garden.Slots) do
   if slotIndex~=i and existing.SpeciesId==id then return false,"ALREADY_PLANTED" end
  end
  if self.X.InventoryService:Available(p,id)<1 then return false,"NO_FREE_COPY" end
 end

 local slot={}
 if id~="" then
  slot={SpeciesId=id,TotalPollination=0,Mutation=""}
  local mutation=self.X.Temp[player].SeedMutation
  if mutation and mutation.Id==id then
   slot.Mutation=mutation.Mutation
   self.X.Temp[player].SeedMutation=nil
  end
 end

 p.Garden.Slots[i]=slot
 p.Garden.Revision+=1
 self.X.GardenActivityService:CancelGarden(player)
 self:Build(player)
 if id~="" then self.X:Emit(player,"Plant",1) end
 return true
end

function S:GardenEdit(player,i,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local temp=self.X.Temp[player]
 if not temp or temp.MenuOpen~=true or temp.MenuName~="Garden" then return false,"MENU_REQUIRED" end
 if (self.EditorSessions[player] or 0)<workspace:GetServerTimeNow() then return false,"ACTION_UNAVAILABLE" end
 if not self.X.U.Integer(i,p.Garden.UnlockedSlots) then return false,"INVALID_SLOT" end
 local tutorialStep=T.Steps[p.Tutorial.Step]
 if tutorialStep and tutorialStep.Id=="Plant" and i~=(tutorialStep.Slot or 1) then return false,"TUTORIAL_TARGET" end
 if tutorialStep and tutorialStep.Id=="Synergy" and (i~=(tutorialStep.Slot or 2) or id~="Tulip") then return false,"TUTORIAL_TARGET" end
 if id~="" and (type(id)~="string" or not F.Exists(id)) then return false,"INVALID_ITEM" end
 local old=p.Garden.Slots[i]
 if old.SpeciesId==id then return true end

 local sourceIndex=nil
 if id~="" then
  if (p.FlowerCollection.OwnedSeedCopies[id] or 0)<1 then return false,"NOT_OWNED" end
  for slotIndex,existing in ipairs(p.Garden.Slots) do
   if slotIndex~=i and existing.SpeciesId==id then sourceIndex=slotIndex break end
  end
 end

 local slot={}
 if id~="" then
  if sourceIndex then
   local source=p.Garden.Slots[sourceIndex]
   slot={SpeciesId=id,TotalPollination=tonumber(source.TotalPollination) or 0,Mutation=source.Mutation or ""}
   p.Garden.Slots[sourceIndex]={}
  else
   slot={SpeciesId=id,TotalPollination=0,Mutation=""}
   local mutation=self.X.Temp[player].SeedMutation
   if mutation and mutation.Id==id then
    slot.Mutation=mutation.Mutation
    self.X.Temp[player].SeedMutation=nil
   end
  end
 end

 p.Garden.Slots[i]=slot
 p.Garden.Revision+=1
 self.EditorSessions[player]=workspace:GetServerTimeNow()+600
 self.X.GardenActivityService:CancelGarden(player)
 self:Build(player)
 if id~="" then self.X:Emit(player,"Plant",1) end
 return true
end

function S:RefreshCapacity(player)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local capacity=Rules.FlowerCapacity(p)
 if Rules.HasOverflow(p.Garden.Slots,capacity) then return false,"RESPEC_GARDEN_OCCUPIED" end
 p.Garden.UnlockedSlots=capacity
 self:Build(player)
 return true
end

function S:Remove(player)
 self.EditorSessions[player]=nil
 self.EditorSessions[player]=nil
 local plot=self.Plots[player]
 if plot then
  self.Used[plot.Index]=nil
  plot.Model:Destroy()
  self.Plots[player]=nil
 end
end

return S
