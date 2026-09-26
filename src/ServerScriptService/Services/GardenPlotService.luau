local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local G=require(RS.Config.GardenSynergyConfig) local C=require(RS.Config.BloomConfig) local T=require(RS.Config.TutorialConfig)
local Rules=require(RS.Shared.GardenRules)
local S={Plots={},Used={}}
function S:Init(x) self.X=x end
function S:Position(player,slot) local plot=self.Plots[player] return plot and plot.Origin+G.Position(slot) end
function S:HivePosition(player) local plot=self.Plots[player] return plot and plot.Origin+Vector3.new(0,1,19) end
function S:HivePromptText(p)
 local inventory=p and p.Pollinators and p.Pollinators.BeeInventory
 local ownsStarter=type(inventory)=="table" and (tonumber(inventory.WorkerBee) or 0)>0
 if not ownsStarter then return "Get Worker Bee" end
 local cost=C.HiveCosts[p.Hive.Level+1]
 return cost and ("Upgrade Hive • "..math.floor(cost).." Honey") or "Hive MAX"
end
function S:RefreshHivePrompt(player)
 local p=self.X:Profile(player) local plot=self.Plots[player] if not p or not plot then return false end
 local hive=plot.Model:FindFirstChild("Hive") local prompt=hive and hive:FindFirstChildOfClass("ProximityPrompt")
 if not prompt then return false end
 prompt.ActionText=self:HivePromptText(p)
 prompt.ObjectText="Hive • Level "..p.Hive.Level
 return true
end
function S:AddFlowerXP(player,i,amount)
 local p=self.X:Profile(player) if not p or type(i)~="number" or i%1~=0 or type(amount)~="number" or amount~=amount or amount<=0 then return false end
 local slot=p.Garden.Slots[i] local flower=slot and slot.SpeciesId and F.Species[slot.SpeciesId] if not flower then return false end
 local growth=flower.GrowthProfile or {XPPerLevel=C.FlowerLevelXP,MaxLevel=C.MasteryCap,ScalePerLevel=.025}
 local xpPerLevel=math.max(1,tonumber(growth.XPPerLevel) or C.FlowerLevelXP) local maxLevel=math.max(1,math.floor(tonumber(growth.MaxLevel) or C.MasteryCap))
 local level=math.clamp(math.floor(tonumber(slot.Level) or 1),1,maxLevel) local xp=math.max(0,tonumber(slot.XP) or 0)+amount
 while level<maxLevel do local need=level*xpPerLevel if xp<need then break end xp-=need level+=1 end
 if level>=maxLevel then xp=math.min(xp,level*xpPerLevel) end
 slot.Level=level slot.XP=xp slot.TotalPollination=math.max(0,tonumber(slot.TotalPollination) or 0)+amount
 self.X.FlowerProgressionService:Add(player,slot.SpeciesId,amount)
 local plot=self.Plots[player] local model=plot and plot.Flowers[i]
 if model then
  local scalePerLevel=tonumber(growth.ScalePerLevel) or .025 model:ScaleTo(1+math.min(2,(level-1)*scalePerLevel))
  local levelText=model:FindFirstChild("LevelText",true) local fill=model:FindFirstChild("ProgressFill",true)
  if levelText then levelText.Text=flower.DisplayName.." • LV."..level end
  if fill then fill.Size=UDim2.fromScale(level>=maxLevel and 1 or math.clamp(xp/math.max(1,level*xpPerLevel),0,1),1) end
 end
 return true
