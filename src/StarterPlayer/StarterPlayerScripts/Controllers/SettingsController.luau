local UIS=game:GetService("UserInputService")
local Lighting=game:GetService("Lighting")

local S={Connections={}}

local ON_COLOR=Color3.fromRGB(8,115,184)
local OFF_COLOR=Color3.fromRGB(31,46,61)
local KNOB_COLOR=Color3.fromRGB(235,247,255)
local CATEGORY_ACTIVE=Color3.fromRGB(14,46,74)
local CATEGORY_IDLE=Color3.fromRGB(13,26,40)
local CATEGORY_STROKE_ACTIVE=Color3.fromRGB(48,186,255)
local CATEGORY_STROKE_IDLE=Color3.fromRGB(23,60,94)

local CATEGORY_Y={
 General=0,
 Audio=148,
 Gameplay=296,
 Interface=444,
 Graphics=548,
 Controls=654,
}

local CATEGORY_SUBTITLE={
 General="Game & UI preferences",
 Audio="Music and sound effects",
 Gameplay="Roll and reward behavior",
 Interface="HUD and presentation",
 Graphics="Visual effects and scale",
 Controls="Keyboard shortcuts",
}

local TOGGLE_BINDINGS={
 TutorialsToggle="TutorialsEnabled",
 RewardPopupsToggle="RewardPopups",
 QuickRollToggle="QuickRoll",
 RarityColorsToggle="ShowRarityColors",
 CompactHudToggle="CompactHUD",
 BloomToggle="BloomEnabled",
 LowEffectsToggle="ReducedEffects",
 MuteAllToggle="MuteAll",
}

local function connect(signal,fn)
 local connection=signal:Connect(fn)
 table.insert(S.Connections,connection)
 return connection
end

function S.Cleanup()
 for _,connection in ipairs(S.Connections) do
  connection:Disconnect()
 end
 table.clear(S.Connections)
 S.Runtime=nil
 S.ListeningKeybind=nil
end

local function find(root,name,className)
 local object=root and root:FindFirstChild(name,true)
 if object and (not className or object:IsA(className)) then return object end
 return nil
end

local function setToggleVisual(toggle,on)
 if not toggle or not toggle:IsA("GuiObject") then return end
 toggle.BackgroundColor3=on and ON_COLOR or OFF_COLOR
 local knob=toggle:FindFirstChild("Knob")
 if knob and knob:IsA("GuiObject") then
  knob.BackgroundColor3=KNOB_COLOR
  knob.Position=on and UDim2.new(1,-20,.5,-8) or UDim2.new(0,4,.5,-8)
 end
end

local function bindPress(object,callback)
 if not object or not object:IsA("GuiObject") then return end
 if object:IsA("GuiButton") then
  connect(object.Activated,callback)
 else
  object.Active=true
  connect(object.InputBegan,function(input)
   local t=input.UserInputType
   if t==Enum.UserInputType.MouseButton1 or t==Enum.UserInputType.Touch then callback() end
  end)
 end
end

local function updateCategoryVisual(button,selected)
 if not button or not button:IsA("GuiObject") then return end
 button.BackgroundColor3=selected and CATEGORY_ACTIVE or CATEGORY_IDLE
 button.BackgroundTransparency=selected and .015 or .12
 local stroke=button:FindFirstChildOfClass("UIStroke")
 if stroke then
  stroke.Color=selected and CATEGORY_STROKE_ACTIVE or CATEGORY_STROKE_IDLE
  stroke.Thickness=selected and 1.4 or 1
  stroke.Transparency=selected and .05 or .45
 end
end

local function setSliderVisual(slider,t)
 if not slider or not slider:IsA("GuiObject") then return end
 t=math.clamp(t,0,1)
 local fill=slider:FindFirstChild("Fill")
 local knob=slider:FindFirstChild("Knob")
 if fill and fill:IsA("GuiObject") then fill.Size=UDim2.new(t,0,1,0) end
 if knob and knob:IsA("GuiObject") then knob.Position=UDim2.new(t,-6,.5,-6) end
