local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")

local ActivityConfig=require(RS.Config.ActivityConfig)
local Icons=require(RS.Config.IconsConfig)

local Q={}

local TABS={"Main","Activities","Trials","Completed"}
local COLORS={
 Panel=Color3.fromRGB(14,30,46),
 Hover=Color3.fromRGB(19,49,73),
 Selected=Color3.fromRGB(10,56,89),
 Stroke=Color3.fromRGB(16,65,104),
 Cyan=Color3.fromRGB(48,187,255),
 White=Color3.fromRGB(245,248,252),
 Text=Color3.fromRGB(198,216,234),
 Muted=Color3.fromRGB(122,154,184),
 Faint=Color3.fromRGB(74,104,132),
 Green=Color3.fromRGB(66,219,148),
 Gold=Color3.fromRGB(255,187,64),
 Danger=Color3.fromRGB(230,66,91),
 Purple=Color3.fromRGB(168,102,237),
}

local function countMap(map)
 local count=0
 for _ in pairs(map or {}) do count+=1 end
 return count
end

local function prettyKind(value)
 local text=tostring(value or "Activity")
 text=text:gsub("(%l)(%u)","%1 %2")
 return text
end

local function find(root,name,className)
 local object=root and root:FindFirstChild(name,true)
 if object and (not className or object:IsA(className)) then return object end
 return nil
end

local function strokeOf(object)
 return object and object:FindFirstChildOfClass("UIStroke")
end

local function setStroke(object,color,transparency)
 local stroke=strokeOf(object)
 if stroke then
  stroke.Color=color
  stroke.Transparency=transparency or stroke.Transparency
 end
end

local function setTabVisual(button,selected)
 button.BackgroundColor3=selected and COLORS.Selected or COLORS.Panel
 button.BackgroundTransparency=selected and .01 or .04
 setStroke(button,selected and COLORS.Cyan or COLORS.Stroke,selected and .04 or .34)
 local label=button:FindFirstChild("Label")
 if label and label:IsA("TextLabel") then
  label.TextColor3=selected and COLORS.White or COLORS.Text
 end
 local icon=button:FindFirstChild("Icon")
 if icon and icon:IsA("ImageLabel") then
  icon.ImageColor3=selected and COLORS.Cyan or COLORS.Muted
 end
end

local function bindTab(controller,button,name,state)
 if not button or not button:IsA("GuiButton") then return end
 local function selected()
  return state.Tab==name
 end
 setTabVisual(button,selected())
 button.MouseEnter:Connect(function()
  if not selected() then button.BackgroundColor3=COLORS.Hover end
 end)
 button.MouseLeave:Connect(function()
  setTabVisual(button,selected())
 end)
 button.Activated:Connect(function()
  if state.Tab==name then return end
  state.Tab=name
  controller:RenderMenu()
 end)
end

local function setText(root,name,text)
 local label=root and root:FindFirstChild(name)
 if label and label:IsA("TextLabel") then label.Text=tostring(text or "") end
 return label
end

local function setImage(root,name,image)
 local object=root and root:FindFirstChild(name)
 if object and object:IsA("ImageLabel") then object.Image=image or "" end
 return object
end

local function setAction(button,text,state,callback)
 if not button or not button:IsA("TextButton") then return end
 button.Text=text or ""
 button.AutoButtonColor=false
 local enabled=callback~=nil
 button.Active=enabled
 button.Selectable=enabled
 button.TextTransparency=enabled and 0 or .28

 local base=COLORS.Selected
 local border=COLORS.Cyan
 if state=="success" then
  base=Color3.fromRGB(12,94,62)
  border=COLORS.Green
 elseif state=="complete" then
  base=Color3.fromRGB(52,45,20)
  border=COLORS.Gold
 elseif state=="disabled" then
  base=Color3.fromRGB(25,39,53)
  border=COLORS.Faint
 elseif state=="danger" then
  base=Color3.fromRGB(82,29,41)
  border=COLORS.Danger
 end
 button.BackgroundColor3=base
 setStroke(button,border,enabled and .08 or .45)

 if enabled then
  button.MouseEnter:Connect(function()
   TweenService:Create(button,TweenInfo.new(.11),{BackgroundColor3=base:Lerp(Color3.new(1,1,1),.08)}):Play()
  end)
  button.MouseLeave:Connect(function()
   TweenService:Create(button,TweenInfo.new(.11),{BackgroundColor3=base}):Play()
  end)
  button.Activated:Connect(callback)
 end
end