end
function S:Build(player)
 local p=self.X:Profile(player) if not p then return end local plot=self.Plots[player]
 if not plot then local i=1 while self.Used[i] do i=i+1 end self.Used[i]=true local a=(i-1)%12*math.pi*2/12 local r=105+math.floor((i-1)/12)*60 local origin=self.X.Origin+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
  local m=Instance.new("Model") m.Name="Garden_"..player.UserId m:SetAttribute("OwnerUserId",player.UserId) m.Parent=self.X.World
  plot={Index=i,Origin=origin,Model=m,Flowers={}} self.Plots[player]=plot
  local base=self.X:Part(m,"Ground",origin-Vector3.new(0,1,0),Vector3.new(2,50,50),Color3.fromRGB(83,137,78),true)
  base.Shape=Enum.PartType.Cylinder
  base.CFrame=CFrame.new(base.Position)*CFrame.Angles(0,0,math.rad(90))
  base.Material=Enum.Material.Grass

  local border=self.X:Part(m,"PlotBorder",origin-Vector3.new(0,.08,0),Vector3.new(.26,47,47),Color3.fromRGB(181,154,108),false)
  border.Shape=Enum.PartType.Cylinder
  border.CFrame=CFrame.new(border.Position)*CFrame.Angles(0,0,math.rad(90))
  border.Material=Enum.Material.Sandstone
  border.CanQuery=false

  local bed=self.X:Part(m,"GardenBed",origin+Vector3.new(0,.08,-2),Vector3.new(.18,36,31),Color3.fromRGB(116,88,61),false)
  bed.Shape=Enum.PartType.Cylinder
  bed.CFrame=CFrame.new(bed.Position)*CFrame.Angles(0,0,math.rad(90))
  bed.Material=Enum.Material.Ground
  bed.CanQuery=false

  local hivePosition=self:HivePosition(player)
  local hiveBase=self.X:Part(m,"HiveBase",hivePosition-Vector3.new(0,1.15,0),Vector3.new(.5,7.4,7.4),Color3.fromRGB(92,83,72),false)
  hiveBase.Shape=Enum.PartType.Cylinder
  hiveBase.CFrame=CFrame.new(hiveBase.Position)*CFrame.Angles(0,0,math.rad(90))
  hiveBase.Material=Enum.Material.Slate
  hiveBase.CanQuery=false

  local hive=self.X:Part(m,"Hive",hivePosition,Vector3.new(4.4,5.4,5.4),Color3.fromRGB(224,169,56),true)
  hive.Shape=Enum.PartType.Cylinder
  hive.CFrame=CFrame.new(hive.Position)*CFrame.Angles(0,0,math.rad(90))
  hive.Material=Enum.Material.WoodPlanks

  for ringIndex,offset in ipairs({-1.25,0,1.25}) do
   local diameter=6.1-math.abs(offset)*.55
   local ring=self.X:Part(m,"HiveBand_"..ringIndex,hivePosition+Vector3.new(0,offset,0),Vector3.new(.22,diameter,diameter),Color3.fromRGB(246,196,78),false)
   ring.Shape=Enum.PartType.Cylinder
   ring.CFrame=CFrame.new(ring.Position)*CFrame.Angles(0,0,math.rad(90))
   ring.Material=Enum.Material.SmoothPlastic
   ring.CanQuery=false
  end

  local entrance=self.X:Part(m,"HiveEntrance",hivePosition+Vector3.new(0,-.15,-2.72),Vector3.new(1.9,1.9,.25),Color3.fromRGB(63,49,42),false)
  entrance.Shape=Enum.PartType.Cylinder
  entrance.CFrame=CFrame.new(entrance.Position)*CFrame.Angles(math.rad(90),0,0)
  entrance.Material=Enum.Material.SmoothPlastic
  entrance.CanQuery=false

  self.X:Prompt(hive,self:HivePromptText(p),function(who) if who==player then self.X.HiveService:Interact(player) else self.X.SocialService:Bless(who,player) end end)
 end
 if plot.Content then plot.Content:Destroy() end plot.Flowers={} local content=Instance.new("Folder") content.Name="Flowers" content.Parent=plot.Model plot.Content=content
 for i=1,C.MaxFlowerSlots do local pos=self:Position(player,i) local unlocked=i<=p.Garden.UnlockedSlots
  local pad=self.X:Part(content,"Slot_"..i,pos,Vector3.new(.28,5.2,5.2),unlocked and Color3.fromRGB(166,126,78) or Color3.fromRGB(72,78,83),false)
  pad.Shape=Enum.PartType.Cylinder
  pad.CFrame=CFrame.new(pad.Position)*CFrame.Angles(0,0,math.rad(90))
  pad.Material=unlocked and Enum.Material.Ground or Enum.Material.Slate
  pad:SetAttribute("OwnerUserId",player.UserId) pad:SetAttribute("SlotId",i)
  if unlocked then self.X:Prompt(pad,"Plant / replace",function(who) if who==player then self.X:Send(player,"PlantPicker",i) end end)
   local slot=p.Garden.Slots[i] local f=slot and F.Species[slot.SpeciesId] if f then local growth=f.GrowthProfile or {} local scalePerLevel=tonumber(growth.ScalePerLevel) or .025 local m=self.X.FlowerService.Build(i,f,pos+Vector3.new(0,.2,0)) m.Parent=content m:ScaleTo(1+math.min(2,((slot.Level or 1)-1)*scalePerLevel)) plot.Flowers[i]=m end
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
 if tutorialStep and tutorialStep.Id=="Plant" and i~=(tutorialStep.Slot or 3) then return false,"TUTORIAL_TARGET" end
 if tutorialStep and tutorialStep.Id=="Synergy" and (i~=(tutorialStep.Slot or 2) or id~="Tulip") then return false,"TUTORIAL_TARGET" end
 local pos=self:Position(player,i)
 if not pos or not self.X.U.Near(player,pos,C.InteractionDistance) then return false,"TOO_FAR" end
 if id~="" and (type(id)~="string" or not F.Exists(id)) then return false,"INVALID_ITEM" end
 local old=p.Garden.Slots[i]
 if old.SpeciesId==id then return true end
 if Rules.HasProgress(old) then return false,"GARDEN_PROGRESS_PROTECTED" end
 if id~="" and self.X.InventoryService:Available(p,id)<1 then return false,"NO_FREE_COPY" end
 local slot={}
 if id~="" then
  slot={SpeciesId=id,Level=1,XP=0,TotalPollination=0,Mutation=""}
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
function S:RefreshCapacity(player)
 local p=self.X:Profile(player) if not p then return false,"PROFILE_LOADING" end
 local capacity=Rules.FlowerCapacity(p)
 if Rules.HasOverflow(p.Garden.Slots,capacity) then return false,"RESPEC_GARDEN_OCCUPIED" end
 p.Garden.UnlockedSlots=capacity self:Build(player) return true
end
function S:Remove(player) local plot=self.Plots[player] if plot then self.Used[plot.Index]=nil plot.Model:Destroy() self.Plots[player]=nil end end
return S