end

local function bindSlider(ui,slider,key,minValue,maxValue,current)
 if not slider or not slider:IsA("GuiObject") then return end
 slider.Active=true
 local range=maxValue-minValue
 local initial=math.clamp((current-minValue)/range,0,1)
 setSliderVisual(slider,initial)

 local dragging=false
 local lastValue=current

 local function valueAt(screenX)
  local width=math.max(1,slider.AbsoluteSize.X)
  local t=math.clamp((screenX-slider.AbsolutePosition.X)/width,0,1)
  local value=minValue+range*t
  if key~="UIScale" then
   value=math.floor(value*100+.5)/100
  else
   value=math.floor(value*100+.5)/100
  end
  lastValue=value
  setSliderVisual(slider,t)
 end

 connect(slider.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=true
   valueAt(input.Position.X)
  end
 end)

 connect(UIS.InputChanged,function(input)
  if not dragging then return end
  if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
   valueAt(input.Position.X)
  end
 end)

 connect(UIS.InputEnded,function(input)
  if not dragging then return end
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
   dragging=false
   ui:Send("Setting",key,lastValue)
  end
 end)
end

local function bindKeybind(ui,button,key)
 if not button or not button:IsA("TextButton") then return end
 bindPress(button,function()
  if S.ListeningKeybind then return end
  S.ListeningKeybind={Button=button,Key=key,Previous=button.Text}
  button.Text="PRESS KEY"
 end)
 connect(UIS.InputBegan,function(input,processed)
  if processed or not S.ListeningKeybind or S.ListeningKeybind.Button~=button then return end
  if input.UserInputType~=Enum.UserInputType.Keyboard then return end
  local code=input.KeyCode
  if code==Enum.KeyCode.Unknown or code==Enum.KeyCode.Escape then
   button.Text=S.ListeningKeybind.Previous
   S.ListeningKeybind=nil
   return
  end
  local name=code.Name
  button.Text=name
  S.ListeningKeybind=nil
  ui:Send("Setting",key,name)
 end)
end

function S.ApplyEffects(ui,profile)
 if not profile then return end
 local settings=profile.Settings or {}
 for _,object in ipairs(Lighting:GetDescendants()) do
  if object:IsA("BloomEffect") then
   object.Enabled=settings.BloomEnabled~=false
  end
 end
 local compact=settings.CompactHUD==true
 for _,rootName in ipairs({"CurrencyHUD","MenuDock","RollHUD","RollButton"}) do
  local root=ui.SafeRoot and ui.SafeRoot:FindFirstChild(rootName)
  local scale=root and root:FindFirstChild("UserScale")
  if scale and scale:IsA("UIScale") then scale.Scale=compact and .88 or 1 end
 end
 if ui.PanelScale and ui.Menu~="Workshop" then
  ui.PanelScale.Scale=ui:GetMenuScale()
 end
end

