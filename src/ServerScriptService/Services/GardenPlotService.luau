local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local G=require(RS.Config.GardenSynergyConfig) local C=require(RS.Config.BloomConfig)
local Rules=require(RS.Shared.GardenRules)
local S={Plots={},Used={}}
function S:Init(x) self.X=x end
function S:Position(player,slot) local plot=self.Plots[player] return plot and plot.Origin+G.Position(slot) end
function S:HivePosition(player) local plot=self.Plots[player] return plot and plot.Origin+Vector3.new(0,1,19) end
function S:HivePromptText(p)
 if not p.StarterBeeGranted then return "Get Worker Bee" end
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
  self.X:Part(m,"Ground",origin-Vector3.new(0,1,0),Vector3.new(44,2,48),Color3.fromRGB(95,155,90),true)
  local hive=self.X:Part(m,"Hive",self:HivePosition(player),Vector3.new(5,5,5),Color3.fromRGB(240,185,50),true)
  self.X:Prompt(hive,self:HivePromptText(p),function(who) if who==player then self.X.HiveService:Interact(player) else self.X.SocialService:Bless(who,player) end end)
 end
 if plot.Content then plot.Content:Destroy() end plot.Flowers={} local content=Instance.new("Folder") content.Name="Flowers" content.Parent=plot.Model plot.Content=content
 for i=1,C.MaxFlowerSlots do local pos=self:Position(player,i) local unlocked=i<=p.Garden.UnlockedSlots
  local pad=self.X:Part(content,"Slot_"..i,pos,Vector3.new(5,.3,5),unlocked and Color3.fromRGB(190,145,90) or Color3.fromRGB(75,80,85),false)
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

