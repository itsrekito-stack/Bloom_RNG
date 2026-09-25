local Players=game:GetService("Players")
local RF=game:GetService("ReplicatedFirst")
local RS=game:GetService("ReplicatedStorage")
local ContentProvider=game:GetService("ContentProvider")
local TweenService=game:GetService("TweenService")
local ContextActionService=game:GetService("ContextActionService")
local SoundService=game:GetService("SoundService")

RF:RemoveDefaultLoadingScreen()

local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("BloomLoading")
if old then old:Destroy() end

player:SetAttribute("BloomAssetsReady",false)
player:SetAttribute("BloomGameReady",false)

local gui=Instance.new("ScreenGui")
gui.Name="BloomLoading"
gui.IgnoreGuiInset=true
gui.DisplayOrder=1000
gui.ResetOnSpawn=false
gui.ZIndexBehavior=Enum.ZIndexBehavior.Global
gui.Parent=playerGui

local bg=Instance.new("Frame")
bg.Size=UDim2.fromScale(1,1)
bg.BackgroundColor3=Color3.fromRGB(13,18,24)
bg.BorderSizePixel=0
bg.Parent=gui

local card=Instance.new("Frame")
card.AnchorPoint=Vector2.new(.5,.5)
card.Position=UDim2.fromScale(.5,.5)
card.Size=UDim2.fromOffset(470,184)
card.BackgroundColor3=Color3.fromRGB(20,27,36)
card.BorderSizePixel=0
card.Parent=bg
local cardCorner=Instance.new("UICorner")
cardCorner.CornerRadius=UDim.new(0,20)
cardCorner.Parent=card
local cardStroke=Instance.new("UIStroke")
cardStroke.Color=Color3.fromRGB(7,10,14)
cardStroke.Thickness=3
cardStroke.Parent=card

local accent=Instance.new("Frame")
accent.Size=UDim2.fromOffset(5,58)
accent.Position=UDim2.fromOffset(18,24)
accent.BackgroundColor3=Color3.fromRGB(84,174,255)
accent.BorderSizePixel=0
accent.Parent=card

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-92,0,34)
title.Position=UDim2.fromOffset(36,22)
title.BackgroundTransparency=1
title.Text="BLOOM RNG"
title.TextColor3=Color3.fromRGB(245,248,252)
title.TextSize=25
title.Font=Enum.Font.GothamBlack
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=card

local percent=Instance.new("TextLabel")
percent.AnchorPoint=Vector2.new(1,0)
percent.Size=UDim2.fromOffset(64,30)
percent.Position=UDim2.new(1,-28,0,24)
percent.BackgroundTransparency=1
percent.Text="0%"
percent.TextColor3=Color3.fromRGB(102,224,166)
percent.TextSize=16
percent.Font=Enum.Font.GothamBold
percent.TextXAlignment=Enum.TextXAlignment.Right
percent.Parent=card

local subtitle=Instance.new("TextLabel")
subtitle.Size=UDim2.new(1,-72,0,36)
subtitle.Position=UDim2.fromOffset(36,57)
subtitle.BackgroundTransparency=1
subtitle.Text="Preparing a fully synchronized session…"
subtitle.TextColor3=Color3.fromRGB(166,184,202)
subtitle.TextSize=12
subtitle.TextWrapped=true
subtitle.Font=Enum.Font.Gotham
subtitle.TextXAlignment=Enum.TextXAlignment.Left
subtitle.TextYAlignment=Enum.TextYAlignment.Top
subtitle.Parent=card

local track=Instance.new("Frame")
track.Size=UDim2.new(1,-72,0,10)
track.Position=UDim2.fromOffset(36,119)
track.BackgroundColor3=Color3.fromRGB(34,45,58)
track.BorderSizePixel=0
track.Parent=card
local trackCorner=Instance.new("UICorner")
trackCorner.CornerRadius=UDim.new(0,5)
trackCorner.Parent=track

local fill=Instance.new("Frame")
fill.Size=UDim2.fromScale(0,1)
fill.BackgroundColor3=Color3.fromRGB(102,224,166)
fill.BorderSizePixel=0
fill.Parent=track
local fillCorner=Instance.new("UICorner")
fillCorner.CornerRadius=UDim.new(0,5)
fillCorner.Parent=fill
local gradient=Instance.new("UIGradient")
gradient.Color=ColorSequence.new({
 ColorSequenceKeypoint.new(0,Color3.fromRGB(84,174,255)),
 ColorSequenceKeypoint.new(1,Color3.fromRGB(102,224,166)),
})
gradient.Parent=fill