local function cardTemplate(runtime)
 local components=runtime:FindFirstChild("Components")
 local template=components and components:FindFirstChild("QuestCardTemplate")
 if not template or not template:IsA("Frame") then
  error("[QuestsV2] Authored QuestCardTemplate missing")
 end
 return template
end

local function addCard(runtime,list,layoutOrder,data)
 local card=cardTemplate(runtime):Clone()
 card.Name="QuestCard_"..tostring(data.Id or layoutOrder)
 card.Visible=true
 card.LayoutOrder=layoutOrder
 card.Parent=list

 local iconBox=card:FindFirstChild("IconBox")
 if iconBox then setImage(iconBox,"Icon",data.Icon) end
 setText(card,"Title",data.Title)
 setText(card,"Description",data.Description)
 setText(card,"ProgressText",data.ProgressText)
 setText(card,"Meta",data.Meta)
 local pill=setText(card,"StatePill",data.StateText or "")
 if pill then pill.TextColor3=data.StateColor or COLORS.Cyan end

 local progress=card:FindFirstChild("ProgressTrack")
 local fill=progress and progress:FindFirstChild("Fill")
 if fill and fill:IsA("Frame") then
  fill.Size=UDim2.fromScale(math.clamp(tonumber(data.Progress) or 0,0,1),1)
  fill.BackgroundColor3=data.ProgressColor or COLORS.Cyan
 end

 local reward=card:FindFirstChild("RewardBox")
 if reward then
  setText(reward,"RewardLabel",data.RewardLabel or "REWARD")
  setText(reward,"RewardText",data.RewardText or "Progression")
  setImage(reward,"RewardIcon",data.RewardIcon or Icons.Get("System","Quests"))
 end

 local action=card:FindFirstChild("ActionButton")
 setAction(action,data.ActionText,data.ActionState,data.Action)
 setStroke(card,data.CardStroke or COLORS.Stroke,data.CardStrokeTransparency or .22)
 return card
end

local function addEmpty(runtime,list,title,description)
 local components=runtime:FindFirstChild("Components")
 local template=components and components:FindFirstChild("EmptyStateTemplate")
 if not template or not template:IsA("Frame") then return end
 local empty=template:Clone()
 empty.Name="EmptyState"
 empty.Visible=true
 empty.LayoutOrder=1
 setText(empty,"Title",title)
 setText(empty,"Description",description)
 empty.Parent=list
end

local function trialReward(trial)
 if trial.RewardText and trial.RewardText~="" then return trial.RewardText end
 return trial.Completed and "Repeat • 5 Coins" or "First clear • Workshop Points"
end

local function findTrial(items,id)
 for _,item in ipairs(items or {}) do
  if item.Id==id then return item end
 end
 return nil
end

local function trialProgress(trial,active)
 if trial.Completed and (not active or active.Id~=trial.Id) then
  return trial.Target or 1,trial.Target or 1
 end
 if active and active.Id==trial.Id then
  local counts=active.Counts or {}
  return tonumber(counts[trial.Event]) or 0,math.max(1,tonumber(trial.Target) or 1)
 end
 return 0,math.max(1,tonumber(trial.Target) or 1)
end

local function addTrialCard(controller,runtime,list,order,trial,active,viewOnly)
 local current,target=trialProgress(trial,active)
 local isActive=active and active.Id==trial.Id
 local actionText,actionState,action
 if viewOnly then
  actionText="VIEW"
  actionState="primary"
  action=function()
   controller.QuestsV2State.Tab="Trials"
   controller:RenderMenu()
  end
 elseif isActive then
  actionText="ACTIVE"
  actionState="success"
 elseif trial.CanStart then
  actionText=trial.Completed and "REPEAT" or "START"
  actionState=trial.Completed and "complete" or "primary"
  action=function() controller:Send("Trial",trial.Id) end
 elseif trial.Completed then
  actionText="CLEARED"
  actionState="complete"
 else
  actionText=(trial.Reason=="TOO_FAR" or trial.Reason=="WRONG_SECTOR") and "AT SHRINE" or "LOCKED"
  actionState="disabled"
 end

 local description
 if isActive then
  description=string.format("%s progress • %d/%d",prettyKind(trial.Event),current,target)
 else
  description=trial.StartHint or trial.ReasonText or ("Complete "..prettyKind(trial.Event).." objectives.")
 end
 local sector=tostring(trial.Sector or "World")
 local stateText=isActive and "ACTIVE" or trial.Completed and "CLEARED" or trial.Advanced and "ADVANCED" or "TRIAL"
 local stateColor=isActive and COLORS.Green or trial.Completed and COLORS.Gold or trial.Advanced and COLORS.Purple or COLORS.Cyan
 addCard(runtime,list,order,{
  Id="Trial_"..tostring(trial.Id),
  Title=trial.Name or trial.Id,
  Description=description,
  Icon=trial.Advanced and Icons.Get("System","Upgrade") or Icons.Get("System","Quests"),
  Progress=current/target,
  ProgressText=string.format("%d / %d",current,target),
  ProgressColor=isActive and COLORS.Green or trial.Completed and COLORS.Gold or COLORS.Cyan,
  Meta=string.format("%s  •  %ds",sector,tonumber(trial.Seconds) or 0),
  RewardLabel="REWARD",
  RewardText=trialReward(trial),
  RewardIcon=trial.Completed and Icons.GetCurrencyIcon("Coins") or Icons.Get("Menus","Workshop"),
  StateText=stateText,
  StateColor=stateColor,
  ActionText=actionText,
  ActionState=actionState,
  Action=action,
  CardStroke=isActive and COLORS.Green or trial.Completed and COLORS.Gold or COLORS.Stroke,
  CardStrokeTransparency=isActive and .08 or .22,
 })
