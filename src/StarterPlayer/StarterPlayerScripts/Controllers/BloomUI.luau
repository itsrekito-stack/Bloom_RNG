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
local R=require(RS.Config.RarityConfig)
local Theme=require(RS.Config.UIThemeConfig)
local RollAudio=require(RS.Config.RollAudioConfig)
local BloomConfig=require(RS.Config.BloomConfig)
local RollPool=require(RS.Config.RollPoolConfig)
local NumberFormatter=require(RS.Shared.NumberFormatter)
local WorkshopEffects=require(RS.Shared.WorkshopEffects)
local InventoryV2=require(script.Parent.InventoryV2Controller)
local GardenEditor=require(script.Parent.GardenEditorController)
local IndexV1=require(script.Parent.IndexController)
local HiveV1=require(script.Parent.HiveController)
local QuestsV2=require(script.Parent.QuestsController)
local SettingsV2=require(script.Parent.SettingsController)

local C=Theme.Colors
local KEY_CODES={} for _,item in ipairs(Enum.KeyCode:GetEnumItems()) do KEY_CODES[item.Name]=item end
local CLIENT_BUILD="bloom-roll-roulette-highlight-v14-2026-09-29"
local WORKSHOP_ZOOM_ACTION="BloomWorkshopZoomCapture"
local UI={Player=Players.LocalPlayer,Pending=false,Auto=false,NextRoll=0,Menu=nil,State=nil,Connections={},RouletteRunning=false,RouletteLanding=false,RouletteGeneration=0,RollSession=0,RollRequestSequence=0,RollRequestSessions={}}

local MENU_RENDERERS={SeedSatchel="InventoryV2",Garden="GardenV1",Hive="HiveV1",Index="IndexV1",Trials="QuestsV2",Settings="SettingsV2"}
local MENU_DOCK_CONTEXT={SeedSatchel=true,Garden=true,Hive=true,Index=true,Workshop=true,Trials=true,Settings=true}
local MENU_REFRESH_ACTIONS={
 Setting="Settings",
 ResetSettings="Settings",
 EquipBee="SeedSatchel",
 UnequipAllBees="SeedSatchel",
 GardenEdit="Garden",
 HiveUpgrade="Hive",
 EquipSynergy="Index",
 IndexViewed="Index",
 Flag="SeedSatchel",
 WorkshopBuy="Workshop",
 Trial="Trials",
}

local MENU_NAMES={
 SeedSatchel="Inventory",
 Garden="Garden",
 Hive="Hive",
 Index="Index",
 Workshop="Workshop",
 Trials="Quests",
 Settings="Settings",
 Season="Season Turn",
 Replay="Tutorial Replay",
 Cards="Season Cards",
}
local MENU_HINTS={
 SeedSatchel="Bees, resources, and keepsakes",
 Garden="Arrange your seven Flower slots and inspect the active Synergy",
 Hive="Level your Hive, spend resources, and earn Workshop Points",
 Index="Discovered Flowers, Bees, Synergies, and Traits",
 Workshop="Permanent upgrades and progression branches",
 Trials="Tasks, progress & rewards",
 Settings="Game & UI preferences",
 Season="Review the changes before confirming",
 Replay="Replay the tutorial without resetting progress",
 Cards="Choose an effect for the new Season",
}
local SETTINGS_NAMES={
 ReducedEffects="Reduced effects",
 ShowOtherPollinators="Show other players' bees",
 HideOtherPlayersTokens="Hide other players' activities",
 RareFeed="Show rare discoveries",
}
local JOURNEY={
 "Get your first bee","Collect a Pollen Spark","Honey delivery","Make a roll","Plant a flower","Fill the Bloom Meter","Make a Bloom Roll","Reach Hive Level 2","Buy a Workshop node","Create a synergy","Unlock the second bee slot","Activate a Bee Trait","Discover 6 flowers","Prepare a Season Turn",
}

function UI:JourneyCount()
 return #JOURNEY
end

function UI:JourneyText(step)
 return JOURNEY[tonumber(step) or 1] or "Keep growing your garden"
end

local PERSISTENT_HOVERS=setmetatable({}, {__mode="k"})
local function hover(button,base,over)
 button.AutoButtonColor=false
 PERSISTENT_HOVERS[button]={Base=base,Over=over,Hovered=false}
 button.MouseEnter:Connect(function()
  if not button.Parent then return end
  local state=PERSISTENT_HOVERS[button]
  if state then state.Hovered=true end
  button:SetAttribute("BloomHovered",true)
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=over}):Play()
 end)
 button.MouseLeave:Connect(function()
  if not button.Parent then return end
  local state=PERSISTENT_HOVERS[button]
  if state then state.Hovered=false end
  button:SetAttribute("BloomHovered",false)
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=base}):Play()
 end)
end

local function refreshPersistentHovers()
 for button,state in pairs(PERSISTENT_HOVERS) do
  if button and button.Parent and state then
   button.BackgroundColor3=state.Hovered and state.Over or state.Base
  end
 end
end

local function compact(v)
 return NumberFormatter.Compact(tonumber(v) or 0)
end

