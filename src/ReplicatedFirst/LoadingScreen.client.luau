local Players=game:GetService("Players")
local RF=game:GetService("ReplicatedFirst")
local TweenService=game:GetService("TweenService")

RF:RemoveDefaultLoadingScreen()
local player=Players.LocalPlayer
local playerGui=player:WaitForChild("PlayerGui")
local old=playerGui:FindFirstChild("BloomLoading")
if old then old:Destroy() end

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
card.Size=UDim2.fromOffset(440,166)
card.BackgroundColor3=Color3.fromRGB(20,27,36)
card.BorderSizePixel=0
card.Parent=bg
local cardCorner=Instance.new("UICorner") cardCorner.CornerRadius=UDim.new(0,20) cardCorner.Parent=card
local cardStroke=Instance.new("UIStroke") cardStroke.Color=Color3.fromRGB(7,10,14) cardStroke.Thickness=3 cardStroke.Parent=card

local accent=Instance.new("Frame")
accent.Size=UDim2.fromOffset(5,58)
accent.Position=UDim2.fromOffset(18,24)
accent.BackgroundColor3=Color3.fromRGB(84,174,255)
accent.BorderSizePixel=0
accent.Parent=card

local title=Instance.new("TextLabel")
title.Size=UDim2.new(1,-64,0,34)
title.Position=UDim2.fromOffset(36,22)
title.BackgroundTransparency=1
title.Text="BLOOM RNG"
title.TextColor3=Color3.fromRGB(245,248,252)
title.TextSize=25
title.Font=Enum.Font.GothamBlack
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=card

local subtitle=Instance.new("TextLabel")
subtitle.Size=UDim2.new(1,-64,0,24)
subtitle.Position=UDim2.fromOffset(36,57)
subtitle.BackgroundTransparency=1
subtitle.Text="Подготавливаем сад и профиль…"
subtitle.TextColor3=Color3.fromRGB(166,184,202)
subtitle.TextSize=12
subtitle.Font=Enum.Font.Gotham
subtitle.TextXAlignment=Enum.TextXAlignment.Left
subtitle.Parent=card

local track=Instance.new("Frame")
track.Size=UDim2.new(1,-72,0,10)
track.Position=UDim2.fromOffset(36,108)
track.BackgroundColor3=Color3.fromRGB(34,45,58)
track.BorderSizePixel=0
track.Parent=card
local trackCorner=Instance.new("UICorner") trackCorner.CornerRadius=UDim.new(0,5) trackCorner.Parent=track

local fill=Instance.new("Frame")
fill.Size=UDim2.fromScale(.18,1)
fill.BackgroundColor3=Color3.fromRGB(102,224,166)
fill.BorderSizePixel=0
fill.Parent=track
local fillCorner=Instance.new("UICorner") fillCorner.CornerRadius=UDim.new(0,5) fillCorner.Parent=fill
local gradient=Instance.new("UIGradient")
gradient.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(84,174,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(102,224,166))})
gradient.Parent=fill

local status=Instance.new("TextLabel")
status.Size=UDim2.new(1,-72,0,20)
status.Position=UDim2.fromOffset(36,126)
status.BackgroundTransparency=1
status.Text="CONNECTING"
status.TextColor3=Color3.fromRGB(116,136,156)
status.TextSize=10
status.Font=Enum.Font.GothamBold
status.TextXAlignment=Enum.TextXAlignment.Left
status.Parent=card

local scale=Instance.new("UIScale") scale.Parent=card
local function resize()
 local camera=workspace.CurrentCamera
 local w=camera and camera.ViewportSize.X or 1366
 scale.Scale=math.clamp((w-24)/440,.62,1)
end
resize()
if workspace.CurrentCamera then workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(resize) end

local running=true
task.spawn(function()
 local dots=0
 while running and gui.Parent do
  dots=(dots+1)%4
  local profileState=player:GetAttribute("BloomProfileState")
  if profileState=="Loading" then status.Text="LOADING PROFILE"..string.rep(".",dots)
  elseif profileState=="Active" and not player:GetAttribute("BloomClientReady") then status.Text="SYNCING UI"..string.rep(".",dots)
  elseif profileState=="Failed" then status.Text="PROFILE ERROR"
  else status.Text="CONNECTING"..string.rep(".",dots) end
  local goal=fill.Size.X.Scale>.72 and .22 or .82
  TweenService:Create(fill,TweenInfo.new(.65,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Size=UDim2.fromScale(goal,1)}):Play()
  task.wait(.7)
 end
end)

local start=os.clock()
while not player:GetAttribute("BloomClientReady") and os.clock()-start<30 do task.wait(.1) end
running=false
status.Text=player:GetAttribute("BloomClientReady") and "READY" or "CONTINUING…"
TweenService:Create(fill,TweenInfo.new(.18),{Size=UDim2.fromScale(1,1)}):Play()
task.wait(.2)
local fade=TweenService:Create(bg,TweenInfo.new(.22),{BackgroundTransparency=1})
fade:Play()
for _,x in ipairs(card:GetDescendants()) do
 if x:IsA("TextLabel") then TweenService:Create(x,TweenInfo.new(.18),{TextTransparency=1}):Play()
 elseif x:IsA("Frame") then TweenService:Create(x,TweenInfo.new(.18),{BackgroundTransparency=1}):Play() end
end
task.wait(.24)
gui:Destroy()