function S.Render(ui,profile,uiState)
 S.Cleanup()
 local template=ui.StateKits and ui.StateKits:FindFirstChild("SettingsKit")
 if not template or not template:IsA("Frame") then
  ui:Label(ui.Content,"SettingsKit missing",32)
  return
 end

 local runtime=template:Clone()
 runtime.Name="SettingsRuntime"
 runtime.Visible=true
 runtime.Position=UDim2.fromScale(0,0)
 runtime.Size=UDim2.fromScale(1,1)
 runtime.LayoutOrder=1
 runtime.Parent=ui.Content
 S.Runtime=runtime

 local settings=profile.Settings or {}
 local shell=find(runtime,"SettingsShell","Frame")
 local categories=find(runtime,"CategoryPanel","Frame")
 local content=find(runtime,"ContentPanel","Frame")
 local scroll=find(runtime,"SettingsScroll","ScrollingFrame")
 local header=find(runtime,"ContentHeader","Frame")
 if not shell or not categories or not content or not scroll or not header then
  error("[SettingsController] Authored SettingsKit structure is incomplete")
 end

 local headerTitle=find(header,"Title","TextLabel")
 local headerSubtitle=find(header,"Subtitle","TextLabel")
 ui.SettingsV2State=ui.SettingsV2State or {Category="General"}
 local selectedCategory=CATEGORY_Y[ui.SettingsV2State.Category]~=nil and ui.SettingsV2State.Category or "General"

 local function selectCategory(name)
  selectedCategory=name
  ui.SettingsV2State.Category=name
  local y=CATEGORY_Y[name] or 0
  scroll.CanvasPosition=Vector2.new(0,y)
  if headerTitle then headerTitle.Text=string.upper(name) end
  if headerSubtitle then headerSubtitle.Text=CATEGORY_SUBTITLE[name] or "" end
  for categoryName in pairs(CATEGORY_Y) do
   updateCategoryVisual(categories:FindFirstChild("Category_"..categoryName),categoryName==name)
  end
 end

 for name in pairs(CATEGORY_Y) do
  local button=categories:FindFirstChild("Category_"..name)
  if button then bindPress(button,function() selectCategory(name) end) end
 end
 selectCategory(selectedCategory)

 for toggleName,key in pairs(TOGGLE_BINDINGS) do
  local toggle=find(scroll,toggleName)
  if toggle then
   local on=settings[key]==true
   setToggleVisual(toggle,on)
   local row=toggle.Parent
   bindPress(row,function()
    ui:Send("Setting",key,not (ui.State and ui.State.Profile.Settings[key]==true))
   end)
  end
 end

 local autoToggle=find(scroll,"AutoRollToggle")
 if autoToggle then
  setToggleVisual(autoToggle,ui.Auto==true)
  bindPress(autoToggle.Parent,function()
   ui:SetAutoRolling(not ui.Auto)
   setToggleVisual(autoToggle,ui.Auto==true)
  end)
 end

 local music=find(scroll,"MusicVolumeSlider")
 local sfx=find(scroll,"SfxVolumeSlider")
 local uiScale=find(scroll,"UiScaleSlider")
 bindSlider(ui,music,"MusicVolume",0,1,tonumber(settings.MusicVolume) or .5)
 bindSlider(ui,sfx,"SFXVolume",0,1,tonumber(settings.SFXVolume) or tonumber(settings.TokenSoundVolume) or .5)
 bindSlider(ui,uiScale,"UIScale",.8,1.15,tonumber(settings.UIScale) or 1)

 local language=find(scroll,"LanguageDropdown","TextButton")
 if language then
  language.Text=tostring(settings.Language or "English")
  bindPress(language,function()
   ui:Toast("English is currently the supported language")
  end)
 end

 local openKey=find(scroll,"OpenMenuKeybind","TextButton")
 local rollKey=find(scroll,"RollKeybind","TextButton")
 if openKey then openKey.Text=tostring(settings.OpenMenuKey or "M") end
 if rollKey then rollKey.Text=tostring(settings.RollKey or "R") end
 bindKeybind(ui,openKey,"OpenMenuKey")
 bindKeybind(ui,rollKey,"RollKey")

 local reset=find(runtime,"ResetButton","TextButton")
 local apply=find(runtime,"ApplyButton","TextButton")
 local save=find(runtime,"SaveButton","TextButton")
 if reset then bindPress(reset,function()
  ui:SetAutoRolling(false)
  ui:Send("ResetSettings")
 end) end
 if apply then bindPress(apply,function()
  S.ApplyEffects(ui,ui.State and ui.State.Profile or profile)
  ui:Toast("Settings applied")
 end) end
 if save then bindPress(save,function() ui:Send("SaveSettings") end) end

 S.ApplyEffects(ui,profile)
end

return S