local WORKSHOP_FEATURE_TEXT={
 PityDetails="Shows pity and the guaranteed new discovery",
 RepeatPlant="Replant the last seed",
 GuaranteedAbilityToken="Rare bee abilities always offer an Overcharge token",
 PatternHints="Flower pattern hints",
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
  elseif key=="FlowerGrowthMultiplier" then text="Flower growth ×"..tostring(value)
  elseif key=="LuckMultiplier" then text="Luck ×"..tostring(value)
  elseif key=="PollinatorPowerMultiplier" then text="Bee power ×"..tostring(value)
  elseif key=="PollinatorYieldMultiplier" then text="Bee yield ×"..tostring(value)
  elseif key=="HiveHoneyMultiplier" then text="Hive Honey ×"..tostring(value)
  elseif key=="TokenChance" then text="Ability token chance +"..math.floor((tonumber(value) or 0)*100+.5).."%"
  elseif key=="BeeXP" then text="Bee XP ×"..tostring(value)
  elseif key=="TraitCooldown" then text="Trait cooldown ×"..tostring(value)
  elseif key=="AbilityYield" then text="Ability rewards ×"..tostring(value)
  elseif key=="DustYield" then text="Petal Dust ×"..tostring(value)
  elseif key=="MilestoneCoins" then text="Milestone Coins +"..tostring(value)
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

function UI:MenuTemplate(name)
 local kit=self.StateKits and self.Menu and self.StateKits:FindFirstChild(self.Menu.."Kit")
 local template=kit and kit:FindFirstChild(name)
 if template then return template end
 return self.Templates and self.Templates:FindFirstChild(name)
end

function UI:Label(parent,text,height)
 local template=self:MenuTemplate("LabelTemplate")
 if not template or not template:IsA("TextLabel") then error("[BloomUI] Authored LabelTemplate missing") end
 local label=template:Clone()
 label.Name="Label"
 label.Visible=true
 label.Parent=parent
 label.Text=text or ""
 label.Size=UDim2.new(1,0,0,height or 30)
 label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 self.MenuLayoutOrder=(self.MenuLayoutOrder or 0)+1
 label.LayoutOrder=self.MenuLayoutOrder
 return label
end

function UI:Section(parent,text)
 local template=self:MenuTemplate("SectionTemplate")
 if not template or not template:IsA("TextLabel") then error("[BloomUI] Authored SectionTemplate missing") end
 local label=template:Clone()
 label.Name="Section"
 label.Visible=true
 label.Parent=parent
 label.Text=string.upper(text or "")
 label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 self.MenuLayoutOrder=(self.MenuLayoutOrder or 0)+1
 label.LayoutOrder=self.MenuLayoutOrder
 return label
end

function UI:Button(parent,text,fn,icon)
 local template=self:MenuTemplate("ButtonTemplate")
 if not template or not template:IsA("TextButton") then error("[BloomUI] Authored ButtonTemplate missing") end
 local button=template:Clone()
 button.Name="Button"
 button.Visible=true
 button.Parent=parent
 button.Text=text or ""
 button.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 self.MenuLayoutOrder=(self.MenuLayoutOrder or 0)+1
 button.LayoutOrder=self.MenuLayoutOrder
 local img=button:FindFirstChild("Icon")
 local padding=button:FindFirstChild("Padding") or button:FindFirstChildOfClass("UIPadding")
 if img and img:IsA("ImageLabel") then
  img.Visible=icon~=nil and icon~=""
  img.Image=icon or ""
  img.ZIndex=button.ZIndex+1
 end
 button.TextXAlignment=(icon and icon~="") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
 if padding then padding.PaddingLeft=UDim.new(0,(icon and icon~="") and 36 or 10) end
 hover(button,C.PanelRaised,C.PanelHover)
 button.Activated:Connect(fn)
 return button
end

function UI:Send(action,a,b,c)
 self.Request:FireServer(action,a,b,c)
end

local LEGACY_ROULETTE_NAMES={
 Roulette=true,RouletteGui=true,RouletteGUI=true,RouletteFrame=true,RoulettePanel=true,RouletteContainer=true,
 Reel=true,ReelFrame=true,SpinFrame=true,SpinGui=true,OldRoulette=true,OldRollUI=true,
 TutorialRollButton=true,AutoRollButton=true,RollGui=true,RollGUI=true,RollUI=true,RollFrame=true,RollPanel=true,RollContainer=true,
}

local function hasLegacyReelToken(lower)
 return lower=="reel"
  or string.sub(lower,1,4)=="reel"
  or string.sub(lower,-4)=="reel"
  or string.find(lower,"_reel",1,true)~=nil
  or string.find(lower,"reel_",1,true)~=nil
end

local function looksLikeLegacyRoulette(instance)
 local name=instance.Name
 if LEGACY_ROULETTE_NAMES[name] then return true end
 local lower=string.lower(name)
 return string.find(lower,"roulette",1,true)~=nil
  or hasLegacyReelToken(lower)
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

function UI:IsIndexExclusive()
 return self.IndexFocus==true and self.Menu=="Index"
end

function UI:IsFullscreenExclusive()
 return self:IsWorkshopExclusive() or self:IsIndexExclusive()
end

function UI:WorkshopHUDObjects()
 return {
  self.ObjectiveCard,self.CurrencyHUD,self.QuestTracker,self.RollHUD,self.Roll,
  self.Guide,self.ToastRoot,self.Reveal,
 }
end

function UI:CaptureWorkshopHUDVisibility()
 if self.WorkshopHUDVisibility then return end
 local snapshot={}
 for _,gui in ipairs(self:WorkshopHUDObjects()) do
  if gui and gui:IsA("GuiObject") then snapshot[gui]=gui.Visible end
 end
 self.WorkshopHUDVisibility=snapshot
end

function UI:RestoreWorkshopHUDVisibility()
 local snapshot=self.WorkshopHUDVisibility
 self.WorkshopHUDVisibility=nil
 if not snapshot then return end
 for gui,visible in pairs(snapshot) do
  if gui and gui.Parent and gui:IsA("GuiObject") then gui.Visible=visible end
 end
end

function UI:ApplyWorkshopFocusVisibility()
 local exclusive=self:IsWorkshopExclusive()
 if self.BoostHUD then self.BoostHUD:SetSuppressed(exclusive) end
 if self.TraitHUD then self.TraitHUD:SetSuppressed(exclusive) end
 if not exclusive then return end
 for _,gui in ipairs(self:WorkshopHUDObjects()) do
  if gui and gui:IsA("GuiObject") then gui.Visible=false end
 end
end

function UI:SetWorkshopFocus(active)
 active=active==true
 if active==self.WorkshopFocus then
  self:ApplyWorkshopFocusVisibility()
  return
 end
 if active then
  self:CaptureWorkshopHUDVisibility()
  self.WorkshopFocus=true
  self.ToastUntil=nil
  self:ApplyWorkshopFocusVisibility()
 else
  self.WorkshopFocus=false
  self:RestoreWorkshopHUDVisibility()
  if self.BoostHUD then self.BoostHUD:SetSuppressed(false) end
  if self.TraitHUD then self.TraitHUD:SetSuppressed(false) end
  if self.State then self:Render() end
 end
end

function UI:CaptureIndexHUDVisibility()
 if self.IndexHUDVisibility then return end
 local snapshot={}
 for _,gui in ipairs(self:WorkshopHUDObjects()) do
  if gui and gui:IsA("GuiObject") then snapshot[gui]=gui.Visible end
 end
 self.IndexHUDVisibility=snapshot
end

function UI:RestoreIndexHUDVisibility()
 local snapshot=self.IndexHUDVisibility
 self.IndexHUDVisibility=nil
 if not snapshot then return end
 for gui,visible in pairs(snapshot) do
  if gui and gui.Parent and gui:IsA("GuiObject") then gui.Visible=visible end
 end
end

function UI:ApplyIndexFocusVisibility()
 local exclusive=self:IsIndexExclusive()
 if self.BoostHUD then self.BoostHUD:SetSuppressed(exclusive or self:IsWorkshopExclusive()) end
 if self.TraitHUD then self.TraitHUD:SetSuppressed(exclusive or self:IsWorkshopExclusive()) end
 if not exclusive then return end
 for _,gui in ipairs(self:WorkshopHUDObjects()) do
  if gui and gui:IsA("GuiObject") then gui.Visible=false end
 end
end

function UI:SetIndexFocus(active)
 active=active==true
 if active==self.IndexFocus then
  self:ApplyIndexFocusVisibility()
  return
 end
 if active then
  self:CaptureIndexHUDVisibility()
  self.IndexFocus=true
  self.ToastUntil=nil
  self:ApplyIndexFocusVisibility()
 else
  self.IndexFocus=false
  self:RestoreIndexHUDVisibility()
  if self.BoostHUD then self.BoostHUD:SetSuppressed(self:IsWorkshopExclusive()) end
  if self.TraitHUD then self.TraitHUD:SetSuppressed(self:IsWorkshopExclusive()) end
  if self.State then self:Render() end
 end
end

function UI:Toast(text)
 if self:IsFullscreenExclusive() then return end
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

local function workshopStructure(shell)
 if not shell or not shell:IsA("GuiObject") then return nil end
 local body=shell:FindFirstChild("WorkshopBody")
 local treePanel=body and body:FindFirstChild("TreePanel")
 local canvas=treePanel and treePanel:FindFirstChild("TreeCanvas")
 local panMap=canvas and canvas:FindFirstChild("PanMap")
 local tooltip=body and body:FindFirstChild("NodeTooltip")
 local currencyBar=body and body:FindFirstChild("WorkshopCurrencyBar")
 if not body or not treePanel or not canvas or not panMap or not tooltip or not currencyBar then return nil end
 return {
  Body=body,
  TreePanel=treePanel,
  Canvas=canvas,
  PanMap=panMap,
  Tooltip=tooltip,
  CurrencyBar=currencyBar,
 }
end

function UI:CenterWorkshopCanvas(canvas,panMap,zoom)
 if not canvas or not canvas.Parent or not panMap or not panMap.Parent then return false end
 local core=panMap:FindFirstChild("Node_CORE")
 if not core or not core:IsA("GuiObject") then return false end
 local mapWidth=panMap.Size.X.Scale*canvas.CanvasSize.X.Offset+panMap.Size.X.Offset
 local mapHeight=panMap.Size.Y.Scale*canvas.CanvasSize.Y.Offset+panMap.Size.Y.Offset
 if mapWidth<=0 then mapWidth=2200 end
 if mapHeight<=0 then mapHeight=1700 end
 local nodeWidth=core.Size.X.Scale*mapWidth+core.Size.X.Offset
 local nodeHeight=core.Size.Y.Scale*mapHeight+core.Size.Y.Offset
 local center=Vector2.new(
  core.Position.X.Scale*mapWidth+core.Position.X.Offset+nodeWidth*.5,
  core.Position.Y.Scale*mapHeight+core.Position.Y.Offset+nodeHeight*.5
 )*(tonumber(zoom) or 1)
 local viewport=canvas.AbsoluteSize
 if viewport.X<1 or viewport.Y<1 then return false end
 local target=self:ClampWorkshopCanvasPosition(canvas,center-viewport*.5)
 canvas.CanvasPosition=target
 self.WorkshopCanvasPosition=target
 return true
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
  if not zoomScale or not zoomScale:IsA("UIScale") then error("[BloomUI] Workshop PanMap/WorkshopZoomScale missing") end
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
 if self.WorkshopCanvasPosition then
  local saved=self:ClampWorkshopCanvasPosition(canvas,self.WorkshopCanvasPosition)
  canvas.CanvasPosition=saved
  self.WorkshopCanvasPosition=saved
 else
  if not self:CenterWorkshopCanvas(canvas,nodes,zoom) then
   task.defer(function()
    if self.Menu=="Workshop" and canvas.Parent then self:CenterWorkshopCanvas(canvas,nodes,zoom) end
   end)
  end
 end

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

local function relativeGuiPath(instance,root)
 local parts={}
 local current=instance
 while current and current~=root do
  table.insert(parts,1,current.Name)
  current=current.Parent
 end
 return table.concat(parts,"/")
end

function UI:CapturePanelInteractionState()
 local state={Scroll={}}
 local function capture(instance)
  if instance:IsA("ScrollingFrame") then
   local key=instance==self.Content and "__CONTENT__" or relativeGuiPath(instance,self.Content)
   state.Scroll[key]=instance.CanvasPosition
  end
 end
 capture(self.Content)
 for _,instance in ipairs(self.Content:GetDescendants()) do capture(instance) end
 return state
end

function UI:RestorePanelInteractionState(state)
 if not state or not self.Content or not self.Content.Parent then return end
 local lookup={__CONTENT__=self.Content}
 for _,instance in ipairs(self.Content:GetDescendants()) do
  if instance:IsA("ScrollingFrame") then
   lookup[relativeGuiPath(instance,self.Content)]=instance
  end
 end
 for key,position in pairs(state.Scroll or {}) do
  local frame=lookup[key]
  if frame and frame:IsA("ScrollingFrame") then frame.CanvasPosition=position end
 end
end

function UI:ClearPanel()
 self:DisconnectWorkshopPan()
 SettingsV2.Cleanup()
 self.WorkshopRuntime=nil
 for _,x in ipairs(self.Content:GetChildren()) do
  if not x:IsA("UIListLayout") and not x:IsA("UIPadding") then x:Destroy() end
 end
end

function UI:GetMenuScale()
 if self.Menu=="Workshop" or self.Menu=="Index" then return 1 end
 local settings=self.State and self.State.Profile and self.State.Profile.Settings
 return math.clamp(tonumber(settings and settings.UIScale) or 1,.8,1.15)
end

function UI:SetPanelVisible(visible)
 self.Panel.Visible=visible
 self.ModalShade.Visible=visible
 if visible then
  local scale=self:GetMenuScale()
  self.PanelScale.Scale=scale*.96
  TweenService:Create(self.PanelScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=scale}):Play()
 end
end

