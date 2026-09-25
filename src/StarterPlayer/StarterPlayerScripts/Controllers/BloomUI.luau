local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local CAS=game:GetService("ContextActionService")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")

local Icons=require(RS.Config.IconsConfig)
local F=require(RS.Config.FlowersConfig)
local B=require(RS.Config.BeesConfig)
local W=require(RS.Config.WorkshopConfig)
local T=require(RS.Config.TutorialConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local R=require(RS.Config.RarityConfig)
local L=require(RS.Config.LocationsConfig)
local Theme=require(RS.Config.UIThemeConfig)
local RollAudio=require(RS.Config.RollAudioConfig)
local NumberFormatter=require(RS.Shared.NumberFormatter)
local InventoryV2=require(script.Parent.InventoryV2Controller)

local C=Theme.Colors
local CLIENT_BUILD="roll-correlation-v6-2026-09-25"
local WORKSHOP_ZOOM_ACTION="BloomWorkshopZoomCapture"
local UI={Player=Players.LocalPlayer,Pending=false,Auto=false,NextRoll=0,Menu=nil,State=nil,Connections={},RouletteRunning=false,RouletteLanding=false,RouletteGeneration=0,RollSession=0,RollRequestSequence=0,RollRequestSessions={}}

local MENU_RENDERERS={SeedSatchel="InventoryV2"}
local MENU_NAMES={
 SeedSatchel="Inventory",
 Workshop="Workshop",
 FieldGuide="Field Guide",
 Map="Map",
 Trials="Trials",
 Settings="Settings",
 Plant="Planting",
 Season="Season Turn",
 Replay="Tutorial Replay",
 Cards="Season Cards",
}
local MENU_HINTS={
 SeedSatchel="Flowers, seeds, bees, resources, and keepsakes",
 Workshop="Permanent upgrades and progression branches",
 FieldGuide="Collection, odds, and discovered synergies",
 Map="Sectors, discoveries, and travel",
 Trials="Short build trials",
 Settings="Effects, sound, and automation",
 Plant="Choose a seed for an empty flower bed",
 Season="Review the changes before confirming",
 Replay="Replay the tutorial without resetting progress",
 Cards="Choose an effect for the new Season",
}
local SETTINGS_NAMES={
 ReducedEffects="Reduced effects",
 ShowOtherPollinators="Show other players' bees",
 HideOtherPlayersTokens="Hide other players' activities",
 RareFeed="Show rare discoveries",
 AutoDissolve="Auto-dissolve duplicates",
}
local JOURNEY={
 "Get your first bee","Collect a Pollen Spark","Honey delivery","Make a roll","Plant a flower","Fill the Bloom Meter","Make a Bloom Roll","Reach Hive Level 2","Visit the Workshop","Buy a Workshop node","Create a synergy","Unlock the second bee slot","Activate a Bee Trait","Visit Sunny Orchard","Complete Solar Bloom","Discover 6 flowers","Unlock Crystal Gate","Complete a trial","Visit Crystal Greenhouse","Prepare a Season Turn",
}

local function make(class,parent,props)
 local x=Instance.new(class)
 for k,v in pairs(props or {}) do x[k]=v end
 x.Parent=parent
 return x
end

local function corner(x,r)
 return make("UICorner",x,{CornerRadius=UDim.new(0,r or Theme.Radius.Medium)})
end

local function outline(x,color,thickness,transparency)
 return make("UIStroke",x,{Color=color or C.BorderDark,Thickness=thickness or Theme.Stroke.Control,Transparency=transparency or Theme.Stroke.DarkTransparency,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end

local function pad(x,l,r,t,b)
 return make("UIPadding",x,{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or l or 0),PaddingTop=UDim.new(0,t or l or 0),PaddingBottom=UDim.new(0,b or t or l or 0)})
end

local function hover(button,base,over)
 button.AutoButtonColor=false
 button.MouseEnter:Connect(function()
  if not button.Parent then return end
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=over}):Play()
 end)
 button.MouseLeave:Connect(function()
  if not button.Parent then return end
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=base}):Play()
 end)
end

local function compact(v)
 return NumberFormatter.Compact(tonumber(v) or 0)
end

local WORKSHOP_FEATURE_TEXT={
 PityDetails="Shows pity and the guaranteed new discovery",
 RepeatPlant="Replant the last seed",
 PatternHints="Flower pattern hints",
 AutoDissolve="Auto-dissolve duplicates",
 DissolveFilters="Auto-dissolve filters by rarity",
 SeedMutation="Unlocks seed mutations",
 EventRadar="Shows world events",
 LaunchPads="Unlocks fast travel",
 KeepSeasonCard="Keeps a card between Seasons",
 MemoryMutation="Keeps a mutation in memory",
 AdvancedTrials="Unlocks advanced trials",
 ThirdMemory="Unlocks an additional memory slot",
}

local function workshopEffectText(rules)
 if not rules or next(rules)==nil then return "Central node of the upgrade tree" end
 local out={}
 for key,value in pairs(rules) do
  local text
  if key=="Feature" then text=WORKSHOP_FEATURE_TEXT[tostring(value)] or tostring(value)
  elseif key=="RollCooldown" then text="Roll cooldown → "..tostring(value).."s"
  elseif key=="Reserve" then text="Bloom reserve +"..tostring(value)
  elseif key=="RevealScale" then text="Reveal time ×"..tostring(value)
  elseif key=="FlowerSlots" then text="Flower slots +"..tostring(value)
  elseif key=="Adjacency" then text="Adjacency radius +"..tostring(value)
  elseif key=="SynergyXP" then text="Synergy XP ×"..tostring(value)
  elseif key=="BeeSlots" then text="Bee slots +"..tostring(value)
  elseif key=="TokenChance" then text="Ability token chance +"..math.floor((tonumber(value) or 0)*100+.5).."%"
  elseif key=="BeeXP" then text="Bee XP ×"..tostring(value)
  elseif key=="TraitCooldown" then text="Trait cooldown ×"..tostring(value)
  elseif key=="AbilityYield" then text="Ability rewards ×"..tostring(value)
  elseif key=="DustYield" then text="Petal Dust ×"..tostring(value)
  elseif key=="MilestoneCoins" then text="Milestone Coins +"..tostring(value)
  elseif key=="StudyDiscount" then text="Mastery cost −"..math.floor((tonumber(value) or 0)*100+.5).."%"
  elseif key=="CoinYield" then text="Coins ×"..tostring(value)
  elseif key=="ManualCharge" then text="Bloom charge ×"..tostring(value)
  elseif key=="NewWeight" then text="New discovery weight ×"..tostring(value)
  elseif key=="MutationChance" then text="Mutation chance +"..math.floor((tonumber(value) or 0)*100+.5).."%"
  elseif key=="SignatureWeight" then text="Signature weight ×"..tostring(value)
  elseif key=="RouteCharge" then text="Route charge ×"..tostring(value)
  elseif key=="CrystalSeconds" then text="Crystal interaction "..tostring(value).."s"
  elseif key=="WildInterval" then text="Wild interval ×"..tostring(value)
  elseif key=="EclipseWeight" then text="Eclipse weight ×"..tostring(value)
  elseif key=="MemoryMastery" then text="Memory Mastery +"..tostring(value)
  elseif key=="SeasonNectar" then text="Ancient Nectar per Season +"..tostring(value)
  else text=key.." "..tostring(value) end
  table.insert(out,text)
 end
 table.sort(out)
 return table.concat(out," • ")
end

local function workshopCostText(node)
 if not node or node.Id=="CORE" then return "CORE" end
 local parts={tostring(node.Cost or 0).." POINT"}
 if (node.Coins or 0)>0 then table.insert(parts,compact(node.Coins).." COINS") end
 if (node.Dust or 0)>0 then table.insert(parts,compact(node.Dust).." DUST") end
 if (node.Nectar or 0)>0 then table.insert(parts,compact(node.Nectar).." NECTAR") end
 return table.concat(parts,"  •  ")
end