local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-72,0,20)
status.Position=UDim2.fromOffset(36,138)
status.BackgroundTransparency=1
status.Text="LOADING EXPERIENCE"
status.TextColor3=Color3.fromRGB(116,136,156)
status.TextSize=10
status.Font=Enum.Font.GothamBold
status.TextXAlignment=Enum.TextXAlignment.Left
status.Parent=card

local detail=Instance.new("TextLabel")
detail.Size=UDim2.new(1,-72,0,16)
detail.Position=UDim2.fromOffset(36,157)
detail.BackgroundTransparency=1
detail.Text="Waiting for Roblox replication…"
detail.TextColor3=Color3.fromRGB(78,94,112)
detail.TextSize=9
detail.Font=Enum.Font.Gotham
detail.TextXAlignment=Enum.TextXAlignment.Left
detail.Parent=card

local scale=Instance.new("UIScale")
scale.Parent=card
local function resize()
 local camera=workspace.CurrentCamera
 local w=camera and camera.ViewportSize.X or 1366
 scale.Scale=math.clamp((w-24)/470,.62,1)
end
resize()
if workspace.CurrentCamera then
 workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize)
end
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
 resize()
 if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end
end)

local BLOCK_ACTION="BloomLoadingInputGate"
local BLOCK_KEYS={
 Enum.KeyCode.W,Enum.KeyCode.A,Enum.KeyCode.S,Enum.KeyCode.D,
 Enum.KeyCode.Space,Enum.KeyCode.Up,Enum.KeyCode.Down,Enum.KeyCode.Left,Enum.KeyCode.Right,
 Enum.KeyCode.Thumbstick1,Enum.KeyCode.ButtonA,
}
ContextActionService:BindActionAtPriority(
 BLOCK_ACTION,
 function() return Enum.ContextActionResult.Sink end,
 false,
 10000,
 table.unpack(BLOCK_KEYS)
)

local assetClasses={
 ImageLabel=true,ImageButton=true,Decal=true,Texture=true,MeshPart=true,SpecialMesh=true,
 Sound=true,Animation=true,ParticleEmitter=true,Beam=true,Trail=true,SurfaceAppearance=true,VideoFrame=true,
}

local assetsReady=false
local assetsLoaded=0
local assetsTotal=0
local assetFailures=0
local seenAssets={}

local function collectAssets(root,out)
 if not root then return end
 for _,instance in ipairs(root:GetDescendants()) do
  if assetClasses[instance.ClassName] and not seenAssets[instance] then
   seenAssets[instance]=true
   table.insert(out,instance)
  end
 end
end

local function preloadBatch(batch)
 if #batch==0 then return true end
 assetsTotal+=#batch
 local finished=0
 while true do
  local ok,err=pcall(function()
   ContentProvider:PreloadAsync(batch,function(_,fetchStatus)
    finished+=1
    assetsLoaded+=1
    if fetchStatus==Enum.AssetFetchStatus.Failure then assetFailures+=1 end
   end)
  end)
  if ok then return true end
  warn("[BloomLoading] PreloadAsync failed; retrying batch:",err)
  status.Text="RETRYING ASSET LOAD"
  detail.Text="Roblox asset service is not ready yet. Retrying automatically…"
  task.wait(1)
 end
end

task.spawn(function()
 if not game:IsLoaded() then game.Loaded:Wait() end
 while gui.Parent and not player:GetAttribute("BloomStateReady") do
  if player:GetAttribute("BloomClientBootState")=="Failed" then return end
  task.wait(.05)
 end
 if not gui.Parent then return end

 local stablePasses=0
 while gui.Parent and stablePasses<2 do
  local batch={}
  collectAssets(RS,batch)
  collectAssets(playerGui,batch)
  collectAssets(RF,batch)
  collectAssets(SoundService,batch)
  collectAssets(workspace,batch)
  if #batch==0 then
   stablePasses+=1
  else
   stablePasses=0
   preloadBatch(batch)
  end
  task.wait()
 end

 assetsReady=true
 player:SetAttribute("BloomAssetsReady",true)
 print(string.format("[BloomLoading] Critical preload complete assets=%d failed=%d",assetsLoaded,assetFailures))
end)

local function readiness()
 local loaded=game:IsLoaded()
 local profileState=player:GetAttribute("BloomProfileState")
 local profile=profileState=="Active" or profileState=="Saving"
 local server=player:GetAttribute("BloomGameplayReady")==true
 local client=player:GetAttribute("BloomClientReady")==true
 local state=player:GetAttribute("BloomStateReady")==true
 return loaded,profile,server,client,state,assetsReady,profileState