function UI:Close()
 local closingMenu=self.Menu

 self:DisconnectWorkshopPan()
 self.ReplayIndex=nil
 local wasWorkshop=closingMenu=="Workshop"
 local wasIndex=closingMenu=="Index"
 local serverMenuOpen=self.MenuServerOpen==true
 if wasWorkshop then
  self.WorkshopRuntime=nil
  self.WorkshopCanvasPosition=nil
  self.WorkshopZoom=nil
 end
 if closingMenu=="Season" then self:Send("SeasonCancel") end
 self.Menu=nil
 self.MenuRenderer=nil
 self.MenuArg=nil
 self.MenuRefreshRequested=false
 self.MenuServerOpen=false
 self:SetPanelVisible(false)
 if wasWorkshop then self:SetWorkshopFocus(false) end
 if wasIndex then self:SetIndexFocus(false) end
 if serverMenuOpen then self:Send("Menu",false) end
 self:RefreshMenuDock()
 self:RefreshRollHUDVisibility()
end

function UI:Open(name,arg,options)
 if self:IsWorkshopExclusive() and name~="Workshop" then return end
 if self:IsIndexExclusive() and name~="Index" then return end
 if self.Menu==name and arg==nil then self:Close() return end
 if not self.State then return end
 if name~="Settings" and name~="Season" and name~="Cards" and name~="Replay" and name~="Index" and name~="Hive" and not self.State.Profile.Tutorial.FeatureUnlocks[name] then return end

 local silentMenu=type(options)=="table" and options.SilentMenu==true
 if silentMenu and self.MenuServerOpen then
  self:Send("Menu",false)
  self.MenuServerOpen=false
 end

 self.Menu=name
 self.MenuRenderer=MENU_RENDERERS[name] or name
 self.MenuArg=arg
 self.MenuRefreshRequested=false
 self:RefreshRollHUDVisibility()
 self:SetPanelVisible(true)
 self:RefreshMenuDock()
 if name=="Workshop" then self:SetWorkshopFocus(true) end
 if name=="Index" then self:SetIndexFocus(true) end
 self:RenderMenu()

 local announcesMenu=name~="Season" and name~="Cards" and name~="Replay" and name~="Index"
 if announcesMenu and not silentMenu then
  self:Send("Menu",name)
  self.MenuServerOpen=true
 elseif silentMenu then
  self.MenuServerOpen=false
 end
 self:ApplyWorkshopFocusVisibility()
 self:ApplyIndexFocusVisibility()
end

function UI:OpenGardenMenu(slot)
 slot=tonumber(slot)
 if not slot or slot%1~=0 or slot<1 then
  self:Toast("This garden slot is unavailable.")
  return
 end
 self.GardenEditorState=self.GardenEditorState or {SelectedFlowerId=nil,SelectedSlot=nil}
 self.GardenEditorState.SelectedSlot=slot
 local p=self.State and self.State.Profile
 if not self.GardenEditorState.SelectedFlowerId and p and WorkshopEffects.Feature(p,"GARDEN_3","RepeatPlant") and self.LastSeed then
  self.GardenEditorState.SelectedFlowerId=self.LastSeed
 end
 self:Open("Garden",{Slot=slot})
end

function UI:RenderMenu(preserveInteraction)
 if not self.Menu or not self.State then return end
 local interactionState=preserveInteraction and self:CapturePanelInteractionState() or nil
 local p=self.State.Profile
 local ui=self.State.UI or {}
 local name=self.Menu
 local renderer=self.MenuRenderer or MENU_RENDERERS[name] or name
 self.MenuLayoutOrder=0
 local workshop=renderer=="Workshop"
 local index=renderer=="IndexV1"
 local fullscreen=workshop or index
 local reuseWorkshop=workshop and self.WorkshopRuntime and self.WorkshopRuntime.Parent==self.Content
 if not reuseWorkshop then self:ClearPanel() end
 self.PanelTitle.Text=MENU_NAMES[name] or name
 self.PanelSubtitle.Text=MENU_HINTS[name] or ""

 if self.PanelHeader then
  self.PanelHeader.Size=fullscreen and UDim2.new(1,0,0,0) or UDim2.new(1,0,0,54)
  self.PanelHeader.BackgroundTransparency=fullscreen and 1 or .05
  self.PanelHeader.ZIndex=fullscreen and 118 or 51
 end
 self.PanelTitle.Visible=not fullscreen
 self.PanelSubtitle.Visible=not fullscreen
 if self.PanelHeaderIcon then
  self.PanelHeaderIcon.Visible=not fullscreen
  if not fullscreen then
   local kit=self.StateKits and self.StateKits:FindFirstChild(name.."Kit")
   local kitIcon=kit and kit:FindFirstChild("KitHeader") and kit.KitHeader:FindFirstChild("StateIcon")
   local headerImage=(kitIcon and kitIcon:IsA("ImageLabel") and kitIcon.Image) or Icons.Get("Menus",name)
   if headerImage=="" then
    if name=="Season" or name=="Cards" then headerImage=Icons.Get("System","Flower")
    elseif name=="Replay" then headerImage=Icons.Get("System","Tutorial")
    else headerImage=Icons.Get("System","Info") end
   end
   self.PanelHeaderIcon.Image=headerImage
  end
 end
 if self.PanelHeaderAccent then self.PanelHeaderAccent.Visible=not fullscreen end
 if self.PanelClose then
  self.PanelClose.Visible=true
  self.PanelClose.Position=fullscreen and UDim2.new(1,-48,0,12) or UDim2.new(1,-44,0,10)
  self.PanelClose.ZIndex=fullscreen and 120 or 53
 end

 -- Bloom UI Studio previews Inventory v2 on a 1220x660 MainPanel.
 -- Mirror that authored canvas at runtime instead of inheriting the generic
 -- 600x420 menu size. Narrower desktop screens are capped to the viewport.
 if not fullscreen then
  local safeSize=self.SafeRoot and self.SafeRoot.AbsoluteSize or Vector2.new(1366,768)
  local safeW=safeSize.X>100 and safeSize.X or 1366
  local safeH=safeSize.Y>100 and safeSize.Y or 768

  self.Panel.AnchorPoint=Vector2.new(.5,.5)
  self.Panel.Position=UDim2.new(.5,0,.51,0)

  if self.IsMobileLayout then
   self.Panel.Size=UDim2.fromOffset(math.max(300,safeW-16),math.max(300,safeH-108))
  elseif renderer=="InventoryV2" then
   self.Panel.Size=UDim2.fromOffset(math.min(1220,math.max(700,safeW-24)),math.min(660,math.max(500,safeH-24)))
  elseif renderer=="GardenV1" then
   self.Panel.Size=UDim2.fromOffset(math.min(1040,math.max(760,safeW-36)),math.min(620,math.max(500,safeH-40)))
  elseif renderer=="HiveV1" then
   self.Panel.Size=UDim2.fromOffset(math.min(920,math.max(720,safeW-56)),math.min(590,math.max(500,safeH-54)))
  elseif renderer=="SettingsV2" then
   self.Panel.Size=UDim2.fromOffset(math.min(920,math.max(720,safeW-64)),math.min(570,math.max(500,safeH-72)))
  elseif renderer=="QuestsV2" then
   self.Panel.Size=UDim2.fromOffset(math.min(980,math.max(760,safeW-48)),math.min(560,math.max(500,safeH-64)))
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

 if not fullscreen and not preserveInteraction then self.Content.CanvasPosition=Vector2.new() end

 if fullscreen then
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
 end

 -- Geometry and renderer dispatch must stay separate so Workshop can render.
 if renderer=="InventoryV2" then
  -- SeedSatchel is the persistent feature/unlock id; InventoryV2 is its only
  -- live renderer. Keep the outer Content fixed because ItemGrid scrolls itself.
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  InventoryV2.Render(self,p,ui)

 elseif renderer=="GardenV1" then
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  GardenEditor.Render(self,p,ui)

 elseif renderer=="HiveV1" then
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  HiveV1.Render(self,p,ui)

 elseif renderer=="IndexV1" then
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  IndexV1.Render(self,p,ui)

 elseif renderer=="SettingsV2" then
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  SettingsV2.Render(self,p,ui)

 elseif renderer=="QuestsV2" then
  self.Content.AutomaticCanvasSize=Enum.AutomaticSize.None
  self.Content.CanvasSize=UDim2.fromOffset(0,0)
  self.Content.ScrollingEnabled=false
  self.Content.ScrollBarThickness=0
  QuestsV2.Render(self,p,ui)

 elseif renderer=="Workshop" then
  local shell=self.WorkshopRuntime
  local structure=workshopStructure(shell)
  local firstWorkshopBuild=not structure or shell.Parent~=self.Content
  local template=self.Panel:FindFirstChild("WorkshopTemplate")
  local templateStructure=workshopStructure(template)
  if not templateStructure then
   error("[BloomUI] Authored WorkshopTemplate is stale or incomplete. AI SYNC must provide NodeTooltip, WorkshopCurrencyBar and the tree structure.")
  end

  if firstWorkshopBuild then
   if shell and shell.Parent then shell:Destroy() end
   shell=template:Clone()
   shell.Name="WorkshopRuntime"
   shell.Visible=true
   shell.Parent=self.Content
   shell.Size=UDim2.fromScale(1,1)
   shell.Position=UDim2.new()
   shell.LayoutOrder=1
   self.WorkshopRuntime=shell
   self.WorkshopZoomLabel=nil
   structure=workshopStructure(shell)
   if not structure then error("[BloomUI] WorkshopRuntime clone failed authored structure validation") end
  end

   local workshopUI=ui.Workshop
   local body=structure.Body
   local treePanel=structure.TreePanel
   local canvas=structure.Canvas
   local panMap=structure.PanMap
   panMap.Position=UDim2.fromOffset(0,0)

   local nodes=canvas:FindFirstChild("Nodes") or panMap
   local links=canvas:FindFirstChild("Connections") or panMap
   if not nodes or not links then error("[BloomUI] Workshop tree containers missing") end

   local tooltip=structure.Tooltip
   if firstWorkshopBuild then tooltip.Visible=false end
   tooltip.Active=false
   local tooltipTitle=tooltip:FindFirstChild("Title")
   local tooltipBranch=tooltip:FindFirstChild("Branch")
   local tooltipEffect=tooltip:FindFirstChild("Effect")
   local tooltipCost=tooltip:FindFirstChild("Cost")
   local tooltipHint=tooltip:FindFirstChild("Hint")
   local tooltipAccent=tooltip:FindFirstChild("Accent")
   if not tooltipTitle or not tooltipBranch or not tooltipEffect or not tooltipCost or not tooltipHint or not tooltipAccent then
    error("[BloomUI] Workshop NodeTooltip authored fields are incomplete")
   end
   local tooltipStroke=tooltip:FindFirstChildOfClass("UIStroke")

   local currencyBar=structure.CurrencyBar
   local function setWorkshopCurrency(name,value,image)
    local pill=currencyBar:FindFirstChild(name)
    local valueLabel=pill and pill:FindFirstChild("Value")
    local icon=pill and pill:FindFirstChild("Icon")
    if not pill or not valueLabel or not valueLabel:IsA("TextLabel") or not icon or not icon:IsA("ImageLabel") then
     error("[BloomUI] Workshop currency pill incomplete: "..tostring(name))
    end
    valueLabel.Text=compact(value)
    icon.Image=image or ""
   end
   local pointIcon=Icons.Get("Menus","Workshop")
   if pointIcon=="" then pointIcon=Icons.Get("System","Upgrade") end
   local coinIcon=Icons.GetCurrencyIcon("Coins")
   local dustIcon=Icons.GetCurrencyIcon("PetalDust")
   local nectarIcon=Icons.GetCurrencyIcon("AncientNectar")
   if nectarIcon=="" then nectarIcon=Icons.Get("System","Flower") end
   setWorkshopCurrency("WorkshopPoints",p.WorkshopV5.Points,pointIcon)
   setWorkshopCurrency("WorkshopCoins",p.Currencies.Coins,coinIcon)
   setWorkshopCurrency("WorkshopPetalDust",p.Currencies.PetalDust,dustIcon)
   setWorkshopCurrency("WorkshopAncientNectar",p.Currencies.AncientNectar,nectarIcon)

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

     if not nodeScale or not nodeScale:IsA("UIScale") then error("[BloomUI] Workshop node missing authored NodeScale: "..id) end
     if not selectionGlow or not selectionGlow:IsA("ImageLabel") then error("[BloomUI] Workshop node missing authored SelectionGlow: "..id) end

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
    self:BindWorkshopPan(canvas,nodes)
   end
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
 if interactionState then
  task.defer(function()
   if self.Menu==name and self.Content and self.Content.Parent then self:RestorePanelInteractionState(interactionState) end
  end)
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