function UI:Text(parent,text,size,props)
 props=props or {}
 local label=make("TextLabel",parent,{
  Size=size or UDim2.new(1,0,0,24),
  Position=props.Position or UDim2.new(),
  AnchorPoint=props.AnchorPoint or Vector2.new(),
  BackgroundTransparency=props.BackgroundTransparency==nil and 1 or props.BackgroundTransparency,
  BackgroundColor3=props.BackgroundColor3 or C.Panel,
  BorderSizePixel=0,
  Text=text or "",
  TextColor3=props.TextColor3 or C.Text,
  TextSize=props.TextSize or 14,
  TextWrapped=props.TextWrapped~=false,
  TextXAlignment=props.TextXAlignment or Enum.TextXAlignment.Left,
  TextYAlignment=props.TextYAlignment or Enum.TextYAlignment.Center,
  Font=props.Font or Enum.Font.Gotham,
  ZIndex=props.ZIndex or ((parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1),
  Visible=props.Visible==nil and true or props.Visible,
 })
 if props.Name then label.Name=props.Name end
 if props.AutomaticSize then label.AutomaticSize=props.AutomaticSize end
 return label
end

function UI:Label(parent,text,height)
 local template=self.Templates and self.Templates:FindFirstChild("LabelTemplate")
 local label
 if template and template:IsA("TextLabel") then
  label=template:Clone()
  label.Name="Label"
  label.Visible=true
  label.Parent=parent
  label.Text=text or ""
  label.Size=UDim2.new(1,0,0,height or 30)
  label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 else
  label=self:Text(parent,text,UDim2.new(1,0,0,height or 30),{BackgroundTransparency=.32,BackgroundColor3=C.PanelSoft,TextColor3=C.Muted,TextSize=11,TextWrapped=true})
  corner(label,Theme.Radius.Medium)
  outline(label,C.BorderSoft,1,.46)
  pad(label,10,10,4,4)
 end
 return label
end

function UI:Section(parent,text)
 local template=self.Templates and self.Templates:FindFirstChild("SectionTemplate")
 local label
 if template and template:IsA("TextLabel") then
  label=template:Clone()
  label.Name="Section"
  label.Visible=true
  label.Parent=parent
  label.Text=string.upper(text or "")
  label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 else
  label=self:Text(parent,string.upper(text or ""),UDim2.new(1,0,0,18),{TextColor3=C.Blue,TextSize=10,Font=Enum.Font.GothamBold})
  pad(label,2,2,0,0)
 end
 return label
end

function UI:Button(parent,text,fn,icon)
 local template=self.Templates and self.Templates:FindFirstChild("ButtonTemplate")
 local b
 if template and template:IsA("TextButton") then
  b=template:Clone()
  b.Name="Button"
  b.Visible=true
  b.Parent=parent
  b.Text=text or ""
  b.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
  local img=b:FindFirstChild("Icon")
  local padding=b:FindFirstChild("Padding") or b:FindFirstChildOfClass("UIPadding")
  if img and img:IsA("ImageLabel") then
   img.Visible=icon~=nil and icon~=""
   img.Image=icon or ""
   img.ZIndex=b.ZIndex+1
  end
  b.TextXAlignment=(icon and icon~="") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
  if padding then padding.PaddingLeft=UDim.new(0,(icon and icon~="") and 36 or 10) end
 else
  local base=C.PanelRaised
  b=make("TextButton",parent,{Size=UDim2.new(1,0,0,34),BackgroundColor3=base,BorderSizePixel=0,Text=text,TextColor3=C.Text,TextSize=12,TextWrapped=true,TextXAlignment=icon and icon~="" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,Font=Enum.Font.GothamMedium,ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1})
  corner(b,Theme.Radius.Medium)
  outline(b,C.BorderDark,Theme.Stroke.Control,.12)
  if icon and icon~="" then make("ImageLabel",b,{Name="Icon",Size=UDim2.fromOffset(22,22),Position=UDim2.fromOffset(8,6),BackgroundTransparency=1,Image=icon,ScaleType=Enum.ScaleType.Fit,ZIndex=b.ZIndex+1}) pad(b,36,10,0,0) else pad(b,10,10,0,0) end
 end
 hover(b,C.PanelRaised,C.PanelHover)
 b.Activated:Connect(fn)
 return b
end

function UI:Send(action,a,b,c)
 self.Request:FireServer(action,a,b,c)
end

local LEGACY_ROULETTE_NAMES={
 Roulette=true,RouletteGui=true,RouletteGUI=true,RouletteFrame=true,RoulettePanel=true,RouletteContainer=true,
 Reel=true,ReelFrame=true,SpinFrame=true,SpinGui=true,OldRoulette=true,OldRollUI=true,
 TutorialRollButton=true,AutoRollButton=true,RollGui=true,RollGUI=true,RollUI=true,RollFrame=true,RollPanel=true,RollContainer=true,
}

local function looksLikeLegacyRoulette(instance)
 local name=instance.Name
 if LEGACY_ROULETTE_NAMES[name] then return true end
 local lower=string.lower(name)
 return string.find(lower,"roulette",1,true)~=nil
  or string.find(lower,"reel",1,true)~=nil
  or string.find(lower,"oldroll",1,true)~=nil
end

function UI:PurgeLegacyRouletteGui()
 local playerGui=self.Player:FindFirstChild("PlayerGui")
 if not playerGui then return end

 -- Delete any retired roll/roulette ScreenGui left in an old Studio place.
 for _,gui in ipairs(playerGui:GetChildren()) do
  if gui:IsA("ScreenGui") and gui~=self.Gui then
   local legacy=looksLikeLegacyRoulette(gui)
   if not legacy then
    for _,item in ipairs(gui:GetDescendants()) do
     if looksLikeLegacyRoulette(item) then legacy=true break end
    end
   end
   if legacy then
    warn("[BloomUI] Removing legacy roulette ScreenGui:",gui:GetFullName())
    gui:Destroy()
   end
  end
 end

 -- Inside authoritative BloomUI only SafeRoot/VerticalRoulette is allowed.
 local canonical=self.SafeRoot and self.SafeRoot:FindFirstChild("VerticalRoulette")
 if self.Gui and canonical then
  local trash={}
  for _,item in ipairs(self.Gui:GetDescendants()) do
   if item~=canonical and not item:IsDescendantOf(canonical) and looksLikeLegacyRoulette(item) then
    -- Keep the current Roll button/HUD; only retired roulette/reel structures are removed.
    if item~=self.Roll and item~=self.RollHUD and item.Name~="RollButton" and item.Name~="RollHUD" then
     table.insert(trash,item)
    end
   end
  end
  table.sort(trash,function(a,b)
   local function depth(x)
    local d=0
    while x and x~=self.Gui do d+=1 x=x.Parent end
    return d
   end
   return depth(a)<depth(b)
  end)
  for _,item in ipairs(trash) do
   if item.Parent then
    warn("[BloomUI] Removing legacy roulette object:",item:GetFullName())
    item:Destroy()
   end
  end
 end
end

function UI:IsWorkshopExclusive()
 return self.WorkshopFocus==true and self.Menu=="Workshop"
end

function UI:ApplyWorkshopFocusVisibility()
 if not self:IsWorkshopExclusive() then return end
 for _,gui in ipairs({
  self.ObjectiveCard,self.CurrencyHUD,self.Dock,self.RollHUD,self.Roll,self.RouletteViewport,
  self.Guide,self.ToastRoot,self.Reveal,
 }) do
  if gui and gui:IsA("GuiObject") then gui.Visible=false end
 end
end

function UI:SetWorkshopFocus(active)
 self.WorkshopFocus=active==true
 if self.WorkshopFocus then
  self.Auto=false
  self:StopRouletteAnimation()
  self.ToastUntil=nil
  self:ApplyWorkshopFocusVisibility()
 else
  if self.State then self:Render() end
 end
end

function UI:Toast(text)
 if self:IsWorkshopExclusive() then return end
 self.ToastLabel.Text=tostring(text or "")
 self.ToastRoot.Visible=true
 self.ToastUntil=os.clock()+4
 if self.ToastScale then
  self.ToastScale.Scale=.94
  TweenService:Create(self.ToastScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
end

function UI:DisconnectWorkshopPan()
 CAS:UnbindAction(WORKSHOP_ZOOM_ACTION)
 if self.WorkshopPanConnections then
  for _,connection in ipairs(self.WorkshopPanConnections) do
   connection:Disconnect()
  end
 end
 self.WorkshopPanConnections=nil
 self.WorkshopPanDragging=false
end

function UI:ClampWorkshopCanvasPosition(canvas,position)
 if not canvas or not canvas:IsA("ScrollingFrame") then return Vector2.zero end
 local maxX=math.max(0,canvas.AbsoluteCanvasSize.X-canvas.AbsoluteSize.X)
 local maxY=math.max(0,canvas.AbsoluteCanvasSize.Y-canvas.AbsoluteSize.Y)
 return Vector2.new(math.clamp(position.X,0,maxX),math.clamp(position.Y,0,maxY))
end

function UI:BindWorkshopPan(canvas,nodes)
 self:DisconnectWorkshopPan()
 if not canvas:IsA("ScrollingFrame") then return end

 canvas.Active=true
 canvas.ScrollingEnabled=false
 canvas.ScrollBarThickness=0
 canvas.ElasticBehavior=Enum.ElasticBehavior.Never
 canvas.Selectable=false

 local panMap=canvas:FindFirstChild("PanMap")
 local zoomScale=nil
 local baseCanvas=Vector2.new(
  math.max(1,canvas.CanvasSize.X.Offset),
  math.max(1,canvas.CanvasSize.Y.Offset)
 )
 if panMap and panMap:IsA("GuiObject") then
  zoomScale=panMap:FindFirstChild("WorkshopZoomScale")
  if not zoomScale then
   zoomScale=Instance.new("UIScale")
   zoomScale.Name="WorkshopZoomScale"
   zoomScale.Parent=panMap
  end
 end

 local zoomMin=.5
 local zoomMax=1.6
 local zoomStep=.1
 local zoom=math.clamp(tonumber(self.WorkshopZoom) or 1,zoomMin,zoomMax)
 self.WorkshopZoom=zoom

 local function applyZoom(value)
  zoom=math.clamp(value,zoomMin,zoomMax)
  self.WorkshopZoom=zoom
  if zoomScale then zoomScale.Scale=zoom end
  if self.WorkshopZoomLabel and self.WorkshopZoomLabel.Parent then
   self.WorkshopZoomLabel.Text=tostring(math.floor(zoom*100+.5)).."%"
  end
  canvas.CanvasSize=UDim2.fromOffset(
   math.max(1,math.floor(baseCanvas.X*zoom+.5)),
   math.max(1,math.floor(baseCanvas.Y*zoom+.5))
  )
 end
 applyZoom(zoom)

 local connections={}
 self.WorkshopPanConnections=connections

 local dragging=false
 local moved=false
 local startPointer=Vector2.zero
 local startCanvas=Vector2.zero
 local dragThreshold=4

 local function pointerPosition(input)
  return Vector2.new(input.Position.X,input.Position.Y)
 end

 local function insideCanvas(position)
  local topLeft=canvas.AbsolutePosition
  local size=canvas.AbsoluteSize
  return position.X>=topLeft.X and position.X<=topLeft.X+size.X and position.Y>=topLeft.Y and position.Y<=topLeft.Y+size.Y
 end

 local function overNodeButton(position)
  for _,node in ipairs(nodes:GetChildren()) do
   if node:IsA("GuiButton") and node.Visible then
    local topLeft=node.AbsolutePosition
    local size=node.AbsoluteSize
    if position.X>=topLeft.X and position.X<=topLeft.X+size.X and position.Y>=topLeft.Y and position.Y<=topLeft.Y+size.Y then
     return true
    end
   end
  end
  return false
 end

 local function finishDrag()
  if not dragging then return end
  dragging=false
  moved=false
  self.WorkshopPanDragging=false
  if canvas.Parent then
   local position=self:ClampWorkshopCanvasPosition(canvas,canvas.CanvasPosition)
   canvas.CanvasPosition=position
   self.WorkshopCanvasPosition=position
  end
 end

 table.insert(connections,UIS.InputBegan:Connect(function(input)
  if self.Menu~="Workshop" or not canvas.Parent or not canvas.Visible then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
  local position=pointerPosition(input)
  if not insideCanvas(position) or overNodeButton(position) then return end
  dragging=true
  moved=false
  self.WorkshopPanDragging=true
  startPointer=position
  startCanvas=canvas.CanvasPosition
 end))

 CAS:BindActionAtPriority(
  WORKSHOP_ZOOM_ACTION,
  function(_,inputState,input)
   if self.Menu~="Workshop" or not canvas.Parent then
    return Enum.ContextActionResult.Pass
   end

   if inputState==Enum.UserInputState.Change and input.UserInputType==Enum.UserInputType.MouseWheel then
    local mouse=UIS:GetMouseLocation()
    if insideCanvas(mouse) then
     local wheel=input.Position.Z
     if wheel~=0 then
      local oldZoom=zoom
      local newZoom=math.clamp(oldZoom+wheel*zoomStep,zoomMin,zoomMax)
      if math.abs(newZoom-oldZoom)>=.001 then
       local localMouse=mouse-canvas.AbsolutePosition
       local worldPoint=(canvas.CanvasPosition+localMouse)/oldZoom
       applyZoom(newZoom)

       local target=worldPoint*newZoom-localMouse
       target=self:ClampWorkshopCanvasPosition(canvas,target)
       canvas.CanvasPosition=target
       self.WorkshopCanvasPosition=target
      end
     end
    end
   end

   -- While Workshop is open, the wheel belongs exclusively to the tree.
   -- Sinking it here prevents PlayerModule/CameraModule from zooming the world.
   return Enum.ContextActionResult.Sink
  end,
  false,
  Enum.ContextActionPriority.High.Value+100,
  Enum.UserInputType.MouseWheel
 )

 table.insert(connections,UIS.InputChanged:Connect(function(input)
  if not canvas.Parent or self.Menu~="Workshop" then return end
  if input.UserInputType~=Enum.UserInputType.MouseMovement or not dragging then return end

  local delta=pointerPosition(input)-startPointer
  if not moved and delta.Magnitude<dragThreshold then return end
  moved=true
  local position=self:ClampWorkshopCanvasPosition(canvas,startCanvas-delta)
  canvas.CanvasPosition=position
  self.WorkshopCanvasPosition=position
 end))

 table.insert(connections,UIS.InputEnded:Connect(function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 then finishDrag() end
 end))

 table.insert(connections,UIS.WindowFocusReleased:Connect(finishDrag))

 table.insert(connections,canvas:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
  if not dragging and canvas.Parent then
   self.WorkshopCanvasPosition=self:ClampWorkshopCanvasPosition(canvas,canvas.CanvasPosition)
  end
 end))
end

function UI:ClearPanel()
 self:DisconnectWorkshopPan()
 self.WorkshopRuntime=nil
 for _,x in ipairs(self.Content:GetChildren()) do
  if not x:IsA("UIListLayout") and not x:IsA("UIPadding") then x:Destroy() end
 end
end

function UI:SetPanelVisible(visible)
 self.Panel.Visible=visible
 self.ModalShade.Visible=visible
 if visible then
  self.PanelScale.Scale=.96
  TweenService:Create(self.PanelScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
end

function UI:Close()
 self:DisconnectWorkshopPan()
 self.ReplayIndex=nil
 local wasWorkshop=self.Menu=="Workshop"
 if wasWorkshop then self.WorkshopRuntime=nil end
 if self.Menu=="Season" then self:Send("SeasonCancel") end
 self.Menu=nil
 self.MenuRenderer=nil
 self:SetPanelVisible(false)
 if wasWorkshop then self:SetWorkshopFocus(false) end
 self:Send("Menu",false)
end

function UI:Open(name,arg)
 if self:IsWorkshopExclusive() and name~="Workshop" then return end
 if self.Menu==name and arg==nil then self:Close() return end
 if not self.State then return end
 if name~="Settings" and name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" and not self.State.Profile.Tutorial.FeatureUnlocks[name] then return end
 self.Menu=name
 self.MenuRenderer=MENU_RENDERERS[name] or name
 self.MenuArg=arg
 self:SetPanelVisible(true)
 if name=="Workshop" then self:SetWorkshopFocus(true) end
 if name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" then self:Send("Menu",name) end
 self:RenderMenu()
 self:ApplyWorkshopFocusVisibility()
end

function UI:RenderMenu()
 if not self.Menu or not self.State then return end
 local p=self.State.Profile
 local ui=self.State.UI or {}
 local name=self.Menu
 local renderer=self.MenuRenderer or MENU_RENDERERS[name] or name
 local workshop=renderer=="Workshop"
 local reuseWorkshop=workshop and self.WorkshopRuntime and self.WorkshopRuntime.Parent==self.Content
 if not reuseWorkshop then self:ClearPanel() end
 self.PanelTitle.Text=MENU_NAMES[name] or name
 self.PanelSubtitle.Text=MENU_HINTS[name] or ""

 if self.PanelHeader then
  self.PanelHeader.Size=workshop and UDim2.new(1,0,0,0) or UDim2.new(1,0,0,54)
  self.PanelHeader.BackgroundTransparency=workshop and 1 or .05
  self.PanelHeader.ZIndex=workshop and 118 or 51
 end
 self.PanelTitle.Visible=not workshop
 self.PanelSubtitle.Visible=not workshop
 if self.PanelHeaderIcon then
  self.PanelHeaderIcon.Visible=not workshop
  if not workshop then
   local headerImage=Icons.Get("Menus",name)
   if headerImage=="" then
    if name=="Plant" then headerImage=Icons.Get("System","Garden")
    elseif name=="Season" or name=="Cards" then headerImage=Icons.Get("System","Flower")
    elseif name=="Replay" then headerImage=Icons.Get("System","Tutorial")
    else headerImage=Icons.Get("System","Info") end
   end
   self.PanelHeaderIcon.Image=headerImage
  end
 end
 if self.PanelHeaderAccent then self.PanelHeaderAccent.Visible=not workshop end
 if self.PanelClose then
  self.PanelClose.Visible=true
  self.PanelClose.Position=workshop and UDim2.new(1,-48,0,12) or UDim2.new(1,-44,0,10)
  self.PanelClose.ZIndex=workshop and 120 or 53
 end

 -- Bloom UI Studio previews Inventory v2 on a 1220x660 MainPanel.
 -- Mirror that authored canvas at runtime instead of inheriting the generic
 -- 600x420 menu size. Narrower desktop screens are capped to the viewport.
 if not workshop then
  local safeSize=self.SafeRoot and self.SafeRoot.AbsoluteSize or Vector2.new(1366,768)
  local safeW=safeSize.X>100 and safeSize.X or 1366
  local safeH=safeSize.Y>100 and safeSize.Y or 768

  self.Panel.AnchorPoint=Vector2.new(.5,.5)
  self.Panel.Position=UDim2.new(.5,0,.51,0)

  if self.IsMobileLayout then
   self.Panel.Size=UDim2.fromOffset(math.max(300,safeW-16),math.max(300,safeH-108))
  elseif renderer=="InventoryV2" then
   self.Panel.Size=UDim2.fromOffset(math.min(1220,math.max(700,safeW-24)),math.min(660,math.max(500,safeH-24)))
  else
   self.Panel.Size=UDim2.fromOffset(600,420)
  end

  -- Workshop makes Content fullscreen; restore normal authored menu geometry.
  self.Content.Position=UDim2.fromOffset(9,60)
  self.Content.Size=UDim2.new(1,-18,1,-68)
  self.Content.ZIndex=52
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.Y
  self.Content.ScrollingEnabled=true
  self.Content.ScrollBarThickness=4
 end

 if not workshop then self.Content.CanvasPosition=Vector2.new() end

 if workshop then
  -- Workshop is intentionally chrome-free: only the close button floats above the map.
  self.Panel.AnchorPoint=Vector2.new(.5,.5)
  self.Panel.Position=UDim2.fromScale(.5,.5)
  self.Panel.Size=UDim2.fromScale(1,1)
  self.Content.Position=UDim2.fromOffset(0,0)
  self.Content.Size=UDim2.fromScale(1,1)
  self.Content.ZIndex=52
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
 elseif renderer=="InventoryV2" then
  -- SeedSatchel is the persistent feature/unlock id; InventoryV2 is its only
  -- live renderer. Keep the outer Content fixed because ItemGrid scrolls itself.
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  InventoryV2.Render(self,p,ui)

 elseif renderer=="Workshop" then
  local shell=self.WorkshopRuntime
  local firstWorkshopBuild=not shell or shell.Parent~=self.Content
  local template=self.Panel:FindFirstChild("WorkshopTemplate")
  if firstWorkshopBuild and not template then
   self:Label(self.Content,"WorkshopTemplate missing",32)
  else
   if firstWorkshopBuild then
    shell=template:Clone()
    shell.Name="WorkshopRuntime"
    shell.Visible=true
    shell.Parent=self.Content
    shell.Size=UDim2.fromScale(1,1)
    shell.Position=UDim2.new()
    shell.LayoutOrder=1
    self.WorkshopRuntime=shell
    self.WorkshopZoomLabel=nil
   end

   local workshopUI=ui.Workshop
   local body=shell:WaitForChild("WorkshopBody")
   local treePanel=body:WaitForChild("TreePanel")
   local canvas=treePanel:WaitForChild("TreeCanvas")
   local panMap=canvas:FindFirstChild("PanMap")
   if panMap and panMap:IsA("GuiObject") then
    -- Editor-only positioning never affects the runtime map.
    panMap.Position=UDim2.fromOffset(0,0)
   end

   local nodes=canvas:FindFirstChild("Nodes") or panMap
   local links=canvas:FindFirstChild("Connections") or panMap
   if not nodes or not links then error("[BloomUI] Workshop tree containers missing") end

   local tooltip=body:WaitForChild("NodeTooltip")
   if firstWorkshopBuild then tooltip.Visible=false end
   tooltip.Active=false
   local tooltipTitle=tooltip:WaitForChild("Title")
   local tooltipBranch=tooltip:WaitForChild("Branch")
   local tooltipEffect=tooltip:WaitForChild("Effect")
   local tooltipCost=tooltip:WaitForChild("Cost")
   local tooltipHint=tooltip:WaitForChild("Hint")
   local tooltipAccent=tooltip:WaitForChild("Accent")
   local tooltipStroke=tooltip:FindFirstChildOfClass("UIStroke")

   local effects=require(RS.Config.WorkshopEffectsConfig)

   local function nodeRevealed(id)
    local node=W.Nodes[id]
    if not node then return false end
    local backend=workshopUI and workshopUI.Nodes and workshopUI.Nodes[id]
    if backend then return backend.Revealed==true end
    if id=="CORE" or p.WorkshopV5.Nodes[id]==true then return true end
    return node.Parent=="CORE" or (node.Parent and p.WorkshopV5.Nodes[node.Parent]==true) or false
   end

   self.SelectedNode=self.SelectedNode or "CORE"
   if not nodeRevealed(self.SelectedNode) then self.SelectedNode="CORE" end
   local selectedNode=W.Nodes[self.SelectedNode] or W.Nodes.CORE
   local selectedId=selectedNode and selectedNode.Id or "CORE"

   local branchColors={
    CORE=C.White,
    ROLL=C.Blue,
    GARDEN=C.Green,
    BEES=C.Honey,
    ECONOMY=C.Gold,
    BLOOM=C.Dust,
    EXPLORATION=C.Nectar,
    LEGACY=C.Danger,
   }

   local function moveTooltip(screenX,screenY)
    if not tooltip.Parent then return end
    local localX=screenX-body.AbsolutePosition.X+16
    local localY=screenY-body.AbsolutePosition.Y+16
    local maxX=math.max(8,body.AbsoluteSize.X-tooltip.AbsoluteSize.X-8)
    local maxY=math.max(8,body.AbsoluteSize.Y-tooltip.AbsoluteSize.Y-8)
    tooltip.Position=UDim2.fromOffset(math.clamp(localX,8,maxX),math.clamp(localY,8,maxY))
   end

   local function showTooltip(id,node,backend,owned,available,branchColor)
    local reasonText=backend and backend.ReasonText
    tooltipTitle.Text=node.Name
    tooltipBranch.Text=node.Branch.."  •  "..(owned and "OWNED" or available and "AVAILABLE" or "LOCKED")
    tooltipEffect.Text=workshopEffectText(effects[id])
    tooltipCost.Text=workshopCostText(node)
    tooltipAccent.BackgroundColor3=branchColor
    if tooltipStroke then tooltipStroke.Color=branchColor end

    if id=="CORE" then
     tooltipHint.Text="CORE NODE"
     tooltipHint.TextColor3=C.Muted
    elseif owned then
     tooltipHint.Text="OWNED"
     tooltipHint.TextColor3=C.Green
    elseif not available then
     tooltipHint.Text=reasonText or "LOCKED"
     tooltipHint.TextColor3=C.Faint
    elseif self.SelectedNode==id then
     tooltipHint.Text="CLICK AGAIN TO UPGRADE"
     tooltipHint.TextColor3=C.Green
    else
     tooltipHint.Text="CLICK TO SELECT"
     tooltipHint.TextColor3=C.Blue
    end
    tooltip.Visible=true
   end

   for id,n in pairs(W.Nodes) do
    local node=nodes:FindFirstChild("Node_"..id)
    local backend=workshopUI and workshopUI.Nodes and workshopUI.Nodes[id]
    local owned
    local revealed
    local available
    if backend then
     owned=backend.Owned==true
     revealed=backend.Revealed==true
     available=revealed and backend.Available==true
    else
     owned=id=="CORE" or p.WorkshopV5.Nodes[id]==true
     local parentOwned=not n.Parent or n.Parent=="CORE" or p.WorkshopV5.Nodes[n.Parent]==true
     revealed=owned or id=="CORE" or parentOwned
     available=revealed and not owned and p.Hive.Level>=(n.Hive or 0)
    end

    local selected=revealed and id==selectedId
    local branchColor=branchColors[n.Branch] or C.Blue

    if node and node:IsA("TextButton") then
     local icon=node:FindFirstChild("HexIcon")
     local label=node:FindFirstChild("NodeName")
     local level=node:FindFirstChild("Level")
     local nodeScale=node:FindFirstChild("NodeScale")
     local selectionGlow=node:FindFirstChild("SelectionGlow")

     if not nodeScale then
      nodeScale=Instance.new("UIScale")
      nodeScale.Name="NodeScale"
      nodeScale.Parent=node
     end
     if not selectionGlow and icon and icon:IsA("ImageLabel") then
      selectionGlow=icon:Clone()
      selectionGlow.Name="SelectionGlow"
      selectionGlow.Size=UDim2.new(1,18,1,18)
      selectionGlow.Position=UDim2.fromOffset(-9,-9)
      selectionGlow.ImageColor3=C.Gold
      selectionGlow.ImageTransparency=.58
      selectionGlow.ZIndex=math.max(1,icon.ZIndex-1)
      selectionGlow.Visible=false
      selectionGlow.Parent=node
     end

     if label and label:IsA("TextLabel") then label.Visible=false end
     if level and level:IsA("TextLabel") then level.Visible=false end

     local baseTransparency=not revealed and .52 or owned and 0 or available and .06 or .28
     if icon and icon:IsA("ImageLabel") then
      icon.Image=Icons.GetWorkshopNodeIcon(id,not revealed)
      icon.ImageColor3=not revealed and C.Faint or selected and C.Gold or owned and C.Green or available and branchColor or C.Faint
      icon.ImageTransparency=baseTransparency
     end
     if selectionGlow and selectionGlow:IsA("ImageLabel") then
      selectionGlow.Image=icon and icon:IsA("ImageLabel") and icon.Image or Icons.GetWorkshopNodeIcon(id,not revealed)
      selectionGlow.ImageColor3=C.Gold
      selectionGlow.ImageTransparency=.52
      selectionGlow.Visible=revealed and selected
     end

     local baseScale=selected and 1.12 or 1
     nodeScale.Scale=baseScale
     node.ZIndex=selected and 60 or 57
     local nodeId=id
     local isSelected=selected

     node:SetAttribute("BloomWorkshopOwned",owned)
     node:SetAttribute("BloomWorkshopRevealed",revealed)
     node:SetAttribute("BloomWorkshopAvailable",available)
     node:SetAttribute("BloomWorkshopSelected",selected)
     node:SetAttribute("BloomWorkshopTransparency",baseTransparency)

     if not node:GetAttribute("BloomWorkshopBound") then
      node:SetAttribute("BloomWorkshopBound",true)
      node.MouseEnter:Connect(function(x,y)
       if not node.Parent then return end
       local currentRevealed=node:GetAttribute("BloomWorkshopRevealed")==true
       local currentSelected=node:GetAttribute("BloomWorkshopSelected")==true
       local currentTransparency=tonumber(node:GetAttribute("BloomWorkshopTransparency")) or .28
       local currentOwned=node:GetAttribute("BloomWorkshopOwned")==true
       local currentAvailable=node:GetAttribute("BloomWorkshopAvailable")==true
       local currentUI=self.State and self.State.UI and self.State.UI.Workshop
       local currentBackend=currentUI and currentUI.Nodes and currentUI.Nodes[nodeId]
       TweenService:Create(nodeScale,TweenInfo.new(Theme.Motion.Fast,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
        Scale=currentSelected and 1.18 or currentRevealed and 1.09 or 1.04,
       }):Play()
       if icon and icon.Parent then
        TweenService:Create(icon,TweenInfo.new(Theme.Motion.Fast),{ImageTransparency=math.max(0,currentTransparency-(currentRevealed and .12 or .05))}):Play()
       end
       if currentRevealed then
        showTooltip(nodeId,n,currentBackend,currentOwned,currentAvailable,branchColor)
        if typeof(x)=="number" and typeof(y)=="number" then moveTooltip(x,y) else
         local mouse=UIS:GetMouseLocation()
         moveTooltip(mouse.X,mouse.Y)
        end
       else
        tooltip.Visible=false
       end
      end)
      node.MouseMoved:Connect(function(x,y)
       if node:GetAttribute("BloomWorkshopRevealed")==true and tooltip.Visible then moveTooltip(x,y) end
      end)
      node.MouseLeave:Connect(function()
       if not node.Parent then return end
       local currentSelected=node:GetAttribute("BloomWorkshopSelected")==true
       local currentTransparency=tonumber(node:GetAttribute("BloomWorkshopTransparency")) or .28
       TweenService:Create(nodeScale,TweenInfo.new(Theme.Motion.Fast,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Scale=currentSelected and 1.12 or 1}):Play()
       if icon and icon.Parent then TweenService:Create(icon,TweenInfo.new(Theme.Motion.Fast),{ImageTransparency=currentTransparency}):Play() end
       tooltip.Visible=false
      end)
      node.Activated:Connect(function()
       local currentRevealed=node:GetAttribute("BloomWorkshopRevealed")==true
       local currentOwned=node:GetAttribute("BloomWorkshopOwned")==true
       local currentAvailable=node:GetAttribute("BloomWorkshopAvailable")==true
       if not currentRevealed then return end
       if nodeId=="CORE" then
        self.SelectedNode=nodeId
        self:RenderMenu()
        return
       end
       if self.SelectedNode==nodeId then
        if currentAvailable and not currentOwned then self:Send("WorkshopBuy",nodeId) end
        return
       end
       self.SelectedNode=nodeId
       self:RenderMenu()
      end)
     end
    end

    if n.Parent then
     local link=links:FindFirstChild("Link_"..n.Parent.."_"..id)
     if link and link:IsA("Frame") then
      local parentOwned=n.Parent=="CORE" or p.WorkshopV5.Nodes[n.Parent]==true
      local onSelectedPath=selectedNode
       and n.Branch==selectedNode.Branch
       and (n.Index or 0)<=(selectedNode.Index or 0)
      link.BackgroundColor3=onSelectedPath and C.Gold or revealed and parentOwned and branchColor or C.BorderSoft
      link.BackgroundTransparency=onSelectedPath and .08 or revealed and parentOwned and (owned and .10 or available and .30 or .48) or .84
      link.Size=UDim2.new(link.Size.X.Scale,link.Size.X.Offset,0,onSelectedPath and 6 or revealed and 4 or 2)
     end
    end
   end

   if firstWorkshopBuild then
    if self.WorkshopCanvasPosition then
     canvas.CanvasPosition=self.WorkshopCanvasPosition
    end
    self:BindWorkshopPan(canvas,nodes)
    task.defer(function()
     if not canvas.Parent then return end
     local position=self.WorkshopCanvasPosition
     if not position then
      local core=nodes:FindFirstChild("Node_CORE")
      if core and core:IsA("GuiObject") then
       local zoom=self.WorkshopZoom or 1
       local coreCenter=Vector2.new(
        core.Position.X.Offset+core.Size.X.Offset*.5,
        core.Position.Y.Offset+core.Size.Y.Offset*.5
       )*zoom
       position=coreCenter-canvas.AbsoluteSize*.5
      else
       position=Vector2.new(650,500)
      end
     end
     position=self:ClampWorkshopCanvasPosition(canvas,position)
     canvas.CanvasPosition=position
     self.WorkshopCanvasPosition=position
    end)
   end
  end
 elseif name=="Plant" then
  local slot=tonumber(self.MenuArg)
  self:Section(self.Content,slot and ("Garden Slot "..tostring(slot)) or "Garden")
  if not slot then
   self:Label(self.Content,"Use an unlocked garden pad to choose where to plant.",40)
  else
   self:Label(self.Content,"Choose a free flower copy for this physical garden slot.",42)
   local flowers=ui.Inventory and ui.Inventory.Flowers or {}
   local available={}
   for _,item in ipairs(flowers) do
    if (tonumber(item.Free) or 0)>0 then table.insert(available,item) end
   end
   table.sort(available,function(a,b)
    local preferredA=a.Id==self.LastSeed
    local preferredB=b.Id==self.LastSeed
    if preferredA~=preferredB then return preferredA end
    return tostring(a.DisplayName or a.Id)<tostring(b.DisplayName or b.Id)
   end)
   if #available==0 then
    self:Label(self.Content,"No free flower copies are available. Roll or dissolve/manage planted copies first.",48)
   else
    for _,item in ipairs(available) do
     local label=(item.Id==self.LastSeed and "★  " or "")..tostring(item.DisplayName or item.Id).."   •   "..tostring(item.Rarity or "Common").."   •   x"..tostring(item.Free)
     self:Button(self.Content,label,function()
      self.LastSeed=item.Id
      self:Send("Plant",slot,item.Id)
      self:Close()
     end,Icons.GetFlowerIcon(item.Id))
    end
   end
   self:Button(self.Content,"Cancel",function() self:Close() end,Icons.Get("System","Close"))
  end

 elseif name=="FieldGuide" then
  self:Section(self.Content,"Collection and real odds")
  self:Label(self.Content,"Odds include your current modifiers and the guaranteed new discovery.",48)
  for _,item in ipairs(self.State.Odds) do
   self:Label(self.Content,item.DisplayName.."   •   "..item.Rarity..string.format("   •   %.6f%%",item.Chance*100)..(item.Undiscovered and "   •   UNDISCOVERED" or "   •   discovered"),38)
  end
  self:Section(self.Content,"Synergies")
  self:Label(self.Content,"Pairs: Daisy + Tulip; Sunflower + Clover.",36)
  if p.WorkshopV5.Nodes.GARDEN_5 then self:Label(self.Content,"Crystal triangle: 1, 2, 6; Meadow line: 1, 2, 3; opposite: 1, 15.",48) end
  for id in pairs(p.GardenSynergies.Discovered) do self:Label(self.Content,id.."   •   mastery "..(p.GardenSynergies.Mastery[id] or 0),34) end

 elseif name=="Map" then
  self:Section(self.Content,"Bloom RNG World")
  local mapUI=ui.Map
  local pulse=mapUI and mapUI.Pulse or self.State.Pulse
  if p.WorkshopV5.Nodes.EXPLORATION_1 and pulse then self:Label(self.Content,"Biome Pulse  •  "..pulse.Sector,36) end
  for _,id in ipairs(L.Order) do
   local sector=mapUI and mapUI.Sectors and mapUI.Sectors[id]
   local unlocked=sector and sector.Unlocked or p.World.UnlockedSectors[id]
   local current=sector and sector.Current
   local hint=sector and sector.UnlockHint or (unlocked and "Unlocked" or "Reach Hive "..L.Sectors[id].Hive)
   local marker=current and "  •  YOU ARE HERE" or ""
   self:Label(self.Content,L.Sectors[id].Name.."   •   "..hint..marker,44)
  end
  self:Section(self.Content,"Landmarks")
  local any=false
  for id in pairs(p.World.LandmarkDiscoveries) do any=true self:Label(self.Content,"✓  "..id,32) end
  if not any then self:Label(self.Content,"Nothing discovered yet.",32) end
  self:Button(self.Content,"View Build Trials  •  start them at sector shrines",function() self:Open("Trials") end,Icons.Get("System","Quests"))

 elseif name=="Trials" then
  self:Section(self.Content,"Build Trials")
  local trialsUI=ui.Trials
  if trialsUI and trialsUI.Active then
   self:Label(self.Content,"ACTIVE  •  "..trialsUI.Active.Id.."  •  "..math.ceil(trialsUI.Active.TimeLeft or 0).."s",34)
  end
  if trialsUI and type(trialsUI.Items)=="table" then
   for _,t in ipairs(trialsUI.Items) do
    local hint=t.StartHint or (t.ReasonText and t.ReasonText or "")
    local suffix=hint~="" and "  •  "..hint or ""
    local button=self:Button(self.Content,(t.Completed and "✓  " or "")..t.Name.."   •   "..t.Sector..suffix,function() self:Send("Trial",t.Id) end,Icons.Get("System","Quests"))
    button.Active=t.CanStart==true
   end
  else
   for id,t in pairs(Trials) do
    self:Button(self.Content,(p.Quests.Trials[id] and "✓  " or "")..t.Name.."   •   "..t.Sector,function() self:Send("Trial",id) end,Icons.Get("System","Quests"))
   end
  end

 elseif name=="Settings" then
  self:Section(self.Content,"Interface and Effects")
  for _,id in ipairs({"ReducedEffects","ShowOtherPollinators","HideOtherPlayersTokens","RareFeed","AutoDissolve"}) do
   local on=p.Settings[id]==true
   local enabled=not (id=="AutoDissolve" and ui.Settings and not ui.Settings.AutoDissolveUnlocked)
   local button=self:Button(self.Content,(SETTINGS_NAMES[id] or id).."   •   "..(on and "ON" or "OFF"),function() self:Send("Setting",id,not on) end,Icons.Get("System",on and "Confirm" or "Minus"))
   button.Active=enabled
  end
  self:Button(self.Content,"Activity volume   •   "..math.floor((p.Settings.TokenSoundVolume or 0)*100).."%",function() self:Send("Setting","TokenSoundVolume",(p.Settings.TokenSoundVolume+.25)%1.25) end,Icons.Get("System","Info"))
  if p.WorkshopV5.Nodes.ECONOMY_2 then
   self:Section(self.Content,"Auto-Dissolve Filter")
   for _,rarity in ipairs(R.Order) do
    local on=p.Settings.DissolveRarities[rarity]==true
    self:Button(self.Content,"Dissolve "..rarity.."   •   "..(on and "ON" or "OFF"),function() self:Send("DissolveFilter",rarity) end,Icons.Get("WorkshopHex","Duplicate"))
   end
  end
  self:Section(self.Content,"Tutorial")
  self:Button(self.Content,"Skip Tutorial",function() self:Send("Skip") end,Icons.Get("System","Warning"))
  self:Button(self.Content,"Replay Tutorial",function() self:Send("Replay") end,Icons.Get("System","Tutorial"))

 elseif name=="Season" then
  local preview=self.MenuArg
  self:Section(self.Content,"What Will Be Kept")
  self:Label(self.Content,table.concat(preview.Keep,", "),38)
  self:Section(self.Content,"Changes")
  for _,diff in ipairs(preview.Diff) do self:Label(self.Content,diff.Path..":  "..tostring(diff.Before).."  →  "..tostring(diff.After),38) end
  self:Button(self.Content,self.SeasonSecond and "CONFIRM SEASON RESET" or "Continue",function() self:Send("SeasonConfirm",preview.Token) end,Icons.Get("System",self.SeasonSecond and "Warning" or "Confirm"))

 elseif name=="Replay" then
  local i=self.ReplayIndex or 1
  self.ReplayIndex=i
  self:Section(self.Content,"Step "..i.." of "..#T.Steps)
  self:Label(self.Content,T.Steps[i].Text,38)
  self:Button(self.Content,"Next Step",function() self.ReplayIndex=i%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowRight"))
  self:Button(self.Content,"Previous Step",function() self.ReplayIndex=(i-2)%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowLeft"))

 elseif name=="Cards" then
  self:Section(self.Content,"Card Selection")
  for _,id in ipairs(self.State.Cards) do self:Button(self.Content,id,function() self:Send("Card",id) self:Close() end,Icons.Get("System","Confirm")) end
 end
end

function UI:ApplySafeArea()
 if not self.Gui or not self.SafeRoot then return end
 self.SafeRoot.Position=UDim2.fromScale(0,0)
 self.SafeRoot.Size=UDim2.fromScale(1,1)
 local size=self.SafeRoot.AbsoluteSize
 local camera=Workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(1366,768)
 local safeW=size.X>100 and size.X or viewport.X
 local safeH=size.Y>100 and size.Y or viewport.Y
 self:ApplyResponsiveLayout(math.max(320,safeW),math.max(360,safeH))
end

function UI:ApplyResponsiveLayout(width,height)
 -- Desktop layout is authored in StarterGui. Do not overwrite positions/sizes here,
 -- so designers can move every HUD block directly in Studio.
 self.IsMobileLayout=width<700
 if width>=700 then return end

 -- Small-screen safety only. These adjustments intentionally touch as little as possible.
 self.ObjectiveCard.Size=UDim2.fromOffset(math.max(280,width-24),66)
 self.CurrencyHUD.Position=UDim2.fromOffset(10,208)
 self.Dock.AnchorPoint=Vector2.new(1,.5)
 self.Dock.Position=UDim2.new(1,-10,.56,0)
 self.Guide.Size=UDim2.fromOffset(math.max(260,width-24),38)
 self.RollHUD.Size=UDim2.fromOffset(math.min(300,width-18),38)
 self.RollHUD.AnchorPoint=Vector2.new(.5,1)
 self.RollHUD.Position=UDim2.new(.5,0,1,-62)
 self.Roll.AnchorPoint=Vector2.new(.5,1)
 self.Roll.Position=UDim2.new(.5,0,1,-10)
 self.RouletteViewport.AnchorPoint=Vector2.new(.5,0)
 self.RouletteViewport.Position=UDim2.new(.5,0,0,78)
 self.ToastRoot.Size=UDim2.fromOffset(math.max(260,width-24),36)
 self.Panel.Size=UDim2.fromOffset(math.max(300,width-16),math.max(300,height-108))
 self.Panel.Position=UDim2.new(.5,0,.52,0)
 self.Reveal.Size=UDim2.fromOffset(math.max(280,width-24),100)
end

function UI:Render()
 self.ObjectiveCard.Visible=true
 self.CurrencyHUD.Visible=true
 local p=self.State.Profile
 local step=T.Steps[p.Tutorial.Step]
 if step then
  self.ObjectiveTitle.Text="TUTORIAL  •  "..p.Tutorial.Step.."/"..#T.Steps
  self.ObjectiveText.Text=step.Text
  self.ObjectiveProgressFill.Size=UDim2.fromScale(math.clamp((p.Tutorial.Step-1)/#T.Steps,0,1),1)
  self.ObjectiveProgress.Visible=true
 else
  self.ObjectiveTitle.Text="JOURNEY  •  STEP "..tostring(p.Quests.JourneyStep or 1)
  self.ObjectiveText.Text=JOURNEY[p.Quests.JourneyStep] or "Keep growing your garden"
  self.ObjectiveProgress.Visible=false
 end

 self.CurrencyRows.Coins.Value.Text=compact(p.Currencies.Coins)
 self.CurrencyRows.Honey.Value.Text=compact(p.Hive.Honey)
 self.CurrencyRows.Hive.Value.Text="Level "..tostring(p.Hive.Level)
 self.CurrencyRows.PetalDust.Value.Text=compact(p.Currencies.PetalDust)
 self.CurrencyRows.PetalDust.Root.Visible=p.Tutorial.FeatureUnlocks.SeedSatchel==true
 self.CurrencyRows.AncientNectar.Value.Text=compact(p.Currencies.AncientNectar)
 self.CurrencyRows.AncientNectar.Root.Visible=(p.Season.Count or 0)>0 or (p.Currencies.AncientNectar or 0)>0

 local rollUnlocked=p.Tutorial.FeatureUnlocks.Roll==true
 self.RollHUD.Visible=rollUnlocked
 self.Roll.Visible=rollUnlocked
 self.RouletteViewport.Visible=rollUnlocked and (self.Auto or self.RouletteRunning or self.RouletteLanding)
 if not rollUnlocked and (self.Auto or self.RouletteRunning or self.RouletteLanding) then
  self.Auto=false
  self:StopRouletteAnimation()
 end

 local special=p.RollState.SpecialRollReady==true
 if self.Auto then
  self.Roll.Text=""
  self.Roll.BackgroundTransparency=1
  if self.RollStroke then self.RollStroke.Color=C.Green end
  self.RollIcon.Image=Icons.GetActionIcon("AutoRoll")
 else
  self.Roll.Text=""
  self.Roll.BackgroundTransparency=1
  if self.RollStroke then self.RollStroke.Color=special and C.Gold or C.Blue end
  self.RollIcon.Image=Icons.GetActionIcon("Roll")
 end
 self.RollIcon.ImageColor3=C.White
 if self.RollStatusDot then
  self.RollStatusDot.BackgroundColor3=self.Auto and C.Green or C.Faint
 end
 if self.Auto and not self.RouletteRunning and not self.RouletteLanding then self:StartRouletteAnimation() end

 local charge=math.clamp(tonumber(p.RollState.BloomCharge) or 0,0,100)
 local pity=math.min(30,tonumber(p.RollState.DiscoveryPity) or 0)
 self.MeterLabel.Text=string.format("BLOOM  %.0f%%     •     DISCOVERY  %d/30",charge,pity)..(p.WorkshopV5.Nodes.ROLL_4 and pity>=29 and "  •  NEW GUARANTEED" or "")
 self.BloomFill.Size=UDim2.fromScale(charge/100,1)
 self.MeterArea.Visible=rollUnlocked and (p.Tutorial.Step>=10 or p.Tutorial.Skipped)

 for name,b in pairs(self.DockButtons) do b.Visible=name=="Settings" or p.Tutorial.FeatureUnlocks[name]==true end
 if not self:IsWorkshopExclusive() then self.GuideController:Update() end
 self.GardenPresentation:Update()
 self:ApplyWorkshopFocusVisibility()
end

function UI:RollNow(automatic)
 if self.Pending or self.RouletteLanding or (self.Rewards and self.Rewards.Busy) or os.clock()<self.NextRoll or not self.State then return end
 self.Pending=true
 self.PendingAt=os.clock()
 self.RollRequestSequence=(self.RollRequestSequence or 0)%2147483646+1
 local requestId=self.RollRequestSequence
 self.PendingRollRequest=requestId
 self.PendingRollSession=self.RollSession or 0
 self.RollRequestSessions[requestId]=self.PendingRollSession
 local stale=requestId-64
 if stale>0 then self.RollRequestSessions[stale]=nil end
 self:Send("Roll",automatic==true,requestId)
end

function UI:BuildRouletteVisualPool(preserveCursor)
 local previous=nil
 if preserveCursor and self.RouletteVisualPool and self.RouletteCursor then
  previous=self.RouletteVisualPool[self.RouletteCursor]
 end
 local pool={}
 local serverPool=self.State and self.State.Odds
 if type(serverPool)=="table" and #serverPool>0 then
  for _,item in ipairs(serverPool) do
   local icon=item.Kind=="Bee" and Icons.GetBeeIcon(item.Id or "") or Icons.GetFlowerIcon(item.Id or "")
   if icon=="" then icon=Icons.Get("System",item.Kind=="Bee" and "Bee" or "Flower") end
   table.insert(pool,{
    Id=item.Id,Kind=item.Kind,DisplayName=item.DisplayName or item.Id,Rarity=item.Rarity or "Common",
    Icon=icon,Weight=item.Weight,Odds=item.Odds,Chance=item.Chance,
   })
  end
 else
  local totalWeight=0
  for id,data in pairs(F.Species) do
   local icon=Icons.GetFlowerIcon(id) if icon=="" then icon=Icons.Get("System","Flower") end
   local weight=math.max(0,tonumber(data.DropWeight) or 0) totalWeight=totalWeight+weight
   table.insert(pool,{Id=id,Kind="FlowerSeed",DisplayName=data.DisplayName or id,Rarity=data.Rarity or "Common",Icon=icon,Weight=weight})
  end
  for id,data in pairs(B.Bees) do
   local weight=math.max(0,tonumber(data.DropWeight) or 0) totalWeight=totalWeight+weight
   table.insert(pool,{Id=id,Kind="Bee",DisplayName=data.DisplayName or id,Rarity=data.Rarity or "Common",Icon=Icons.GetBeeIcon(id),Weight=weight})
  end
  for _,item in ipairs(pool) do item.Odds=item.Weight>0 and totalWeight/item.Weight or math.huge end
 end
 table.sort(pool,function(a,b)
  local ar=R.Rank[a.Rarity] or 1 local br=R.Rank[b.Rarity] or 1
  if ar==br then return tostring(a.DisplayName)<tostring(b.DisplayName) end
  return ar<br
 end)
 self.RouletteVisualPool=pool
 local cursor=1
 if previous then
  for i,item in ipairs(pool) do if item.Kind==previous.Kind and item.Id==previous.Id then cursor=i break end end
 end
 self.RouletteCursor=math.clamp(cursor,1,math.max(1,#pool))
 self:RefreshRouletteSlots()
end

function UI:SetRouletteSlot(slot,data,role)
 if not slot or not data then return end
 local icon=slot:FindFirstChild("Icon")
 local name=slot:FindFirstChild("Name")
 local chance=slot:FindFirstChild("Chance")
 local color=R.Colors[data.Rarity] or C.Muted
 local current=role=="Current"
 local faint=role=="Buffer" and .55 or current and 0 or .32
 local marker=slot:FindFirstChild("CurrentMarker") or slot:FindFirstChild("SelectionMarker")
 if marker and marker:IsA("GuiObject") then marker.Visible=current end
 if icon and icon:IsA("ImageLabel") then
  icon.Image=data.Icon or ""
  icon.ImageTransparency=faint
 end
 if name and name:IsA("TextLabel") then
  name.Text=data.DisplayName or data.Id or "?"
  name.TextTransparency=faint
  name.TextSize=current and 13 or 12
  name.TextColor3=current and C.Text or Color3.new(.86,.9,.95)
 end
 if chance and chance:IsA("TextLabel") then
  local odds=tonumber(data.Odds)
  chance.Text=odds and odds<math.huge and ("1 / "..compact(math.max(1,math.floor(odds+.5)))) or "1 / ∞"
  chance.TextColor3=current and C.Gold or color
  chance.TextTransparency=faint
  chance.TextSize=current and 10 or 9
 end
 local scale=slot:FindFirstChild("SlotScale")
 if not scale then
  scale=Instance.new("UIScale")
  scale.Name="SlotScale"
  scale.Parent=slot
 end
 scale.Scale=current and 1.04 or .92
end

function UI:RouletteIndex(offset)
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 then return 1 end
 return ((self.RouletteCursor-1+offset)%#pool)+1
end

function UI:EnsureRouletteRuntimeBuffer()
 if self.RouletteBuffer and self.RouletteBuffer.Parent==self.RouletteStrip then return self.RouletteBuffer end
 if not self.RouletteStrip or not self.RouletteSlots or not self.RouletteSlots.Next then return nil end
 local stale=self.RouletteStrip:FindFirstChild("Buffer") or self.RouletteStrip:FindFirstChild("_RuntimeBuffer")
 if stale then stale:Destroy() end
 local source=self.RouletteSlots.Next
 local buffer=source:Clone()
 buffer.Name="_RuntimeBuffer"
 buffer.Position=UDim2.new(source.Position.X.Scale,source.Position.X.Offset,source.Position.Y.Scale,source.Position.Y.Offset-(RollAudio.StepPixels or 48))
 buffer.Visible=true
 buffer.Parent=self.RouletteStrip
 self.RouletteBuffer=buffer
 return buffer
end

function UI:RefreshRouletteSlots()
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 or not self.RouletteSlots then return end
 local buffer=self:EnsureRouletteRuntimeBuffer()
 if buffer then self:SetRouletteSlot(buffer,pool[self:RouletteIndex(2)],"Buffer") end
 self:SetRouletteSlot(self.RouletteSlots.Next,pool[self:RouletteIndex(1)],"Next")
 self:SetRouletteSlot(self.RouletteSlots.Current,pool[self:RouletteIndex(0)],"Current")
 self:SetRouletteSlot(self.RouletteSlots.Previous,pool[self:RouletteIndex(-1)],"Previous")
end

function UI:PlayRouletteTick()
 local s=self.RouletteSpinSound
 if not s then return end
 s:Stop() s.TimePosition=0
 local master=self.State and self.State.Profile.Settings.TokenSoundVolume or .5
 s.Volume=RollAudio.SpinVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.SpinPlaybackSpeed+Random.new():NextNumber(-.06,.06)
 s:Play()
end

function UI:PlayRouletteRewardSound()
 local s=self.RouletteRewardSound
 if not s then return end
 s:Stop() s.TimePosition=0
 local master=self.State and self.State.Profile.Settings.TokenSoundVolume or .5
 s.Volume=RollAudio.RewardVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.RewardPlaybackSpeed s:Play()
end

function UI:StepRoulette(duration,targetIndex,generation)
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 or not self.RouletteStrip then return false end
 if targetIndex then
  self.RouletteCursor=((targetIndex-2)%#pool)+1
  self:RefreshRouletteSlots()
 end
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 local tween=TweenService:Create(self.RouletteStrip,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Position=UDim2.fromOffset(0,RollAudio.StepPixels)})
 self.RouletteTween=tween self:PlayRouletteTick() tween:Play() tween.Completed:Wait()
 if generation and generation~=self.RouletteGeneration then return false end
 if self.RouletteTween==tween then self.RouletteTween=nil end
 if targetIndex then self.RouletteCursor=targetIndex else self.RouletteCursor=(self.RouletteCursor%#pool)+1 end
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 self:RefreshRouletteSlots()
 return true
end

function UI:StartRouletteAnimation()
 if self.RouletteRunning or self.RouletteLanding or not self.RouletteStrip then return end
 self.RouletteRunning=true
 if self.RouletteViewport then self.RouletteViewport.Visible=true end
 self.RouletteGeneration=self.RouletteGeneration+1
 local generation=self.RouletteGeneration
 task.spawn(function()
  while self.RouletteRunning and not self.RouletteLanding and generation==self.RouletteGeneration and self.Gui and self.Gui.Parent do
   if not self:StepRoulette(RollAudio.CruiseStep,nil,generation) then break end
  end
  if generation==self.RouletteGeneration and self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
  if generation==self.RouletteGeneration then self.RouletteTween=nil end
 end)
end

function UI:StopRouletteAnimation()
 self.RouletteRunning=false
 self.RouletteLanding=false
 self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 if self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
 self:RefreshRouletteSlots()
 if self.RouletteViewport then self.RouletteViewport.Visible=false end
end

function UI:SetAutoRolling(enabled)
 if enabled and (not self.State or self.State.Profile.Tutorial.FeatureUnlocks.Roll~=true) then return end
 local nextAuto=enabled==true
 if self.Auto~=nextAuto then self.RollSession=(self.RollSession or 0)+1 end
 self.Auto=nextAuto
 if self.Auto then
  self:StartRouletteAnimation()
  task.defer(function() self:RollNow(true) end)
 else
  -- Second click is a hard visual stop: cancel the reel and hide it immediately.
  self:StopRouletteAnimation()
 end
 if self.State then self:Render() end
end

function UI:FindRouletteTarget(payload)
 local pool=self.RouletteVisualPool or {}
 for i,item in ipairs(pool) do if item.Kind==payload.Kind and item.Id==payload.Id then return i end end
 local icon=payload.Kind=="Bee" and Icons.GetBeeIcon(payload.Id or "") or Icons.GetFlowerIcon(payload.Id or "")
 if icon=="" then icon=Icons.Get("System",payload.Kind=="Bee" and "Bee" or "Flower") end
 table.insert(pool,{Id=payload.Id,Kind=payload.Kind,DisplayName=payload.DisplayName or payload.Id or "Reward",Rarity=payload.Rarity or "Common",Icon=icon,Odds=payload.Odds,Chance=payload.Chance})
 self.RouletteVisualPool=pool return #pool
end

function UI:AnimateRouletteResult()
 local slot=self.RouletteSlots and self.RouletteSlots.Current if not slot then return end
 local scale=slot:FindFirstChild("SlotScale")
 local icon=slot:FindFirstChild("Icon")
 if scale then
  scale.Scale=1.04
  local pop=TweenService:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1.18}) pop:Play() pop.Completed:Wait()
  TweenService:Create(scale,TweenInfo.new(.20,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Scale=1.04}):Play()
 end
 if icon and icon:IsA("ImageLabel") then
  icon.Rotation=-7
  local swing=TweenService:Create(icon,TweenInfo.new(.16,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,1,true),{Rotation=7}) swing:Play() swing.Completed:Wait() icon.Rotation=0
 end
end

function UI:ResolveRouletteReward(payload)
 if type(payload)~="table" or self.RouletteLanding then return end
 local requestId=payload.RequestId
 local requestSession=requestId and self.RollRequestSessions[requestId] or self.PendingRollSession
 if requestSession~=nil and requestSession~=(self.RollSession or 0) then return end

 -- A server reward can arrive after the player pressed STOP.
 -- The item is already granted server-side; do not resurrect the roulette
 -- and do not show a separate RewardReveal card.
 if not self.Auto and not self.RouletteRunning then
  if self.RouletteViewport then self.RouletteViewport.Visible=false end
  return
 end

 self.RouletteLanding=true
 self.RouletteRunning=false
 if self.RouletteViewport then self.RouletteViewport.Visible=true end
 self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 local generation=self.RouletteGeneration
 task.spawn(function()
  local visualStart=os.clock()
  local target=self:FindRouletteTarget(payload)
  local steps=RollAudio.SettleSteps
  for i,duration in ipairs(steps) do
   if generation~=self.RouletteGeneration then break end
   local final=i==#steps
   if not self:StepRoulette(duration,final and target or nil,generation) then break end
  end
  if generation==self.RouletteGeneration then
   local remaining=math.max(0,(RollAudio.MinimumVisualSpin or 0)-(os.clock()-visualStart))
   if remaining>0 then task.wait(remaining) end
   self:PlayRouletteRewardSound()
   self:AnimateRouletteResult()
   task.wait(RollAudio.ResultHold)
  end
  if generation~=self.RouletteGeneration then return end
  self.RouletteLanding=false
  -- Normal roll rewards are shown only by the roulette itself.
  -- RewardReveal is reserved for non-roll ceremonies.
  if self.Auto then
   self:StartRouletteAnimation()
  elseif self.RouletteViewport then
   self.RouletteViewport.Visible=false
  end
 end)
end

function UI:BindStaticUI()
 local root=self.SafeRoot
 self.ObjectiveCard=root:WaitForChild("ObjectiveCard")
 self.ObjectiveTitle=self.ObjectiveCard:WaitForChild("ObjectiveTitle")
 self.ObjectiveText=self.ObjectiveCard:WaitForChild("ObjectiveText")
 self.ObjectiveProgress=self.ObjectiveCard:WaitForChild("ObjectiveProgress")
 self.ObjectiveProgressFill=self.ObjectiveProgress:WaitForChild("ObjectiveProgressFill")

 self.CurrencyHUD=root:WaitForChild("CurrencyHUD")
 self.CurrencyLayout=self.CurrencyHUD:FindFirstChildOfClass("UIListLayout")
 self.CurrencyRows={}
 local currencyColors={Coins=C.Gold,Honey=C.Honey,Hive=C.Green,PetalDust=C.Dust,AncientNectar=C.Nectar}
 local currencyIcons={Coins=Icons.GetCurrencyIcon("Coins"),Honey=Icons.Get("System","Hive"),Hive=Icons.Get("System","Hive"),PetalDust=Icons.GetCurrencyIcon("PetalDust"),AncientNectar=Icons.Get("System","Flower")}
 for _,key in ipairs({"Coins","Honey","Hive","PetalDust","AncientNectar"}) do
  local row=self.CurrencyHUD:WaitForChild(key)
  local iconRoot=row:FindFirstChild("IconBg")
  local icon=iconRoot and iconRoot:FindFirstChild("Icon") or row:FindFirstChild("Icon")
  if icon and icon:IsA("ImageLabel") then icon.Image=currencyIcons[key] or "" end
  local accent=row:FindFirstChild("Accent")
  if accent and accent:IsA("Frame") then accent.BackgroundColor3=currencyColors[key] end
  self.CurrencyRows[key]={Root=row,Title=row:WaitForChild("Title"),Value=row:WaitForChild("Value"),Icon=icon,Color=currencyColors[key]}
 end

 self.Dock=root:WaitForChild("MenuDock")
 self.DockLayout=self.Dock:FindFirstChildOfClass("UIListLayout")
 self.DockButtons={}
 self.DockTooltips={}
 for _,name in ipairs({"SeedSatchel","Workshop","FieldGuide","Map","Trials","Settings"}) do
  local button=self.Dock:WaitForChild("Dock_"..name)
  local tip=button:WaitForChild("Tooltip")
  tip.Text=MENU_NAMES[name] or name
  local icon=button:FindFirstChild("Icon")
  local image=Icons.Get("Menus",name)
  if image=="" and name=="Map" then image=Icons.Get("System","Garden") end
  if icon and icon:IsA("ImageLabel") then icon.Image=image end
  button.MouseEnter:Connect(function() tip.Visible=true TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play() end)
  button.MouseLeave:Connect(function() tip.Visible=false TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel}):Play() end)
  button.Activated:Connect(function() self:Open(name) end)
  self.DockButtons[name]=button
  self.DockTooltips[name]=tip
 end

 self.RollHUD=root:WaitForChild("RollHUD")
 self.RouletteViewport=root:WaitForChild("VerticalRoulette")
 self.RouletteViewport.Visible=false

 -- Remove any pre-refactor roulette that may still exist in a stale Studio place.
 -- The only supported reel is SafeRoot/VerticalRoulette.
 for _,legacy in ipairs(self.RollHUD:GetDescendants()) do
  local lower=string.lower(legacy.Name)
  if legacy:IsA("GuiObject") and (string.find(lower,"roulette",1,true) or string.find(lower,"reel",1,true)) then
   legacy:Destroy()
  end
 end
 for _,candidate in ipairs(root:GetDescendants()) do
  if candidate~=self.RouletteViewport and candidate.Name=="VerticalRoulette" and candidate:IsA("GuiObject") then
   candidate:Destroy()
  end
 end

 self.RouletteClip=self.RouletteViewport:FindFirstChild("RouletteClip")
 self.RouletteStrip=self.RouletteClip and self.RouletteClip:WaitForChild("ReelStrip") or self.RouletteViewport:WaitForChild("ReelStrip")
 self.RouletteSlots={
  Next=self.RouletteStrip:WaitForChild("Next"),
  Current=self.RouletteStrip:WaitForChild("Current"),
  Previous=self.RouletteStrip:WaitForChild("Previous"),
 }
 local staleBuffer=self.RouletteStrip:FindFirstChild("Buffer") or self.RouletteStrip:FindFirstChild("_RuntimeBuffer")
 if staleBuffer then staleBuffer:Destroy() end
 self.RouletteBuffer=nil
 self:EnsureRouletteRuntimeBuffer()
 self.RouletteSpinSound=Instance.new("Sound") self.RouletteSpinSound.Name="SpinSound" self.RouletteSpinSound.SoundId=RollAudio.SpinSound self.RouletteSpinSound.Volume=RollAudio.SpinVolume self.RouletteSpinSound.Parent=self.RouletteViewport
 self.RouletteRewardSound=Instance.new("Sound") self.RouletteRewardSound.Name="RewardSound" self.RouletteRewardSound.SoundId=RollAudio.RewardSound self.RouletteRewardSound.Volume=RollAudio.RewardVolume self.RouletteRewardSound.Parent=self.RouletteViewport
 self.MeterArea=self.RollHUD:WaitForChild("MeterArea")
 self.MeterLabel=self.MeterArea:WaitForChild("MeterLabel")
 self.BloomTrack=self.MeterArea:WaitForChild("BloomTrack")
 self.BloomFill=self.BloomTrack:WaitForChild("BloomFill")
 self.Roll=root:FindFirstChild("RollButton") or root:WaitForChild("TutorialRollButton")
 self.RollStroke=self.Roll:FindFirstChildOfClass("UIStroke")
 self.RollIcon=self.Roll:WaitForChild("Icon")
 self.RollStatusDot=self.Roll:FindFirstChild("StatusDot")
 self.Roll.Activated:Connect(function() self:SetAutoRolling(not self.Auto) end)
 self.Roll.MouseEnter:Connect(function()
  if not self.Roll.Visible then return end
  local target=self.Auto and C.Green or (self.State and self.State.Profile.RollState.SpecialRollReady and C.Green or C.Blue)
  TweenService:Create(self.Roll,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=target}):Play()
 end)
 self.Roll.MouseLeave:Connect(function() if self.State then self:Render() end end)

 self.Guide=root:WaitForChild("TutorialGuideBanner")
 self.ToastRoot=root:WaitForChild("Toast")
 self.ToastScale=self.ToastRoot:FindFirstChild("ToastScale") or self.ToastRoot:FindFirstChildOfClass("UIScale")
 self.ToastLabel=self.ToastRoot:WaitForChild("ToastLabel")

 self.ModalShade=root:WaitForChild("ModalShade")
 self.Panel=root:WaitForChild("MainPanel")
 self.PanelScale=self.Panel:FindFirstChild("PanelScale") or self.Panel:FindFirstChildOfClass("UIScale")
 local header=self.Panel:WaitForChild("Header")
 self.PanelHeader=header
 self.PanelHeaderIcon=header:FindFirstChild("HeaderIcon")
 self.PanelTitle=header:WaitForChild("PanelTitle")
 self.PanelSubtitle=header:WaitForChild("PanelSubtitle")
 self.PanelHeaderAccent=header:FindFirstChild("HeaderAccent")
 local close=header:WaitForChild("Close")
 self.PanelClose=close
 close.Activated:Connect(function() self:Close() end)
 close.MouseEnter:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Danger}):Play() end)
 close.MouseLeave:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelRaised}):Play() end)
 self.Content=self.Panel:WaitForChild("Content")
 self.ContentLayout=self.Content:FindFirstChildOfClass("UIListLayout")
 self.Templates=self.Panel:FindFirstChild("Templates")

 self.Reveal=root:WaitForChild("RewardReveal")
 self.RewardStroke=self.Reveal:FindFirstChildOfClass("UIStroke")
 self.RevealScale=self.Reveal:FindFirstChild("RevealScale") or self.Reveal:FindFirstChildOfClass("UIScale")
 self.RewardStripe=self.Reveal:WaitForChild("RewardStripe")
 self.RewardIcon=self.Reveal:WaitForChild("RewardIcon")
 self.RewardTitle=self.Reveal:WaitForChild("RewardTitle")
 self.RewardMeta=self.Reveal:WaitForChild("RewardMeta")
 self.RewardHint=self.Reveal:WaitForChild("RewardHint")
 self.Reveal.Activated:Connect(function() if self.Rewards then self.Rewards:SkipCurrent() end end)

 self:BuildRouletteVisualPool()
 self:RefreshRouletteSlots()
 self:PurgeLegacyRouletteGui()