end

local function activityReward(kind)
 local cfg=ActivityConfig.Types[kind] or {}
 if cfg.Boost and cfg.Boost.Label then
  return tostring(cfg.Boost.Label)
 end
 local charge=tonumber(cfg.Charge) or 0
 if charge>0 then return "+"..tostring(charge).." Bloom" end
 return "World activity"
end

local function sortedActivities(controller)
 local out={}
 for id,item in pairs(controller.Activities and controller.Activities.Items or {}) do
  table.insert(out,{Id=id,Item=item})
 end
 table.sort(out,function(a,b)
  local ae=tonumber(a.Item.Expires) or math.huge
  local be=tonumber(b.Item.Expires) or math.huge
  if ae==be then return tostring(a.Id)<tostring(b.Id) end
  return ae<be
 end)
 return out
end

local function addActivityCard(controller,runtime,list,order,id,item,viewOnly)
 local index=math.max(1,tonumber(item.Index) or 1)
 local count=math.max(1,tonumber(item.Count) or 1)
 local completed=math.clamp(index-1,0,count)
 local seconds=math.max(0,math.ceil((tonumber(item.Expires) or workspace:GetServerTimeNow())-workspace:GetServerTimeNow()))
 local tracked=controller.Activities and controller.Activities.TrackedId==id
 local actionText=viewOnly and "VIEW" or tracked and "TRACKED" or "TRACK"
 local action=function()
  if viewOnly then
   controller.QuestsV2State.Tab="Activities"
  elseif controller.Activities and controller.Activities.SetTracked then
   controller.Activities:SetTracked(id)
  end
  controller:RenderMenu()
 end
 addCard(runtime,list,order,{
  Id="Activity_"..tostring(id),
  Title=prettyKind(item.Kind),
  Description="Reach the highlighted world checkpoints before the activity expires.",
  Icon=Icons.Get("System","Garden"),
  Progress=completed/count,
  ProgressText=string.format("%d / %d",completed,count),
  ProgressColor=tracked and COLORS.Green or COLORS.Cyan,
  Meta=string.format("%ds left%s",seconds,item.Sector and ("  •  "..tostring(item.Sector)) or ""),
  RewardLabel="ACTIVITY",
  RewardText=activityReward(item.Kind),
  RewardIcon=Icons.Get("System","Flower"),
  StateText=tracked and "TRACKED" or "WORLD",
  StateColor=tracked and COLORS.Green or COLORS.Cyan,
  ActionText=actionText,
  ActionState=tracked and "success" or "primary",
  Action=action,
  CardStroke=tracked and COLORS.Green or COLORS.Stroke,
  CardStrokeTransparency=tracked and .08 or .22,
 })
end

local function updateSummary(controller,runtime,profile,uiState)
 local summary=runtime:FindFirstChild("SummaryBar",true)
 if not summary then return end
 local journey=summary:FindFirstChild("SummaryJourney")
 local trials=summary:FindFirstChild("SummaryTrials")
 local activities=summary:FindFirstChild("SummaryActivities")
 local journeyStep=math.max(1,tonumber(profile.Quests and profile.Quests.JourneyStep) or 1)
 local journeyCount=math.max(1,controller:JourneyCount())
 if journey then setText(journey,"Value",string.format("%d / %d",math.min(journeyStep,journeyCount),journeyCount)) end
 local completed=countMap(profile.Quests and profile.Quests.Trials)
 local total=#((uiState.Trials and uiState.Trials.Items) or {})
 if trials then setText(trials,"Value",string.format("%d / %d",completed,total)) end
 local activeCount=countMap(controller.Activities and controller.Activities.Items)
 if activities then setText(activities,"Value",tostring(activeCount)) end