function UI:TutorialRollState()
 local p=self.State and self.State.Profile
 local tutorial=p and p.Tutorial
 if not tutorial or tutorial.Skipped==true then return false,true,nil end
 local step=T.Steps[tonumber(tutorial.Step) or 1]
 if not step then return false,true,nil end
 local allowed=step.Id=="FirstFlowerRoll" or step.Id=="FirstBeeRoll" or step.Id=="BloomRoll"
 return true,allowed,step
end

function UI:RefreshRollHUDVisibility()
 if not self.State or not self.State.Profile or not self.Roll or not self.RollHUD or not self.RouletteViewport then return false end
 local p=self.State.Profile
 local rollUnlocked=p.Tutorial.FeatureUnlocks.Roll==true or p.Tutorial.Skipped==true
 local tutorialActive,tutorialAllowed=self:TutorialRollState()
 local controlsVisible=rollUnlocked and self.Menu==nil
 local enabled=controlsVisible and (not tutorialActive or tutorialAllowed) and not self.Pending

 self.RollHUD.Visible=controlsVisible
 self.Roll.Visible=controlsVisible
 self.Roll.Active=enabled
 self.Roll.Selectable=enabled
 if self.RollIcon then
  self.RollIcon.ImageColor3=enabled and C.White or C.Muted
  self.RollIcon.ImageTransparency=enabled and 0 or .48
 end
 if self.RollTutorialLock then
  self.RollTutorialLock.Visible=controlsVisible and tutorialActive and not tutorialAllowed
  self.RollTutorialLock.Text="COMPLETE THE TUTORIAL TO ROLL AGAIN"
 end

 local spinning=self.RouletteRunning or self.RouletteLanding
 self.RouletteViewport.Visible=rollUnlocked and (self.RouletteLanding or ((not tutorialActive or tutorialAllowed) and (self.Auto or spinning)))
 return rollUnlocked
end

function UI:ApplyMenuDockLayout(expanded)
 if not self.Dock then return end
 expanded=expanded==true
 self.InventoryDockExpanded=expanded
 local dockScale=self.Dock:FindFirstChild("UserScale")
 if self.IsMobileLayout then
  local safeSize=self.SafeRoot and self.SafeRoot.AbsoluteSize or Vector2.new(700,700)
  local width=math.max(320,safeSize.X)
  local scale=math.min(1,math.max(.52,(width-16)/579))
  if dockScale then dockScale.Scale=scale end
  self.Dock.AnchorPoint=Vector2.new(.5,1)
  self.Dock.Position=UDim2.new(.5,expanded and -84 or math.floor(151*scale+.5),1,expanded and -14 or -94)
 else
  if dockScale then dockScale.Scale=1 end
  self.Dock.AnchorPoint=Vector2.new(.5,1)
  self.Dock.Position=UDim2.new(.5,expanded and -84 or 151,1,-14)
 end
end

function UI:OpenDockMenu(name)
 if not self.State then return end
 if self.Menu and self.Menu~=name then
  self:Close()
 end
 self:Open(name)
end

function UI:RefreshMenuDock()
 if not self.Dock or not self.State or not self.State.Profile then return end
 local p=self.State.Profile
 local inventoryUnlocked=p.Tutorial.FeatureUnlocks.SeedSatchel==true
 local menuDockOpen=MENU_DOCK_CONTEXT[self.Menu]==true
 self.Dock.Visible=inventoryUnlocked
 self:ApplyMenuDockLayout(menuDockOpen)

 local dockUnlocked={
  SeedSatchel=inventoryUnlocked,
  Garden=p.Tutorial.FeatureUnlocks.Garden==true,
  Hive=inventoryUnlocked,
  Index=inventoryUnlocked,
  Workshop=p.Tutorial.FeatureUnlocks.Workshop==true,
  Trials=p.Tutorial.FeatureUnlocks.Trials==true,
  Settings=inventoryUnlocked,
 }

 for name,b in pairs(self.DockButtons or {}) do
  local enabled=dockUnlocked[name]==true
  local visible=name=="SeedSatchel" or menuDockOpen
  b.Visible=inventoryUnlocked and visible
  b.Active=enabled
  b.Selectable=enabled
  b:SetAttribute("BloomDockEnabled",enabled)
  b.BackgroundTransparency=1

  local stroke=b:FindFirstChildOfClass("UIStroke")
  if stroke then stroke.Transparency=1 end

  local icon=b:FindFirstChild("Icon")
  local hovered=b:GetAttribute("BloomDockHovered")==true
  if icon and icon:IsA("ImageLabel") then
   local selected=self.Menu==name
   icon.ImageTransparency=enabled and 0 or .58
   icon.ImageColor3=enabled and ((hovered or selected) and C.Blue or C.White) or C.Muted
  end

  local tip=self.DockTooltips and self.DockTooltips[name]
  if tip then
   tip.Text=(MENU_NAMES[name] or name)..(enabled and "" or " • LOCKED")
   tip.Visible=b.Visible and hovered
  end
 end
end

