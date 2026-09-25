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

local template=RF:WaitForChild("BloomLoadingTemplate",10)
if not template or not template:IsA("ScreenGui") then
 error("[BloomLoading] Authored ReplicatedFirst/BloomLoadingTemplate ScreenGui is missing")
end
local gui=template:Clone()
gui.Name="BloomLoading"
gui.Enabled=true
gui.Parent=playerGui

local bg=gui:WaitForChild("Background")
local card=bg:WaitForChild("Card")
local title=card:WaitForChild("Title")
local percent=card:WaitForChild("Percent")
local subtitle=card:WaitForChild("Subtitle")
local track=card:WaitForChild("ProgressTrack")
local fill=track:WaitForChild("ProgressFill")
local status=card:WaitForChild("Status")
local detail=card:WaitForChild("Detail")
local scale=card:WaitForChild("ResponsiveScale")
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
