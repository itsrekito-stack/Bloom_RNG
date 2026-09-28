local RS=game:GetService("ReplicatedStorage")

local Icons=require(RS.Config.IconsConfig)
local Theme=require(RS.Config.UIThemeConfig)
local NumberFormatter=require(RS.Shared.NumberFormatter)

local C=Theme.Colors
local S={}

local function find(root,name,className)
 local object=root and root:FindFirstChild(name,true)
 if object and (not className or object:IsA(className)) then return object end
 return nil
end

local function compact(value)
 local ok,result=pcall(function() return NumberFormatter.Compact(tonumber(value) or 0) end)
 return ok and tostring(result) or tostring(math.floor(tonumber(value) or 0))
end

local function setText(root,name,value)
 local label=find(root,name,"TextLabel")
 if label then label.Text=tostring(value or "") end
 return label
end

local function stateStyle(node,state)
 local stroke=node:FindFirstChildOfClass("UIStroke")
 if state=="CURRENT" then
  node.BackgroundColor3=C.PanelHover
  if stroke then stroke.Color=C.Gold stroke.Transparency=.04 stroke.Thickness=2 end
 elseif state=="NEXT" then
  node.BackgroundColor3=C.Panel
  if stroke then stroke.Color=C.Blue stroke.Transparency=.08 stroke.Thickness=1.7 end
 elseif state=="OWNED" then
  node.BackgroundColor3=C.Panel
  if stroke then stroke.Color=C.Green stroke.Transparency=.18 stroke.Thickness=1.4 end
 else
  node.BackgroundColor3=C.Panel
  if stroke then stroke.Color=C.BorderSoft stroke.Transparency=.5 stroke.Thickness=1 end
 end
end

function S.Render(controller,profile,uiState)
 local template=controller.StateKits and controller.StateKits:FindFirstChild("HiveKit")
 if not template or not template:IsA("Frame") then
  controller:Label(controller.Content,"HiveKit missing",32)
  return
 end

 local runtime=template:Clone()
 runtime.Name="HiveRuntime"
 runtime.Visible=true
 runtime.Position=UDim2.fromScale(0,0)
 runtime.Size=UDim2.fromScale(1,1)
 runtime.LayoutOrder=1
 runtime.Parent=controller.Content

 local hive=uiState.Hive or {}
 local level=math.max(1,math.floor(tonumber(hive.Level) or tonumber(profile.Hive and profile.Hive.Level) or 1))
 local nextLevel=math.max(level+1,math.floor(tonumber(hive.NextLevel) or level+1))
 setText(runtime,"LevelText","LEVEL "..tostring(level))
 setText(runtime,"NextLevel","NEXT  •  LEVEL "..tostring(nextLevel))
 setText(runtime,"ProgressText",compact(hive.Honey).." / "..compact(hive.HoneyCost).." Honey  •  "..compact(hive.Coins).." / "..compact(hive.CoinCost).." Coins")
 setText(runtime,"QuestText",hive.QuestReady and "Hive quest complete" or tostring(hive.QuestText or "Complete the next Hive quest"))
 local currentPoints=math.max(0,math.floor(tonumber(hive.WorkshopPoints) or 0))
 local points=math.max(0,math.floor(tonumber(hive.NextWorkshopPoints) or 0))
 local nextReward=points>0 and ("NEXT  +"..tostring(points)) or "NEXT  —"
 setText(runtime,"RewardText","WORKSHOP POINTS  •  "..tostring(currentPoints).."  •  "..nextReward)

 local icon=find(runtime,"HiveIcon","ImageLabel")
 if icon then icon.Image=Icons.Get("System","Hive") end

 local track=find(runtime,"ProgressTrack","Frame")
 local fill=track and track:FindFirstChild("Fill")
 if fill and fill:IsA("Frame") then
  fill.Size=UDim2.fromScale(math.clamp(tonumber(hive.Progress) or 0,0,1),1)
 end

 local upgrade=find(runtime,"UpgradeButton","TextButton")
 if upgrade then
  local enabled=hive.CanUpgrade==true
  upgrade.Active=enabled
  upgrade.Selectable=enabled
  upgrade.Text=enabled and ("UPGRADE TO LEVEL "..tostring(nextLevel)) or tostring(hive.ReasonText or "UPGRADE LOCKED")
  upgrade.TextTransparency=enabled and 0 or .35
  upgrade.BackgroundTransparency=enabled and .02 or .16
  local stroke=upgrade:FindFirstChildOfClass("UIStroke")
  if stroke then
   stroke.Color=enabled and C.Gold or C.BorderSoft
   stroke.Transparency=enabled and .05 or .5
  end
  upgrade.Activated:Connect(function()
   if upgrade.Active then controller:Send("HiveUpgrade") end
  end)
 end

 local list=find(runtime,"RoadList","ScrollingFrame")
 local nodeTemplate=list and list:FindFirstChild("RoadNodeTemplate")
 if not list or not nodeTemplate then error("[HiveMenu] Authored Hive road is incomplete") end
 for _,child in ipairs(list:GetChildren()) do
  if child:GetAttribute("HiveRoadRuntime") then child:Destroy() end
 end

 for order,item in ipairs(hive.Road or {}) do
  local node=nodeTemplate:Clone()
  node.Name="HiveRoad_"..tostring(item.Level or order)
  node.Visible=true
  node.LayoutOrder=order
  node:SetAttribute("HiveRoadRuntime",true)
  setText(node,"Level","LV. "..tostring(item.Level or order))
  setText(node,"State",tostring(item.State or "FUTURE"))
  if (tonumber(item.Level) or 1)<=1 then
   setText(node,"Cost","START")
  else
   setText(node,"Cost",compact(item.HoneyCost).." Honey  •  "..compact(item.CoinCost).." Coins")
  end
  local reward=math.max(0,math.floor(tonumber(item.WorkshopPoints) or 0))
  setText(node,"Reward",reward>0 and ("+"..tostring(reward).." Workshop Point"..(reward==1 and "" or "s")) or "Hive Level")
  stateStyle(node,item.State)
  node.Parent=list
 end
 list.CanvasPosition=Vector2.new(0,math.max(0,(level-3)*62))
end

return S