function UI:RenderQuestTracker()
 if not self.QuestTracker or not self.State then return end
 local p=self.State.Profile
 local visible=not self.IsMobileLayout and not self:IsFullscreenExclusive() and p.Tutorial.Step>#T.Steps
 self.QuestTracker.Visible=visible
 if not visible then return end

 local ui=self.State.UI or {}
 local hive=ui.QuestTracker and ui.QuestTracker.Hive or {}
 local function setRow(row,kicker,text,progress,color)
  if not row then return end
  local kickerLabel=row:FindFirstChild("Kicker")
  local textLabel=row:FindFirstChild("Text")
  local progressLabel=row:FindFirstChild("Progress")
  local accent=row:FindFirstChild("Accent")
  if kickerLabel and kickerLabel:IsA("TextLabel") then kickerLabel.Text=kicker end
  if textLabel and textLabel:IsA("TextLabel") then textLabel.Text=text end
  if progressLabel and progressLabel:IsA("TextLabel") then progressLabel.Text=progress end
  if accent and accent:IsA("Frame") then accent.BackgroundColor3=color end
 end

 local hiveCurrent=math.max(0,tonumber(hive.Current) or 0)
 local hiveTarget=math.max(1,tonumber(hive.Target) or 1)
 local hiveRow=self.QuestRows[1]
 local hideHive=hive.Complete==true or hive.Title=="Hive MAX"
 hiveRow.Visible=not hideHive
 if not hideHive then
  setRow(
   hiveRow,
   "HIVE QUEST  •  LV."..tostring(hive.Level or (p.Hive.Level+1)),
   tostring(hive.Text or "Grow your Hive"),
   compact(hiveCurrent).." / "..compact(hiveTarget),
   C.Honey
  )
 end

 local journeyStep=math.max(1,tonumber(p.Quests.JourneyStep) or 1)
 local journeyDone=journeyStep>#JOURNEY
 local journeyRow=self.QuestRows[2]
 journeyRow.Visible=not journeyDone
 if not journeyDone then
  setRow(
   journeyRow,
   "JOURNEY  •  STEP "..tostring(math.min(journeyStep,#JOURNEY)),
   self:JourneyText(journeyStep),
   tostring(journeyStep).." / "..tostring(#JOURNEY),
   C.Blue
  )
 end

 local bloomMax=math.max(1,tonumber(BloomConfig.BloomMax) or 100)
 local bloomCharge=math.clamp(tonumber(p.RollState.BloomCharge) or 0,0,bloomMax)
 local bloomReady=p.RollState.SpecialRollReady==true
 local bloomRow=self.QuestRows[3]
 bloomRow.Visible=true
 setRow(
  bloomRow,
  "BLOOM QUEST",
  bloomReady and "Use your Bloom Roll" or "Fill the Bloom Meter",
  bloomReady and "ROLL READY" or (tostring(math.floor(bloomCharge+.5)).." / "..tostring(bloomMax)),
  bloomReady and C.Gold or C.Nectar
 )

 local visibleCount=0
 for _,row in ipairs(self.QuestRows) do
  if row.Visible then
   row.Position=UDim2.fromOffset(8,22+visibleCount*43)
   visibleCount+=1
  end
 end
 self.QuestTracker.Size=UDim2.fromOffset(250,26+visibleCount*43)
end

function UI:ApplyResponsiveLayout(width,height)
 -- Desktop layout is authored in StarterGui. Do not overwrite positions/sizes here,
 -- so designers can move every HUD block directly in Studio.
 self.IsMobileLayout=width<700
 if width>=700 then
  self:ApplyMenuDockLayout(self.InventoryDockExpanded==true)
  if self.State then self:RenderQuestTracker() end
  return
 end
 if self.QuestTracker then self.QuestTracker.Visible=false end

 -- Small-screen safety only. These adjustments intentionally touch as little as possible.
 self.ObjectiveCard.Size=UDim2.fromOffset(math.max(280,width-24),66)
 self.CurrencyHUD.Position=UDim2.fromOffset(10,208)
 self:ApplyMenuDockLayout(self.InventoryDockExpanded==true)
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
 if self.BoostHUD then self.BoostHUD:ApplyResponsiveLayout(width) end
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
  self.ObjectiveText.Text=self:JourneyText(p.Quests.JourneyStep)
  self.ObjectiveProgress.Visible=false
  if self.JourneyGuideController then self.JourneyGuideController:RenderObjective() end
 end

 self.CurrencyRows.Coins.Value.Text=compact(p.Currencies.Coins)
 self.CurrencyRows.Honey.Value.Text=compact(p.Hive.Honey)
 self.CurrencyRows.Hive.Value.Text="Level "..tostring(p.Hive.Level)
 self.CurrencyRows.PetalDust.Value.Text=compact(p.Currencies.PetalDust)
 self.CurrencyRows.PetalDust.Root.Visible=p.Tutorial.FeatureUnlocks.SeedSatchel==true
 self.CurrencyRows.AncientNectar.Value.Text=compact(p.Currencies.AncientNectar)
 self.CurrencyRows.AncientNectar.Root.Visible=(p.Season.Count or 0)>0 or (p.Currencies.AncientNectar or 0)>0

 local rollUnlocked=self:RefreshRollHUDVisibility()
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
 local tutorialActive,tutorialAllowed=self:TutorialRollState()
 local rollVisualEnabled=not tutorialActive or tutorialAllowed
 self.RollIcon.ImageColor3=rollVisualEnabled and C.White or C.Muted
 self.RollIcon.ImageTransparency=rollVisualEnabled and 0 or .48
 if self.RollStatusDot then
  self.RollStatusDot.BackgroundColor3=self.Auto and C.Green or C.Faint
 end
 if self.Auto and not self.RouletteRunning and not self.RouletteLanding then self:StartRouletteAnimation() end

 local bloomMax=math.max(1,tonumber(BloomConfig.BloomMax) or 100)
 local charge=math.clamp(tonumber(p.RollState.BloomCharge) or 0,0,bloomMax)
 local bloomPercent=charge/bloomMax*100
 local bloomTutorialStep=T.Steps[self.ReplayIndex or p.Tutorial.Step]
 local bloomTutorialActive=bloomTutorialStep and (bloomTutorialStep.Id=="FillBloom" or bloomTutorialStep.Id=="BloomRoll") or false
 self.MeterLabel.Text=string.format("BLOOM  %.0f%%",bloomPercent)..(p.RollState.SpecialRollReady and "  •  READY" or "")
 self.BloomFill.Size=UDim2.fromScale(charge/bloomMax,1)
 self.MeterArea.Visible=rollUnlocked and (p.Tutorial.Skipped or p.Tutorial.Step>=(T.IndexById.FillBloom or math.huge) or bloomTutorialActive)
 if self.BloomTutorialIndicator then self.BloomTutorialIndicator.Visible=bloomTutorialActive end

 self:RefreshMenuDock()
 refreshPersistentHovers()
 if not self:IsWorkshopExclusive() then
  self.GuideController:Update()
  if self.JourneyGuideController then self.JourneyGuideController:Update() end
 end
 self.GardenPresentation:Update()
 if self.BoostHUD then
  local boosts=self.State.UI and self.State.UI.Boosts or {Items={}}
  self.BoostHUD:Update(boosts,self.State.Revision)
 end
 if self.TraitHUD then
  local inventory=self.State.UI and self.State.UI.Inventory or {}
  local traits=inventory.Traits or {}
  self.TraitHUD:Update(traits,inventory.EquippedBeeSlots or {},self.State.Revision)
 end
 self:RenderQuestTracker()
 self:ApplyWorkshopFocusVisibility()
 self:ApplyIndexFocusVisibility()
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
 local bloomRoll=self.State.Profile.RollState.SpecialRollReady==true
 if bloomRoll then self:SetRouletteBloomHighlight(true,requestId) end
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
  chance.Text=odds and odds<math.huge and ("1 / "..RollPool.FormatOddsNumber(odds)) or "1 / ∞"
  local showRarity=not self.State or not self.State.Profile or self.State.Profile.Settings.ShowRarityColors~=false
  chance.TextColor3=current and C.Gold or (showRarity and color or C.Muted)
  chance.TextTransparency=faint
  chance.TextSize=current and 10 or 9
 end
 local scale=slot:FindFirstChild("SlotScale")
 if not scale or not scale:IsA("UIScale") then error("[BloomUI] Roulette slot missing authored SlotScale: "..slot.Name) end
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
 local settings=self.State and self.State.Profile.Settings or {}
 local master=settings.MuteAll and 0 or (tonumber(settings.SFXVolume) or tonumber(settings.TokenSoundVolume) or .5)
 s.Volume=RollAudio.SpinVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.SpinPlaybackSpeed+Random.new():NextNumber(-.06,.06)
 s:Play()
end

function UI:PlayRouletteRewardSound()
 local s=self.RouletteRewardSound
 if not s then return end
 s:Stop() s.TimePosition=0
 local settings=self.State and self.State.Profile.Settings or {}
 local master=settings.MuteAll and 0 or (tonumber(settings.SFXVolume) or tonumber(settings.TokenSoundVolume) or .5)
 s.Volume=RollAudio.RewardVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.RewardPlaybackSpeed s:Play()
end

function UI:StepRoulette(duration,generation)
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 or not self.RouletteStrip then return false end
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 local quick=self.State and self.State.Profile and self.State.Profile.Settings.QuickRoll==true
 local actualDuration=duration*(quick and .58 or 1)
 local tween=TweenService:Create(self.RouletteStrip,TweenInfo.new(actualDuration,Enum.EasingStyle.Linear,Enum.EasingDirection.Out),{Position=UDim2.fromOffset(0,RollAudio.StepPixels)})
 self.RouletteTween=tween
 self:PlayRouletteTick()
 tween:Play()
 tween.Completed:Wait()
 if generation and generation~=self.RouletteGeneration then return false end
 if self.RouletteTween==tween then self.RouletteTween=nil end
 self.RouletteCursor=(self.RouletteCursor%#pool)+1
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 self:RefreshRouletteSlots()
 return true
end

function UI:SetRouletteBloomHighlight(active,requestId)
 if not self.RouletteViewport or not self.RouletteBloomBase then return end
 local base=self.RouletteBloomBase
 if active then
  if requestId~=nil then self.RouletteBloomRequest=requestId end
  local bloomColor=C.Gold
  TweenService:Create(self.RouletteViewport,TweenInfo.new(Theme.Motion.Fast),{
   BackgroundColor3=base.BackgroundColor3:Lerp(bloomColor,.16),
   BackgroundTransparency=math.max(0,base.BackgroundTransparency-.04),
  }):Play()
  if self.RouletteStroke then
   TweenService:Create(self.RouletteStroke,TweenInfo.new(Theme.Motion.Fast),{Color=bloomColor,Thickness=3,Transparency=0}):Play()
  end
  if self.RouletteTopAccent then
   TweenService:Create(self.RouletteTopAccent,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=bloomColor,BackgroundTransparency=.02}):Play()
  end
  if self.RouletteCurrentMarker then
   TweenService:Create(self.RouletteCurrentMarker,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=bloomColor,BackgroundTransparency=.78}):Play()
  end
  if self.RouletteCurrentMarkerStroke then
   TweenService:Create(self.RouletteCurrentMarkerStroke,TweenInfo.new(Theme.Motion.Fast),{Color=bloomColor,Thickness=2.4,Transparency=0}):Play()
  end
  return
 end
 if requestId~=nil and self.RouletteBloomRequest~=nil and requestId~=self.RouletteBloomRequest then return end
 self.RouletteBloomRequest=nil
 TweenService:Create(self.RouletteViewport,TweenInfo.new(Theme.Motion.Fast),{
  BackgroundColor3=base.BackgroundColor3,
  BackgroundTransparency=base.BackgroundTransparency,
 }):Play()
 if self.RouletteStroke then
  TweenService:Create(self.RouletteStroke,TweenInfo.new(Theme.Motion.Fast),{Color=base.StrokeColor,Thickness=base.StrokeThickness,Transparency=base.StrokeTransparency}):Play()
 end
 if self.RouletteTopAccent then
  TweenService:Create(self.RouletteTopAccent,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=base.AccentColor,BackgroundTransparency=base.AccentTransparency}):Play()
 end
 if self.RouletteCurrentMarker then
  TweenService:Create(self.RouletteCurrentMarker,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=base.MarkerColor,BackgroundTransparency=base.MarkerTransparency}):Play()
 end
 if self.RouletteCurrentMarkerStroke then
  TweenService:Create(self.RouletteCurrentMarkerStroke,TweenInfo.new(Theme.Motion.Fast),{Color=base.MarkerStrokeColor,Thickness=base.MarkerStrokeThickness,Transparency=base.MarkerStrokeTransparency}):Play()
 end