end

local function renderMain(controller,runtime,list,profile,uiState)
 local order=1
 local step=math.max(1,tonumber(profile.Quests and profile.Quests.JourneyStep) or 1)
 local total=math.max(1,controller:JourneyCount())
 local complete=math.clamp(step-1,0,total)
 local finished=step>total
 addCard(runtime,list,order,{
  Id="Journey",
  Title=finished and "Journey Complete" or ("Journey Step "..tostring(step)),
  Description=finished and "All current alpha journey steps are complete." or controller:JourneyText(step),
  Icon=Icons.Get("System","Quests"),
  Progress=finished and 1 or complete/total,
  ProgressText=string.format("%d / %d",math.min(complete,total),total),
  ProgressColor=finished and COLORS.Green or COLORS.Cyan,
  Meta="Core progression",
  RewardLabel="PROGRESSION",
  RewardText=finished and "Alpha path complete" or "Next milestone",
  RewardIcon=Icons.Get("System","Upgrade"),
  StateText=finished and "COMPLETE" or "MAIN",
  StateColor=finished and COLORS.Green or COLORS.Cyan,
  ActionText="SHOW HUD",
  ActionState="primary",
  Action=function() controller:Close() end,
  CardStroke=finished and COLORS.Green or COLORS.Stroke,
 })
 order+=1

 local trials=uiState.Trials or {}
 if trials.Active then
  local item=findTrial(trials.Items,trials.Active.Id)
  if item then
   addTrialCard(controller,runtime,list,order,item,trials.Active,true)
   order+=1
  end
 end
 local activities=sortedActivities(controller)
 if activities[1] then
  addActivityCard(controller,runtime,list,order,activities[1].Id,activities[1].Item,true)
 end
end

function Q.Render(controller,profile,uiState)
 local prototype=controller.Panel:FindFirstChild("QuestsPrototype")
 if not prototype or not prototype:IsA("Frame") then
  controller:Label(controller.Content,"QuestsPrototype missing",32)
  return
 end
 controller.QuestsV2State=controller.QuestsV2State or {Tab="Main"}
 local state=controller.QuestsV2State
 if not table.find(TABS,state.Tab) then state.Tab="Main" end

 local runtime=prototype:Clone()
 runtime.Name="QuestsV2Runtime"
 runtime.Visible=true
 runtime.Position=UDim2.fromScale(0,0)
 runtime.Size=UDim2.fromScale(1,1)
 runtime.LayoutOrder=1
 runtime.Parent=controller.Content

 local shell=runtime:FindFirstChild("QuestsShell")
 local sidebar=shell and shell:FindFirstChild("Sidebar")
 local list=shell and shell:FindFirstChild("QuestList")
 if not shell or not sidebar or not list or not list:IsA("ScrollingFrame") then
  error("[QuestsV2] Authored QuestsPrototype structure is incomplete")
 end

 for _,tab in ipairs(TABS) do
  bindTab(controller,sidebar:FindFirstChild("Tab_"..tab),tab,state)
 end
 updateSummary(controller,runtime,profile,uiState)

 for _,child in ipairs(list:GetChildren()) do
  if child:IsA("GuiObject") then child:Destroy() end
 end
 list.CanvasPosition=Vector2.new()

 if state.Tab=="Main" then
  renderMain(controller,runtime,list,profile,uiState)
 elseif state.Tab=="Activities" then
  local activities=sortedActivities(controller)
  if #activities==0 then
   addEmpty(runtime,list,"No active activities","World activities appear here while they are active.")
  else
   for i,entry in ipairs(activities) do
    addActivityCard(controller,runtime,list,i,entry.Id,entry.Item,false)
   end
  end
 elseif state.Tab=="Trials" then
  local trials=uiState.Trials or {}
  local items=trials.Items or {}
  if #items==0 then
   addEmpty(runtime,list,"Trials are unavailable","Continue progression to unlock build trials.")
  else
   for i,item in ipairs(items) do
    addTrialCard(controller,runtime,list,i,item,trials.Active,false)
   end
  end
 elseif state.Tab=="Completed" then
  local trials=uiState.Trials or {}
  local order=0
  for _,item in ipairs(trials.Items or {}) do
   if item.Completed then
    order+=1
    addTrialCard(controller,runtime,list,order,item,trials.Active,false)
   end
  end
  if order==0 then
   addEmpty(runtime,list,"No completed trials","Your cleared trials will appear here.")
  end
 end
end

return Q