end

function UI:ResolveBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")

 local function collect()
  local found={}
  for _,child in ipairs(playerGui:GetChildren()) do
   if child.Name=="BloomUI" and child:IsA("ScreenGui") then
    table.insert(found,child)
   end
  end
  return found
 end

 local function keepSingle(preferred)
  for _,gui in ipairs(collect()) do
   if gui~=preferred then
    warn("[BloomUI] Removing duplicate PlayerGui/BloomUI:",gui:GetFullName())
    gui:Destroy()
   end
  end
  return preferred
 end

 -- Prefer Roblox's normal StarterGui -> PlayerGui clone. This preserves the
 -- exact authored StarterGui tree and avoids creating a second HUD in Studio.
 local existingList=collect()
 if #existingList>0 then
  local existing=existingList[#existingList]
  print("[BloomUI] Using existing PlayerGui/BloomUI; copies:",#existingList)
  return keepSingle(existing)
 end

 -- Give Roblox a short window to perform its normal clone before falling back.
 local deadline=os.clock()+1.5
 repeat
  task.wait(.05)
  existingList=collect()
  if #existingList>0 then
   local existing=existingList[#existingList]
   print("[BloomUI] PlayerGui/BloomUI appeared after wait; copies:",#existingList)
   return keepSingle(existing)
  end
 until os.clock()>=deadline

 -- Rojo live-sync can add BloomUI to StarterGui after the player spawned. In
 -- that one case Roblox will not back-fill PlayerGui, so clone exactly once.
 local template=StarterGui:FindFirstChild("BloomUI") or StarterGui:WaitForChild("BloomUI",8)
 if template and template:IsA("ScreenGui") then
  -- Re-check immediately before cloning in case the engine won the race.
  existingList=collect()
  if #existingList>0 then
   local existing=existingList[#existingList]
   return keepSingle(existing)
  end
  local clone=template:Clone()
  clone.Name="BloomUI"
  clone:SetAttribute("BloomRuntimeClone",true)
  clone.Parent=playerGui
  print("[BloomUI] Created one fallback PlayerGui/BloomUI from StarterGui")
  return keepSingle(clone)
 end

 error("[BloomUI] BloomUI is missing from both PlayerGui and StarterGui")
end

function UI:GuardBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")
 self.Gui:SetAttribute("BloomAuthoritative",true)
 local function clean(child)
  if child==self.Gui or not child:IsA("ScreenGui") then return end
  if child.Name=="BloomUI" then
   warn("[BloomUI] Destroying late duplicate HUD:",child:GetFullName())
   child:Destroy()
   return
  end
  local legacy=looksLikeLegacyRoulette(child)
  if not legacy then
   for _,item in ipairs(child:GetDescendants()) do
    if looksLikeLegacyRoulette(item) then legacy=true break end
   end
  end
  if legacy then
   warn("[BloomUI] Destroying late legacy roulette GUI:",child:GetFullName())
   child:Destroy()
  end
 end
 for _,child in ipairs(playerGui:GetChildren()) do clean(child) end
 self.GuiGuardConnection=playerGui.ChildAdded:Connect(function(child)
  task.defer(function()
   if child.Parent==playerGui and self.Gui and self.Gui.Parent==playerGui then clean(child) end
  end)
 end)
end

function UI:ApplyState(payload,source)
 if type(payload)~="table" or type(payload.Profile)~="table" then
  warn("[BloomUI] Ignoring invalid state payload from",source or "unknown")
  return false
 end
 local firstState=self.State==nil
 if not firstState and payload.Revision~=nil and self.State.Revision==payload.Revision then return false end
 self.State=payload
 if firstState then
  self.ObjectiveCard.Visible=true
  self.CurrencyHUD.Visible=true
  self.Dock.Visible=true
 end
 if not self.RouletteLanding then self:BuildRouletteVisualPool(true) end
 self:Render()
 if self.Menu and not self.WorkshopPanDragging then self:RenderMenu() end
 if firstState then print("[BloomUI] State applied:",source or "Event") end
 return true
end

function UI:Start()
 print("[BloomUI] Starting client build:",CLIENT_BUILD)
 self.Player:SetAttribute("BloomClientReady",false)
 self.Player:GetAttributeChangedSignal("BloomProfileState"):Connect(function()
  local status=self.Player:GetAttribute("BloomProfileState")
  if status then print("[BloomUI] Profile state attribute:",status) end
 end)
 local remotes=RS:WaitForChild("BloomRemotes")
 self.Request=remotes:WaitForChild("Request")
 self.StateRequest=remotes:WaitForChild("StateRequest")
 local event=remotes:WaitForChild("Event")
 self.Gui=self:ResolveBloomGui()
 self:GuardBloomGui()
 self.SafeRoot=self.Gui:WaitForChild("SafeRoot",10)
 if not self.SafeRoot then error("[BloomUI] BloomUI exists, but SafeRoot is missing") end
 self:BindStaticUI()

 self.Rewards=require(script.Parent.RewardPresentationController)
 self.Rewards:Init(self)
 self.Activities=require(script.Parent.ActivityController)
 self.Activities:Init(self)
 self.Bees=require(script.Parent.PollinatorController)
 self.Bees:Init(self)
 self.GuideController=require(script.Parent.TutorialGuideController)
 self.GuideController:Init(self)
 self.GardenPresentation=require(script.Parent.GardenPresentationController)
 self.GardenPresentation:Init(self)

 event.OnClientEvent:Connect(function(kind,payload)
  if kind=="State" then
   self:ApplyState(payload,"Event")
  elseif kind=="Ack" then
   local relevant=true
   local rollSession=nil
   if payload.Action=="Roll" then
    local requestId=payload.RequestId
    rollSession=requestId and self.RollRequestSessions[requestId] or self.PendingRollSession
    relevant=requestId==nil or requestId==self.PendingRollRequest or self.RollRequestSessions[requestId]~=nil
    if relevant and (requestId==nil or requestId==self.PendingRollRequest) then
     self.Pending=false
     self.PendingRollRequest=nil
     self.PendingRollSession=nil
     self.NextRoll=math.max(self.NextRoll,os.clock()+.2)
     if self.State then self:Render() end
    end
   end
   if relevant and not payload.OK then
    if payload.Action=="Roll" and self.Auto and rollSession==(self.RollSession or 0) then self:SetAutoRolling(false) end
    if not (payload.Action=="Ready" and payload.Reason=="PROFILE_LOADING") then
     self:Toast(payload.Message or payload.Reason or "Action is currently unavailable")
    end
   end
  elseif kind=="TokenCollected" then
   if self.State then
    local volume=self.State.Profile.Settings.TokenSoundVolume
    if volume>0 then
     local sound=Instance.new("Sound")
     sound.SoundId=require(RS.Config.ActivityConfig).TokenSound
     sound.Volume=volume*(self.State.Profile.Settings.ReducedEffects and .5 or 1)
     sound.Parent=self.Gui
     sound:Play()
     game:GetService("Debris"):AddItem(sound,3)
    end
   end
  elseif kind=="Reward" then
   self.NextRoll=os.clock()+payload.Cooldown
   self:ResolveRouletteReward(payload)
  elseif kind=="PlantPicker" then self:Open("Plant",payload)
  elseif kind=="Activities" then self.Activities:Update(payload)
  elseif kind=="OtherTokens" then self.Activities:Others(payload)
  elseif kind=="Bees" then self.Bees:Update(payload)
  elseif kind=="Message" then self:Toast(payload)
  elseif kind=="Open" then task.defer(function() self:Open(payload) end)
  elseif kind=="Trials" then self:Open("Trials",payload)
  elseif kind=="RareFeed" then if self.State and self.State.Profile.Settings.RareFeed then self:Toast(payload.Player.." • "..payload.Name) end
  elseif kind=="Ceremony" then
   if self.State then self.Rewards:Enqueue({Kind="Ceremony",Ceremony=payload.Kind,DisplayName=payload.Text,Rarity=payload.Kind=="Season" and "Mythic" or "Epic",Chance=1}) end
   self:Toast(payload.Text)
   if payload.Kind=="Season" then self:Close() end
  elseif kind=="SeasonPreview" then self.SeasonSecond=false self:Open("Season",payload)
  elseif kind=="SeasonConfirm" then self.SeasonSecond=true self:RenderMenu()
  elseif kind=="Cards" then task.defer(function() self:Open("Cards") end)
  elseif kind=="Replay" then self.ReplayIndex=1 self:Open("Replay") end
 end)
 self.Player:SetAttribute("BloomClientReady",true)
 print("[BloomUI] Client listener ready:",CLIENT_BUILD)

 UIS.InputBegan:Connect(function(input,processed)
  if processed then return end
  if input.KeyCode==Enum.KeyCode.M then self.Dock.Visible=not self.Dock.Visible
  elseif input.KeyCode==Enum.KeyCode.Escape and self.Menu then self:Close() end
 end)

 local cameraConnection=nil
 local function bindCamera()
  if cameraConnection then cameraConnection:Disconnect() cameraConnection=nil end
  local camera=Workspace.CurrentCamera
  if camera then cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:ApplySafeArea() end) end
  task.defer(function() self:ApplySafeArea() end)
 end
 Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
 self.SafeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  local size=self.SafeRoot.AbsoluteSize
  if size.X>100 and size.Y>100 then self:ApplyResponsiveLayout(size.X,size.Y) end
 end)
 bindCamera()

 task.spawn(function()
  local started=os.clock()
  local lastStatus=nil
  local attempts=0
  while self.Gui.Parent and not self.State do
   attempts=attempts+1
   local ok,payload,reason=pcall(function() return self.StateRequest:InvokeServer(self.State and self.State.Revision or nil) end)
   if ok and payload then
    if self:ApplyState(payload,"StateRequest") then
     self:Send("Ready")
     break
    end
   elseif not ok then
    if attempts==1 or attempts%8==0 then warn("[BloomUI] StateRequest failed:",payload) end
   elseif reason and reason~="PROFILE_LOADING" then
    warn("[BloomUI] StateRequest rejected:",reason)
   end
   self:Send("Ready")
   local status=self.Player:GetAttribute("BloomProfileState")
   if status~=lastStatus then
    lastStatus=status
    if status then print("[BloomUI] Profile state:",status) end
    if status=="Active" and self.ObjectiveTitle and self.ObjectiveText then
     self.ObjectiveTitle.Text="SYNCING"
     self.ObjectiveText.Text="Profile loaded. Fetching game state…"
    end
   end
   if os.clock()-started>20 then
    local profileError=self.Player:GetAttribute("BloomProfileError")
    warn("[BloomUI] Still waiting for authoritative state",status,profileError)
    self:Toast(profileError and ("Profile: "..tostring(profileError)) or "Profile state is still syncing…")
    started=os.clock()+9999
   end
   task.wait(.75)
  end
 end)
 task.spawn(function()
  while self.Gui.Parent do
   task.wait(.1)
   for id,item in pairs(self.Activities.Items) do
    if workspace:GetServerTimeNow()>item.Expires then item.Part:Destroy() self.Activities.Items[id]=nil end
   end
   if self.Auto and not self.Pending and not self.RouletteLanding then self:RollNow(true) end
   if self.Pending and os.clock()-self.PendingAt>15 then
    self.Pending=false
    self.Auto=false
    self:StopRouletteAnimation()
    self:Toast("Server response timed out. Auto was turned off.")
    if self.State then self:Render() end
   end
   if self.State then self.GuideController:Update() end
   if self.ToastUntil and os.clock()>self.ToastUntil then self.ToastRoot.Visible=false self.ToastUntil=nil end
  end
 end)
end

return UI