end

function UI:StartRouletteAnimation()
 local bloomReady=self.State and self.State.Profile and self.State.Profile.RollState.SpecialRollReady==true
 if bloomReady and self.RouletteBloomRequest==nil then self:SetRouletteBloomHighlight(true,nil) end
 if self.RouletteRunning or self.RouletteLanding or not self.RouletteStrip then return end
 self.RouletteRunning=true
 if self.RouletteViewport then self.RouletteViewport.Visible=true end
 self.RouletteGeneration=self.RouletteGeneration+1
 local generation=self.RouletteGeneration
 task.spawn(function()
  while self.RouletteRunning and not self.RouletteLanding and generation==self.RouletteGeneration and self.Gui and self.Gui.Parent do
   if not self:StepRoulette(RollAudio.CruiseStep,generation) then break end
  end
  if generation==self.RouletteGeneration and self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
  if generation==self.RouletteGeneration then self.RouletteTween=nil end
 end)
end

function UI:StopRouletteAnimation()
 self:SetRouletteBloomHighlight(false)
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
 local tutorialActive,tutorialAllowed=self:TutorialRollState()
 if tutorialActive then
  self.Auto=false
  if enabled and not tutorialAllowed then
   self:Toast("Complete the tutorial to roll again")
   self:RefreshRollHUDVisibility()
   return
  end
  if enabled then
   self.RollSession=(self.RollSession or 0)+1
   self:StartRouletteAnimation()
   task.defer(function() self:RollNow(false) end)
  else
   self:StopRouletteAnimation()
  end
  self:RefreshRollHUDVisibility()
  return
 end

 local nextAuto=enabled==true
 if self.Auto~=nextAuto then self.RollSession=(self.RollSession or 0)+1 end
 self.Auto=nextAuto
 if self.Auto then
  self:StartRouletteAnimation()
  task.defer(function() self:RollNow(true) end)
 else
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