end

local function setProgress(value)
 value=math.clamp(value,0,1)
 TweenService:Create(fill,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{
  Size=UDim2.fromScale(value,1),
 }):Play()
 percent.Text=tostring(math.floor(value*100+.5)).."%"
end

local dots=0
local ready=false
while gui.Parent and not ready do
 dots=(dots+1)%4
 local loaded,profile,server,client,state,assets,profileState=readiness()
 local bootState=player:GetAttribute("BloomClientBootState")
 local bootError=player:GetAttribute("BloomClientBootError")
 local profileError=player:GetAttribute("BloomProfileError")

 if bootState=="Failed" then
  status.Text="CLIENT STARTUP ERROR"
  status.TextColor3=Color3.fromRGB(255,110,110)
  detail.Text="The game client did not initialize. Check Output for the first Bloom client error."
  subtitle.Text=tostring(bootError or "Client initialization failed.")
  setProgress(math.max(fill.Size.X.Scale,.55))
  task.wait(.25)
  continue
 end

 if profileError or profileState=="Failed" or profileState=="RecoveryFailed" or profileState=="Lost" or profileState=="UnknownOutcome" then
  status.Text="PROFILE ERROR"
  status.TextColor3=Color3.fromRGB(255,110,110)
  detail.Text="Your profile could not be opened safely. The loading screen will not enter gameplay."
  subtitle.Text=tostring(profileError or profileState or "Profile initialization failed.")
  setProgress(math.max(fill.Size.X.Scale,.25))
  task.wait(.25)
  continue
 end

 local assetFraction=assets and 1 or (assetsTotal>0 and math.clamp(assetsLoaded/assetsTotal,0,.98) or 0)
 local progress=(
  (loaded and 1 or 0)
  +(profile and 1 or 0)
  +(server and 1 or 0)
  +(client and 1 or 0)
  +(state and 1 or 0)
  +assetFraction
 )/6
 setProgress(progress)

 status.TextColor3=Color3.fromRGB(116,136,156)
 if not loaded then
  status.Text="LOADING EXPERIENCE"..string.rep(".",dots)
  detail.Text="Waiting for Roblox replication to finish."
 elseif not profile then
  status.Text="LOADING PROFILE"..string.rep(".",dots)
  detail.Text="Opening your server-authoritative save safely."
 elseif not server then
  status.Text="BUILDING WORLD"..string.rep(".",dots)
  detail.Text="Preparing your garden, map and gameplay services."
 elseif not client then
  status.Text="STARTING CLIENT"..string.rep(".",dots)
  detail.Text="Connecting UI controllers and runtime events."
 elseif not state then
  status.Text="SYNCING GAME STATE"..string.rep(".",dots)
  detail.Text="Waiting for the first authoritative state and HUD render."
 elseif not assets then
  status.Text="PRELOADING ASSETS"..string.rep(".",dots)
  if assetsTotal>0 then
   detail.Text=string.format("Preparing images, sounds and world assets • %d/%d",math.min(assetsLoaded,assetsTotal),assetsTotal)
  else
   detail.Text="Scanning rendered UI and world assets."
  end
 else
  ready=true
 end

 if not ready then task.wait(.1) end
end

if not gui.Parent then
 ContextActionService:UnbindAction(BLOCK_ACTION)
 return
end

player:SetAttribute("BloomGameReady",true)
status.TextColor3=Color3.fromRGB(102,224,166)
status.Text="READY"
detail.Text=assetFailures>0
 and string.format("Gameplay ready • %d unavailable asset request(s) were reported to Output.",assetFailures)
 or "Profile, world, UI, state and critical assets are ready."
setProgress(1)

task.wait(.12)
ContextActionService:UnbindAction(BLOCK_ACTION)

local fade=TweenService:Create(bg,TweenInfo.new(.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1})
fade:Play()
for _,x in ipairs(card:GetDescendants()) do
 if x:IsA("TextLabel") then
  TweenService:Create(x,TweenInfo.new(.2),{TextTransparency=1}):Play()
 elseif x:IsA("Frame") then
  TweenService:Create(x,TweenInfo.new(.2),{BackgroundTransparency=1}):Play()
 elseif x:IsA("UIStroke") then
  TweenService:Create(x,TweenInfo.new(.2),{Transparency=1}):Play()
 end
end
task.wait(.3)
gui:Destroy()