function UI:PrepareRouletteLandingTarget(targetIndex,stepCount)
 local pool=self.RouletteVisualPool or {}
 if #pool==0 or not targetIndex then return end
 local desired=((self.RouletteCursor-1+math.max(1,stepCount or 1))%#pool)+1
 if targetIndex~=desired then
  pool[targetIndex],pool[desired]=pool[desired],pool[targetIndex]
 end
 self.RouletteVisualPool=pool
end

function UI:SetRareRollFocus(active,rarity)
 if active then
  if self.Menu or self.RareRollVisibility then return false end
  local snapshot={}
  for _,gui in ipairs({self.ObjectiveCard,self.CurrencyHUD,self.Dock,self.RollHUD,self.Roll,self.Guide,self.ToastRoot}) do
   if gui and gui:IsA("GuiObject") then snapshot[gui]=gui.Visible gui.Visible=false end
  end
  self.RareRollVisibility=snapshot
  if self.BoostHUD then self.BoostHUD:SetSuppressed(true) end
  if self.ModalShade then
   local colors={
    Legendary=Color3.fromRGB(255,190,70),
    Mythic=Color3.fromRGB(180,95,255),
    Celestial=Color3.fromRGB(215,245,255),
   }
   self.ModalShade.BackgroundColor3=colors[rarity] or Color3.fromRGB(25,40,60)
   self.ModalShade.BackgroundTransparency=.68
   self.ModalShade.Visible=true
  end
  return true
 end
 local snapshot=self.RareRollVisibility
 self.RareRollVisibility=nil
 if snapshot then
  for gui,visible in pairs(snapshot) do if gui and gui.Parent then gui.Visible=visible end end
 end
 if self.ModalShade and not self.Menu then self.ModalShade.Visible=false end
 if self.BoostHUD then self.BoostHUD:SetSuppressed(self:IsWorkshopExclusive()) end
 return snapshot~=nil
end

function UI:AnimateRouletteResult(revealScale)
 revealScale=math.max(.1,tonumber(revealScale) or 1)
 local slot=self.RouletteSlots and self.RouletteSlots.Current if not slot then return end
 local scale=slot:FindFirstChild("SlotScale")
 local icon=slot:FindFirstChild("Icon")
 if scale then
  scale.Scale=1.04
  local pop=TweenService:Create(scale,TweenInfo.new(.18*revealScale,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1.18}) pop:Play() pop.Completed:Wait()
  TweenService:Create(scale,TweenInfo.new(.20*revealScale,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Scale=1.04}):Play()
 end
 if icon and icon:IsA("ImageLabel") then
  icon.Rotation=-7
  local swing=TweenService:Create(icon,TweenInfo.new(.16*revealScale,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,1,true),{Rotation=7}) swing:Play() swing.Completed:Wait() icon.Rotation=0
 end
end

function UI:ResolveRouletteReward(payload)
 if type(payload)~="table" or self.RouletteLanding then return end
 local requestId=payload.RequestId
 local requestSession=requestId and self.RollRequestSessions[requestId] or self.PendingRollSession
 if requestSession~=nil and requestSession~=(self.RollSession or 0) then
  self:SetRouletteBloomHighlight(false,requestId)
  return
 end
 if payload.IsSpecialRoll==true then
  -- The Bloom highlight belongs to this exact roulette request and lasts until its result hold ends.
  self:SetRouletteBloomHighlight(true,requestId)
 elseif self.RouletteBloomRequest==requestId then
  self:SetRouletteBloomHighlight(false,requestId)
 end

 -- A server reward can arrive after the player pressed STOP.
 -- The item is already granted server-side; do not resurrect the roulette
 -- and do not show a separate RewardReveal card.
 if not self.Auto and not self.RouletteRunning then
  self:SetRouletteBloomHighlight(false,requestId)
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
  local profile=self.State and self.State.Profile
  local revealScale=WorkshopEffects.Value(profile,"ROLL_3","RevealScale",1)
  local target=self:FindRouletteTarget(payload)
  local steps=RollAudio.SettleSteps
  self:PrepareRouletteLandingTarget(target,#steps)
  for _,duration in ipairs(steps) do
   if generation~=self.RouletteGeneration then break end
   if not self:StepRoulette(duration*revealScale,generation) then break end
  end
  if generation==self.RouletteGeneration then
   local quick=self.State and self.State.Profile and self.State.Profile.Settings.QuickRoll==true
   local speedScale=quick and .55 or 1
   local remaining=math.max(0,((RollAudio.MinimumVisualSpin or 0)*revealScale*speedScale)-(os.clock()-visualStart))
   if remaining>0 then task.wait(remaining) end
   local rank=R.Rank[payload.Rarity] or 0
   local rare=rank>=(R.Rank.Legendary or 5)
   local focused=rare and self:SetRareRollFocus(true,payload.Rarity) or false
   self:PlayRouletteRewardSound()
   self:AnimateRouletteResult(revealScale*(rare and 1.18 or 1))
   task.wait(rare and 1.15 or RollAudio.ResultHold*revealScale*speedScale)
   if focused then self:SetRareRollFocus(false,payload.Rarity) end
  end
  if generation~=self.RouletteGeneration then
   self:SetRouletteBloomHighlight(false,requestId)
   return
  end
  self.RouletteLanding=false
  self:SetRouletteBloomHighlight(false,requestId)
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

 self.QuestTracker=root:WaitForChild("QuestTrackerHUD")
 self.QuestRows={}
 for i=1,3 do
  local row=self.QuestTracker:WaitForChild("Quest_"..i)
  self.QuestRows[i]=row
  row.Activated:Connect(function()
   local p=self.State and self.State.Profile
   if p and p.Tutorial.FeatureUnlocks.Trials then self:Open("Trials")
   else self:Toast("Quests unlock through progression") end
  end)
 end

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
 for _,name in ipairs({"SeedSatchel","Garden","Hive","Index","Workshop","Trials","Settings"}) do
  local button=self.Dock:WaitForChild("Dock_"..name)
  local tip=button:WaitForChild("Tooltip")
  tip.Text=MENU_NAMES[name] or name
  local icon=button:FindFirstChild("Icon")
  local image=Icons.Get("Menus",name)
  if icon and icon:IsA("ImageLabel") then icon.Image=image end
  button.MouseEnter:Connect(function()
   if not button.Visible then return end
   button:SetAttribute("BloomDockHovered",true)
   tip.Visible=true
   if icon and icon:IsA("ImageLabel") and button:GetAttribute("BloomDockEnabled")~=false then
    TweenService:Create(icon,TweenInfo.new(Theme.Motion.Fast),{ImageColor3=C.Blue}):Play()
   end
  end)
  button.MouseLeave:Connect(function()
   button:SetAttribute("BloomDockHovered",false)
   tip.Visible=false
   if icon and icon:IsA("ImageLabel") then
    local enabled=button:GetAttribute("BloomDockEnabled")~=false
    local selected=self.Menu==name
    TweenService:Create(icon,TweenInfo.new(Theme.Motion.Fast),{ImageColor3=enabled and (selected and C.Blue or C.White) or C.Muted}):Play()
   end
  end)
  button.Activated:Connect(function()
   if button:GetAttribute("BloomDockEnabled")==false then return end
   self:OpenDockMenu(name)
  end)
  self.DockButtons[name]=button
  self.DockTooltips[name]=tip
 end

 self.RollHUD=root:WaitForChild("RollHUD")
 self.RouletteViewport=root:WaitForChild("VerticalRoulette")
 self.RouletteViewport.Visible=false
 self.RouletteStroke=self.RouletteViewport:FindFirstChildOfClass("UIStroke")
 self.RouletteTopAccent=self.RouletteViewport:FindFirstChild("TopAccent")
 self.RouletteCurrentMarker=self.RouletteViewport:FindFirstChild("CurrentMarker")
 self.RouletteCurrentMarkerStroke=self.RouletteCurrentMarker and self.RouletteCurrentMarker:FindFirstChildOfClass("UIStroke")
 self.RouletteBloomBase={
  BackgroundColor3=self.RouletteViewport.BackgroundColor3,
  BackgroundTransparency=self.RouletteViewport.BackgroundTransparency,
  StrokeColor=self.RouletteStroke and self.RouletteStroke.Color or C.Border,
  StrokeThickness=self.RouletteStroke and self.RouletteStroke.Thickness or 1.5,
  StrokeTransparency=self.RouletteStroke and self.RouletteStroke.Transparency or .28,
  AccentColor=self.RouletteTopAccent and self.RouletteTopAccent.BackgroundColor3 or C.Blue,
  AccentTransparency=self.RouletteTopAccent and self.RouletteTopAccent.BackgroundTransparency or .28,
  MarkerColor=self.RouletteCurrentMarker and self.RouletteCurrentMarker.BackgroundColor3 or C.Gold,
  MarkerTransparency=self.RouletteCurrentMarker and self.RouletteCurrentMarker.BackgroundTransparency or .92,
  MarkerStrokeColor=self.RouletteCurrentMarkerStroke and self.RouletteCurrentMarkerStroke.Color or C.Gold,
  MarkerStrokeThickness=self.RouletteCurrentMarkerStroke and self.RouletteCurrentMarkerStroke.Thickness or 1.7,
  MarkerStrokeTransparency=self.RouletteCurrentMarkerStroke and self.RouletteCurrentMarkerStroke.Transparency or .04,
 }

 -- Remove any pre-refactor roulette that may still exist in a stale Studio place.
 -- The only supported reel is SafeRoot/VerticalRoulette.
 for _,legacy in ipairs(self.RollHUD:GetDescendants()) do
  local lower=string.lower(legacy.Name)
  if legacy:IsA("GuiObject") and (string.find(lower,"roulette",1,true) or hasLegacyReelToken(lower)) then
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
 self.BloomTutorialIndicator=self.MeterArea:WaitForChild("TutorialIndicator")
 self.BloomTrack=self.MeterArea:WaitForChild("BloomTrack")
 self.BloomFill=self.BloomTrack:WaitForChild("BloomFill")
 self.Roll=root:FindFirstChild("RollButton") or root:WaitForChild("TutorialRollButton")
 self.RollStroke=self.Roll:FindFirstChildOfClass("UIStroke")
 self.RollIcon=self.Roll:WaitForChild("Icon")
 self.RollStatusDot=self.Roll:FindFirstChild("StatusDot")
 self.RollTutorialLock=self.Roll:WaitForChild("TutorialLockLabel")
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
 self.StateKits=self.Panel:FindFirstChild("StateKits")
 if not self.StateKits then error("[BloomUI] MainPanel/StateKits missing from authored UI") end

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

local REQUIRED_AUTHORED_UI={
 "ObjectiveCard","CurrencyHUD","MenuDock","RollHUD","VerticalRoulette","TutorialGuideBanner",
 "TutorialSpotlight","TutorialCallout","TutorialScreenArrow",
 "Toast","ModalShade","MainPanel","RewardReveal","ActiveBoostsHUD","ActiveBoostTooltip",
 "TraitHUD","TraitTooltip","TraitTierPopup","QuestTrackerHUD","WorldUIPrototypes",
}
local RETIRED_MENU_GUI={"Dock_FieldGuide","Dock_Map","FieldGuideKit","MapKit"}

local function validateBloomGui(gui)
 if not gui or not gui:IsA("ScreenGui") then return false,{"BloomUI"} end
 local root=gui:FindFirstChild("SafeRoot")
 if not root or not root:IsA("GuiObject") then return false,{"SafeRoot"} end
 local missing={}
 for _,name in ipairs(REQUIRED_AUTHORED_UI) do
  if not root:FindFirstChild(name) then table.insert(missing,name) end
 end
  local boosts=root:FindFirstChild("ActiveBoostsHUD")
  if boosts then
   for _,name in ipairs({"LuckBadge","ScrollLeft","ScrollRight"}) do
    if not boosts:FindFirstChild(name,true) then table.insert(missing,"ActiveBoostsHUD/"..name) end
   end
  end
 local panel=root:FindFirstChild("MainPanel")
 if panel then
  for _,name in ipairs({"InventoryPrototype","WorkshopTemplate","QuestsPrototype","IndexPrototype"}) do
   if not panel:FindFirstChild(name) then table.insert(missing,"MainPanel/"..name) end
  end
   local inventoryPrototype=panel:FindFirstChild("InventoryPrototype")
   if inventoryPrototype then
    for _,name in ipairs({"TraitFilterPanel","TraitFilterList","TraitChipTemplate","UnequipAllButton","EquippedBadge","InventoryHoverScale","BeeSummary","PassiveRowTemplate","AbilityDescription"}) do
     if not inventoryPrototype:FindFirstChild(name,true) then table.insert(missing,"InventoryPrototype/"..name) end
    end
   end
   local workshopTemplate=panel:FindFirstChild("WorkshopTemplate")
   if workshopTemplate and not workshopTemplate:FindFirstChild("CurrencyHelp",true) then
    table.insert(missing,"WorkshopTemplate/CurrencyHelp")
   end
  local stateKits=panel:FindFirstChild("StateKits")
   if not stateKits or not stateKits:FindFirstChild("GardenKit") then
    table.insert(missing,"MainPanel/StateKits/GardenKit")
   else
    for _,name in ipairs({"UsedBadge","GhostBadge"}) do
     if not stateKits.GardenKit:FindFirstChild(name,true) then table.insert(missing,"MainPanel/StateKits/GardenKit/"..name) end
    end
   end
   if not stateKits or not stateKits:FindFirstChild("HiveKit") then
    table.insert(missing,"MainPanel/StateKits/HiveKit")
   else
    for _,name in ipairs({"HiveShell","ProgressTrack","RoadList","RoadNodeTemplate","UpgradeButton"}) do
     if not stateKits.HiveKit:FindFirstChild(name,true) then table.insert(missing,"MainPanel/StateKits/HiveKit/"..name) end
    end
   end
   local indexPrototype=panel:FindFirstChild("IndexPrototype")
   if indexPrototype then
    for _,name in ipairs({"TraitBeeStrip","TraitBeeIconTemplate","EquipSynergyButton"}) do
     if not indexPrototype:FindFirstChild(name,true) then table.insert(missing,"IndexPrototype/"..name) end
    end
   end
   if not root:FindFirstChild("Dock_Hive",true) then table.insert(missing,"MenuDock/Dock_Hive") end
 end
 for _,name in ipairs(RETIRED_MENU_GUI) do
  if root:FindFirstChild(name,true) then table.insert(missing,"retired:"..name) end
 end
 return #missing==0,missing
end

local function missingText(missing)
 return #missing>0 and table.concat(missing,", ") or "unknown authored nodes"
end

function UI:ResolveBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")

 local function collect()
  local found={}
  for _,child in ipairs(playerGui:GetChildren()) do
   if child.Name=="BloomUI" and child:IsA("ScreenGui") then table.insert(found,child) end
  end
  return found
 end

 local function destroyExcept(preferred)
  for _,gui in ipairs(collect()) do
   if gui~=preferred then
    warn("[BloomUI] Removing duplicate/stale PlayerGui/BloomUI:",gui:GetFullName())
    gui:Destroy()
   end
  end
  return preferred
 end

 local function chooseValid()
  local found=collect()
  local best=nil
  for i=#found,1,-1 do
   local candidate=found[i]
   local valid,missing=validateBloomGui(candidate)
   if valid and not best then
    best=candidate
   elseif not valid then
    warn("[BloomUI] Rejecting stale PlayerGui/BloomUI; missing authored nodes:",missingText(missing))
   end
  end
  if best then
   print("[BloomUI] Using schema-valid PlayerGui/BloomUI; copies:",#found)
   return destroyExcept(best)
  end
  return nil
 end

 local existing=chooseValid()
 if existing then return existing end

 local template=StarterGui:FindFirstChild("BloomUI")
 local deadline=os.clock()+3
 while os.clock()<deadline do
  existing=chooseValid()
  if existing then return existing end
  template=StarterGui:FindFirstChild("BloomUI")
  local templateValid=template and select(1,validateBloomGui(template))
  if templateValid then break end
  task.wait(.05)
 end

 template=StarterGui:FindFirstChild("BloomUI")
 if not template then
  error("[BloomUI] Current authored BloomUI is missing from StarterGui; AI SYNC did not provide the UI model")
 end

 local templateValid,templateMissing=validateBloomGui(template)
 if not templateValid then
  error("[BloomUI] StarterGui/BloomUI is stale or incomplete; missing authored nodes: "..missingText(templateMissing)..". Stop Play, run AI SYNC, then start Play again.")
 end

 for _,stale in ipairs(collect()) do
  local valid=select(1,validateBloomGui(stale))
  if not valid then
   warn("[BloomUI] Replacing stale runtime HUD from current StarterGui template:",stale:GetFullName())
   stale:Destroy()
  end
 end

 existing=chooseValid()
 if existing then return existing end

 local clone=template:Clone()
 clone.Name="BloomUI"
 clone:SetAttribute("BloomRuntimeClone",true)
 clone:SetAttribute("BloomAuthoredSchema","boost-hud-v1")
 clone.Parent=playerGui
 local cloneValid,cloneMissing=validateBloomGui(clone)
 if not cloneValid then
  clone:Destroy()
  error("[BloomUI] Failed to clone current authored HUD; missing nodes after clone: "..missingText(cloneMissing))
 end
 print("[BloomUI] Created schema-valid PlayerGui/BloomUI from current StarterGui")
 return destroyExcept(clone)
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
 local previousTutorialStep=not firstState and self.State.Profile and self.State.Profile.Tutorial and self.State.Profile.Tutorial.Step or nil
 local previousTutorialId=previousTutorialStep and T.Steps[previousTutorialStep] and T.Steps[previousTutorialStep].Id or nil
 local nextTutorialStep=payload.Profile.Tutorial and payload.Profile.Tutorial.Step or nil
 local closeInventoryAfterEquip=self.Menu=="SeedSatchel"
  and previousTutorialId=="EquipBee"
  and previousTutorialStep~=nil
  and nextTutorialStep~=nil
  and nextTutorialStep>previousTutorialStep
 if not firstState and payload.Revision~=nil and self.State.Revision==payload.Revision then return false end
 self.State=payload
 SettingsV2.ApplyEffects(self,payload.Profile)
 if closeInventoryAfterEquip then self:Close() end
 if firstState then
  self.ObjectiveCard.Visible=true
  self.CurrencyHUD.Visible=true
  self.Dock.Visible=true
 end
 if not self.RouletteLanding then self:BuildRouletteVisualPool(true) end
 self:Render()
 if firstState then
  self:ApplySafeArea()
  self.Player:SetAttribute("BloomFirstRenderRevision",tonumber(payload.Revision) or 0)
  self.Player:SetAttribute("BloomStateReady",true)
  print("[BloomUI] First authoritative render ready revision:",tonumber(payload.Revision) or 0)
 end

 if previousTutorialStep and previousTutorialStep<=#T.Steps and nextTutorialStep and nextTutorialStep>#T.Steps then
  self.ObjectiveCard.Visible=true
  self.ObjectiveTitle.Text="TUTORIAL COMPLETE"
  self.ObjectiveText.Text="Your garden journey begins now."
  self.ObjectiveProgress.Visible=true
  self.ObjectiveProgressFill.Size=UDim2.fromScale(1,1)
  local scale=self.ObjectiveCard:FindFirstChild("TutorialCompleteScale")
  if not scale or not scale:IsA("UIScale") then error("[BloomUI] ObjectiveCard/TutorialCompleteScale missing") end
  scale.Scale=1.08
  TweenService:Create(scale,TweenInfo.new(.45,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
  task.delay(1.5,function()
   if self.State and self.State.Profile and self.State.Profile.Tutorial.Step>#T.Steps then self:Render() end
  end)
 end

 if self.Menu and not self.WorkshopPanDragging and self.MenuRefreshRequested then
  self.MenuRefreshRequested=false
  self:RenderMenu(true)
 end
 if firstState then print("[BloomUI] State applied:",source or "Event") end
 return true
end

function UI:Start()
 print("[BloomUI] Starting client build:",CLIENT_BUILD)
 self.Player:SetAttribute("BloomClientReady",false)
 self.Player:SetAttribute("BloomStateReady",false)
 self.Player:SetAttribute("BloomFirstRenderRevision",nil)
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
 self.JourneyGuideController=require(script.Parent.JourneyGuideController)
 self.JourneyGuideController:Init(self,self.GuideController)
 self.GardenPresentation=require(script.Parent.GardenPresentationController)
 self.GardenPresentation:Init(self)
 self.BoostHUD=require(script.Parent.BoostHUDController)
 self.BoostHUD:Init(self)
 self.TraitHUD=require(script.Parent.TraitHUDController)
 self.TraitHUD:Init(self)

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
     if not payload.OK then self:SetRouletteBloomHighlight(false,requestId) end
     if self.State then self:Render() end
    end
   end
   if relevant and payload.OK then
    local refreshMenu=MENU_REFRESH_ACTIONS[payload.Action]
    if refreshMenu and self.Menu==refreshMenu then self.MenuRefreshRequested=true end
   end
   if relevant and not payload.OK then
    local silentActivity=payload.Action=="Activity" and (
     payload.Reason=="STALE_ACTIVITY"
     or payload.Reason=="ACTIVITY_EXPIRED"
     or payload.Reason=="ACTIVITY_CHANGED"
     or payload.Reason=="TOO_FAR"
    )
    if not silentActivity and not (payload.Action=="Ready" and payload.Reason=="PROFILE_LOADING") then
     self:Toast(payload.Message or payload.Reason or "Action is currently unavailable")
    end
   end
  elseif kind=="TokenCollected" then
   if self.State then
    local audioSettings=self.State.Profile.Settings
    local volume=audioSettings.MuteAll and 0 or (tonumber(audioSettings.SFXVolume) or tonumber(audioSettings.TokenSoundVolume) or .5)
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
  elseif kind=="PlantPicker" then self:Open("Garden",{Slot=payload})
  elseif kind=="Activities" then
   self.Activities:Update(payload)
   if self.MenuRenderer=="QuestsV2" then self:RenderMenu(true) end
  elseif kind=="OtherTokens" then self.Activities:Others(payload)
  elseif kind=="Bees" then self.Bees:Update(payload)
  elseif kind=="Message" then self:Toast(payload)
  elseif kind=="Open" then task.defer(function() self:Open(payload) end)
  elseif kind=="Trials" then self:Open("Trials",payload)
  elseif kind=="RareFeed" then if self.State and self.State.Profile.Settings.RareFeed then self:Toast(payload.Player.." • "..payload.Name) end
  elseif kind=="Ceremony" then
   if self.State and self.State.Profile.Settings.RewardPopups~=false then
    self.Rewards:Enqueue({
     Kind=payload.RewardKind or "Ceremony",
     Id=payload.RewardId,
     Ceremony=payload.Kind,
     DisplayName=payload.Text,
     Rarity=payload.Rarity or (payload.Kind=="Season" and "Mythic" or "Epic"),
     IsNew=payload.IsNew==true,
     Chance=1,
    })
   end
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
  local settings=self.State and self.State.Profile and self.State.Profile.Settings or {}
  local openKey=KEY_CODES[tostring(settings.OpenMenuKey or "M")] or Enum.KeyCode.M
  local rollKey=KEY_CODES[tostring(settings.RollKey or "R")] or Enum.KeyCode.R
  if input.KeyCode==Enum.KeyCode.Escape and self.Menu then
   self:Close()
  elseif input.KeyCode==openKey then
   local unlocked=self.State and self.State.Profile.Tutorial.FeatureUnlocks.SeedSatchel==true
   if self.Menu=="SeedSatchel" then
    self:Close()
   elseif unlocked then
    self:Open("SeedSatchel")
   end
  elseif input.KeyCode==rollKey and self.State and self.State.Profile.Tutorial.FeatureUnlocks.Roll==true then
   self:SetAutoRolling(not self.Auto)
  end
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
    if workspace:GetServerTimeNow()>item.Expires then self.Activities:RemoveItem(id) end
   end
   if self.Auto and not self.Pending and not self.RouletteLanding then self:RollNow(true) end
   if self.Pending and os.clock()-self.PendingAt>15 then
    self.Pending=false
    self.PendingRollRequest=nil
    self.PendingRollSession=nil
    self.NextRoll=math.max(self.NextRoll,os.clock()+1)
    self:Toast(self.Auto and "Server response timed out. Retrying..." or "Server response timed out.")
    if self.Auto and not self.RouletteRunning and not self.RouletteLanding then self:StartRouletteAnimation() end
    if self.State then self:Render() end
   end
   if self.State then
    self.GuideController:Update()
    if self.JourneyGuideController then self.JourneyGuideController:Update() end
    if self.BoostHUD then self.BoostHUD:Tick() end
   end
   if self.ToastUntil and os.clock()>self.ToastUntil then self.ToastRoot.Visible=false self.ToastUntil=nil end
  end
 end)
end

return UI
