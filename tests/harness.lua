local nativeRequire=require
local Node={}
function Node:WaitForChild(name) return self[name] end
local function node(path)
 return setmetatable({path=path},{__index=function(t,k) if Node[k] then return Node[k] end if k=="Parent" then return node(path:match("^(.*)/") or "") end return node(path=="" and k or path.."/"..k) end})
end
local colors={} function colors:Lerp(other,a) return self end
Color3={new=function(...) return setmetatable({...},{__index=colors}) end};Color3.fromRGB=Color3.new
local V={}
local vmt={__index=function(v,k) if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) elseif k=="Unit" then return v/v.Magnitude else return V[k] end end}
Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vmt) end}
vmt.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
vmt.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
vmt.__mul=function(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
vmt.__div=function(a,b) return Vector3.new(a.X/b,a.Y/b,a.Z/b) end
function V:Lerp(other,a) return self+(other-self)*a end
Vector3.zero=Vector3.new(0,0,0)
math.clamp=function(x,a,b) return math.max(a,math.min(b,x)) end
math.atan2=math.atan
table.clear=function(t) for k in pairs(t) do t[k]=nil end end
table.find=function(t,x) for i,v in pairs(t) do if v==x then return i end end end
table.freeze=function(t) return t end
table.create=function() return {} end
typeof=type
Random={new=function() return {NextNumber=function(_,a,b) local r=math.random() if a then return a+r*(b-a) end return r end} end}
workspace={GetServerTimeNow=function() return os.clock() end}
local rs=node("ReplicatedStorage")
game={GetService=function(_,name) if name=="ReplicatedStorage" then return rs elseif name=="HttpService" then return {GenerateGUID=function() return tostring(math.random()) end} end return node(name) end}
local sources={}
sources["ReplicatedFirst/LoadingScreen.client"]=[========[local Players=game:GetService("Players")
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
]========]
sources["ServerScriptService/ServerBootstrap.server"]=[========[local Services=script.Parent.Services
-- Remove incompatible LocalScripts left behind when this Rojo place was merged with an older Fruit RNG place.
-- These clients wait for the retired ReplicatedStorage.Remotes and Workspace.Garden.PlayerGardens APIs.
local Players=game:GetService("Players")
local StarterPlayer=game:GetService("StarterPlayer")
local LEGACY_CLIENTS={ProgressionHub=true,CurrencyHUD=true,HiveHUD=true,TutorialGuide=true,FlowerBillboardController=true,QuestTracker=true,BeeTraitsHUD=true}
local function removeLegacy(folder:Instance?)
 if not folder then return end
 for _,item in ipairs(folder:GetDescendants()) do
  if item:IsA("LocalScript") and LEGACY_CLIENTS[item.Name] then
   warn("[Bloom RNG] Removed retired client script:",item:GetFullName())
   item:Destroy()
  end
 end
end
local starterScripts=StarterPlayer:FindFirstChild("StarterPlayerScripts")
removeLegacy(starterScripts)
Players.PlayerAdded:Connect(function(player)
 local scripts=player:WaitForChild("PlayerScripts",10)
 removeLegacy(scripts)
end)
for _,player in ipairs(Players:GetPlayers()) do task.spawn(function() removeLegacy(player:FindFirstChild("PlayerScripts")) end) end

local Data=require(Services.DataService)
local Player=require(Services.PlayerService)
local names={"RemoteService","FlowerService","InventoryService","StatsService","FlowerProgressionService","GardenSynergyService","GardenPlotService","HiveService","RollService","GardenActivityService","PollinatorService","MapService","WorkshopService","TutorialService","MetaProgressionService","BuildTrialService","SeasonService","SocialService","AnalyticsService"}
local loaded={} for _,name in ipairs(names) do loaded[name]=require(Services[name]) end
local ok,err=xpcall(function()
 require(script.Parent.Tests.ConfigValidation).Run()
 Data:Init() Player:Start(Data,loaded,names) Data:Start() print("[BLOOM RNG] server ready")
end,debug.traceback)
if not ok then error("[BLOOM RNG] boot failed: "..tostring(err)) end
]========]
sources["ServerScriptService/Data/ProfileSchema"]=[========[local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local Flowers=require(RS.Config.FlowersConfig)
local Bees=require(RS.Config.BeesConfig)
local Default=require(script.Parent.DefaultProfile)
local Mapping=require(script.Parent.LegacyBloomMapping)
local S={}
local function reconcile(p,d) for k,v in pairs(d) do if type(p[k])~=type(v) then p[k]=U.Copy(v) elseif type(v)=="table" then reconcile(p[k],v) end end end
local function valid(v,seen,depth)
 if depth>64 then return false,"Depth limit" end
 local t=type(v) if t=="number" then return v==v and math.abs(v)<math.huge,"Invalid number" end
 if t=="string" or t=="boolean" or t=="nil" then return true end
 if t~="table" or seen[v] then return false,"Unsupported/cyclic value" end seen[v]=true
 for k,x in pairs(v) do if type(k)~="string" and type(k)~="number" then return false,"Invalid key" end local ok,err=valid(x,seen,depth+1) if not ok then return ok,err end end seen[v]=nil return true
end
function S.Validate(p) if type(p)~="table" then return false,"Profile must be a table" end return valid(p,{},0) end
function S.CreateDefault() return U.Copy(Default) end
function S.Reconcile(p) if type(p)~="table" then return false,"Profile must be a table" end reconcile(p,Default) return true end
function S.Prepare(p)
 local ok,err=S.Validate(p) if not ok then return false,err end
 local n=U.Copy(p) local migrate=not(n.Migrations and n.Migrations.BloomReworkV1)
 -- Do not seed defaults into a returning player's empty garden or add starter inventory twice.
 local savedSlots=type(n.Garden)=="table" and type(n.Garden.Slots)=="table" and U.Copy(n.Garden.Slots)
 local savedCopies=type(n.FlowerCollection)=="table" and type(n.FlowerCollection.OwnedSeedCopies)=="table" and U.Copy(n.FlowerCollection.OwnedSeedCopies)
 reconcile(n,Default)
 if savedSlots then n.Garden.Slots=savedSlots end
 if savedCopies then n.FlowerCollection.OwnedSeedCopies=savedCopies end
 if migrate then
  local legacyCurrencies=type(p.Currencies)=="table" and p.Currencies or {}
  local legacyWorkshop=type(p.WorkshopV2)=="table" and p.WorkshopV2 or {}
  local legacySectors=type(p.UnlockedSectors)=="table" and p.UnlockedSectors or {}
  local f=n.FlowerCollection local dust=U.Number(legacyCurrencies.FruitDust)
  for id,count in pairs(type(p.Inventory)=="table" and p.Inventory or {}) do
   count=math.floor(U.Number(count)) local target=Mapping[id]
   if target then f.OwnedSeedCopies[target]=(f.OwnedSeedCopies[target] or 0)+count else dust=dust+count*C.UnknownCopyDust end
  end
  for id,discovered in pairs(type(p.DiscoveredFruits)=="table" and p.DiscoveredFruits or {}) do if discovered and Mapping[id] then f.DiscoveredFlowers[Mapping[id]]=true end end
  for id,m in pairs(type(p.FruitMastery)=="table" and p.FruitMastery or {}) do
   local target=Mapping[id] if target then local level=type(m)=="table" and m.Level or m
    local previous=f.FlowerMastery[target] or {Level=1,XP=0}
    previous.Level=math.max(previous.Level,math.clamp(U.Number(level,1),1,C.MasteryCap)) f.FlowerMastery[target]=previous
   end
  end
  for _ in pairs(type(p.FruitCombos)=="table" and type(p.FruitCombos.Discovered)=="table" and p.FruitCombos.Discovered or {}) do dust=dust+C.ComboCompensation end
  n.Currencies.PetalDust=U.Number(n.Currencies.PetalDust)+dust
  -- AncientSeeds provenance is ambiguous: archive, do not turn it into earned Nectar.
  n.LegacyArchive={AncientSeeds=legacyCurrencies.AncientSeeds or 0,ResearchNodes=p.ResearchNodes,WorkshopV2=p.WorkshopV2}
  n.World.UnlockedSectors.SunnyOrchard=legacySectors.StarterOrchard or false
  for _,id in ipairs({"CrystalGreenhouse","TwilightGrove"}) do n.World.UnlockedSectors[id]=legacySectors[id]==true or false end
  n.WorkshopV5.Points=math.max(n.WorkshopV5.Points,U.Number(legacyWorkshop.Points))
  n.Migrations.BloomSummary={PetalDust=dust,Version=C.SchemaVersion}
  -- Existing physical flowers are granted enough ownership to preserve their planted layout.
  local counts={} for _,slot in pairs(n.Garden.Slots) do if type(slot)=="table" and Flowers.Exists(slot.SpeciesId) then counts[slot.SpeciesId]=(counts[slot.SpeciesId] or 0)+1 end end
  for id,count in pairs(counts) do f.OwnedSeedCopies[id]=math.max(f.OwnedSeedCopies[id] or 0,count) f.DiscoveredFlowers[id]=true end
 end
 for _,k in ipairs({"Coins","PetalDust","AncientNectar"}) do n.Currencies[k]=U.Number(n.Currencies[k]) end
 n.Hive.Level=math.clamp(math.floor(U.Number(n.Hive.Level,1)),1,#C.HiveCosts)
 n.Garden.UnlockedSlots=math.clamp(math.floor(U.Number(n.Garden.UnlockedSlots,3)),3,C.MaxFlowerSlots)
 for id,count in pairs(n.FlowerCollection.OwnedSeedCopies) do n.FlowerCollection.OwnedSeedCopies[id]=math.floor(U.Number(count)) end
 for i=1,C.MaxFlowerSlots do local slot=n.Garden.Slots[i] or n.Garden.Slots[tostring(i)] or {} n.Garden.Slots[tostring(i)]=nil if type(slot)~="table" then slot={} end
  if i>n.Garden.UnlockedSlots or not Flowers.Exists(slot.SpeciesId) then slot={} else slot.Level=math.clamp(U.Number(slot.Level,1),1,C.MasteryCap) slot.XP=U.Number(slot.XP) slot.TotalPollination=U.Number(slot.TotalPollination) slot.Mutation=type(slot.Mutation)=="string" and slot.Mutation or "" end
  n.Garden.Slots[i]=slot
 end
 for id,count in pairs(n.Pollinators.BeeInventory) do n.Pollinators.BeeInventory[id]=Bees.Exists(id) and math.floor(U.Number(count)) or nil end
 local equipped={} local equippedCounts={}
 for i=1,C.MaxBeeSlots do local id=n.Pollinators.EquippedBeeSlots[i] or n.Pollinators.EquippedBeeSlots[tostring(i)]
  if type(id)=="string" and Bees.Exists(id) and (equippedCounts[id] or 0)<(n.Pollinators.BeeInventory[id] or 0) then equipped[i]=id equippedCounts[id]=(equippedCounts[id] or 0)+1 end
 end n.Pollinators.EquippedBeeSlots=equipped
 for id,m in pairs(n.Pollinators.BeeMastery) do if type(m)=="table" then n.Pollinators.BeeMastery[id]=U.Number(m.XP)+U.Number(m.Level)*25 else n.Pollinators.BeeMastery[id]=U.Number(m) end end
 for id,m in pairs(n.FlowerCollection.FlowerMastery) do if type(m)~="table" then m={Level=1,XP=0} n.FlowerCollection.FlowerMastery[id]=m end m.Level=math.clamp(U.Number(m.Level,1),1,C.MasteryCap) m.XP=U.Number(m.XP) end
 local planted={} for _,slot in ipairs(n.Garden.Slots) do if slot.SpeciesId then local id=slot.SpeciesId planted[id]=(planted[id] or 0)+1 if planted[id]>(n.FlowerCollection.OwnedSeedCopies[id] or 0) then table.clear(slot) end end end
 n.RollState.TotalRolls=math.floor(U.Number(n.RollState.TotalRolls)) n.RollState.DiscoveryPity=math.floor(U.Number(n.RollState.DiscoveryPity))
 n.RollState.BloomCharge=U.Number(n.RollState.BloomCharge,0,C.BloomMax) n.RollState.SpecialRollReady=n.RollState.BloomCharge>=C.BloomMax
 n.SchemaVersion=C.SchemaVersion
 for _,key in ipairs({"StarterFruitGranted","ClaimedIndexMilestones","Inventory","DiscoveredFruits","EquippedFruitIds","LockedFruits","FruitMastery","FruitCombos","ResearchNodes","WorkshopV2","WorkshopLevels","ActiveLocationTheme","OwnedLocations","UnlockedSectors","TutorialProgress","TutorialVersion","TutorialStep","TutorialSkipped"}) do n[key]=nil end
 n.Currencies.FruitDust=nil n.Currencies.AncientSeeds=nil n.Garden.OwnedFlowerTypes=nil
 n.Migrations.BloomReworkV1=true
 ok,err=S.Validate(n) if not ok then return false,err end
 table.clear(p) for k,v in pairs(n) do p[k]=v end return true
end
S.Create=S.CreateDefault S.Sanitize=S.Prepare
return S
]========]
sources["ServerScriptService/Data/DataConfig"]=[========[--!strict
local RunService =
game:GetService("RunService")
local DataConfig = {}
DataConfig.ProductionStoreName =
"FruitRNG_PlayerProfiles_v1"
DataConfig.StudioStoreName =
"FruitRNG_PlayerProfiles_TEST_v1"
DataConfig.KeyPrefix =
"Player_"
DataConfig.SessionLeaseSeconds =
180
DataConfig.AutosaveMinSeconds =
60
DataConfig.AutosaveMaxSeconds =
90
DataConfig.MaxRetries =
3
DataConfig.RetryBaseSeconds =
1
function DataConfig.GetStoreName(): string
if RunService:IsStudio() then
return DataConfig.StudioStoreName
end
return DataConfig.ProductionStoreName
end
return DataConfig
]========]
sources["ServerScriptService/Data/LegacyBloomMapping"]=[========[return {Apple="Daisy",Banana="Tulip",Lemon="Sunflower",Pear="Clover",Kiwi="FrostLily",Watermelon="CrystalRose",Coconut="PrismBloom",Pomegranate="Nightshade",Dragonfruit="EmberDahlia",Peach="Daisy",Grape="MoonOrchid",Pineapple="Clover",Starfruit="StarBloom"}
]========]
sources["ServerScriptService/Data/DefaultProfile"]=[========[return {SchemaVersion=5,Currencies={Coins=0,PetalDust=0,AncientNectar=0},Migrations={BloomReworkV1=true},RollState={TotalRolls=0,BloomCharge=0,DiscoveryPity=0,SpecialRollReady=false},FlowerCollection={OwnedSeedCopies={Daisy=1},DiscoveredFlowers={Daisy=true},FlowerMastery={},LockedFlowers={},FavoriteFlowers={}},Garden={UnlockedSlots=3,Slots={{SpeciesId="Daisy",Level=1,XP=0,Mutation="",TotalPollination=0},{},{}},Revision=0},GardenSynergies={Discovered={},Mastery={}},Pollinators={BeeInventory={},DiscoveredBees={},EquippedBeeSlots={},BeeMastery={}},Hive={Level=1,Honey=0,TotalHoney=0},WorkshopV5={Points=0,Nodes={},LegacyNodes={},ClaimedSources={}},World={UnlockedSectors={Center=true},LandmarkDiscoveries={},EventStats={}},Season={Count=0,ActiveCard="",Keepsakes={},CompletedGoals={}},Tutorial={Version=2,Step=1,FeatureUnlocks={},Events={}},Quests={JourneyStep=1,Claimed={},Trials={}},Settings={ReducedEffects=false,ShowOtherPollinators=true,HideOtherPlayersTokens=true,RareFeed=true,TokenSoundVolume=.5,AutoDissolve=false,DissolveRarities={}},Telemetry={Once={},Counters={}}}
]========]
sources["ServerScriptService/Services/FlowerService"]=[========[local RS=game:GetService("ReplicatedStorage")
local Theme=require(RS.Config.UIThemeConfig)
local UIColors=Theme.Colors

local function part(parent: Instance, name: string, size: Vector3, color: Color3, shape: Enum.PartType?, material: Enum.Material?, transparency: number?): Part
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Anchored = true
    p.CanCollide = name == "Ground" or name == "Border"
    p.CanTouch = false
    p.CanQuery = true
    p.CastShadow = true
    p.Material = material or Enum.Material.SmoothPlastic
    p.Transparency = transparency or 0
    if shape then p.Shape = shape end
    p.Parent = parent
    return p
end

local function roundedBillboard(parent: BasePart, name: string, size: UDim2, studs: Vector3): (BillboardGui, TextLabel)
    local b = Instance.new("BillboardGui")
    b.Name = name
    b.Size = size
    b.StudsOffset = studs
    b.AlwaysOnTop = true
    b.MaxDistance = 125
    b.Parent = parent
    local t = Instance.new("TextLabel")
    t.Name = "Text"
    t.Size = UDim2.fromScale(1, 1)
    t.BackgroundColor3 = Color3.fromRGB(25, 35, 46)
    t.BackgroundTransparency = .10
    t.BorderSizePixel = 0
    t.TextColor3 = Color3.fromRGB(244, 249, 255)
    t.TextStrokeTransparency = .6
    t.Font = Enum.Font.GothamBold
    t.TextSize = 12
    t.TextWrapped = true
    t.Parent = b
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = t
    return b, t
end

local function stem(parent: Model, pos: Vector3, h: number, color: Color3): Part
    local x = part(parent, "Stem", Vector3.new(h, .34, .34), color, Enum.PartType.Cylinder)
    x.CanCollide = false
    x.CFrame = CFrame.new(pos + Vector3.new(0, h * .5, 0)) * CFrame.Angles(0, 0, math.rad(90))
    return x
end

local function petal(parent: Model, name: string, center: Vector3, angle: number, dist: number, size: Vector3, color: Color3, tilt: number?): Part
    local x = part(parent, name, size, color, Enum.PartType.Ball)
    x.CanCollide = false
    x.CFrame = CFrame.new(center + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)) * CFrame.Angles(math.rad(tilt or 10), angle, 0)
    return x
end

local function makeFlowerModel(slotId: number, species: any, position: Vector3): Model
    local m = Instance.new("Model")
    m.Name = string.format("FlowerSlot_%02d", slotId)
    local root = part(m, "Root", Vector3.new(.2, .2, .2), Color3.new(1, 1, 1), nil, nil, 1)
    root.CanCollide = false
    root.CanQuery = false
    root.CFrame = CFrame.new(position)
    m.PrimaryPart = root

    local angle = (slotId * 1.37) % (math.pi * 2)
    local h = 2.45
    stem(m, position, h, Color3.fromRGB(70, 159, 88))
    for leafIndex, leafAngle in ipairs({angle + .7, angle + 3.55}) do
        local y = leafIndex == 1 and .76 or 1.20
        local leaf = part(m, "Leaf" .. leafIndex, Vector3.new(.8, .16, 1.25), Color3.fromRGB(83, 178, 97), Enum.PartType.Ball)
        leaf.CanCollide = false
        leaf.CFrame = CFrame.new(position + Vector3.new(math.cos(leafAngle) * .46, y, math.sin(leafAngle) * .46)) * CFrame.Angles(math.rad(22), leafAngle, math.rad(28))
    end

    local center = position + Vector3.new(0, h + .18, 0)
    local bloom = part(m, "Bloom", Vector3.new(.58, .58, .58), species.AccentColor, Enum.PartType.Ball)
    bloom.CanCollide = false
    bloom.CFrame = CFrame.new(center)
    local key = species.ShapeKey
    if key == "Daisy" then
        for i = 1, 8 do petal(m, "Petal"..i, center, i / 8 * math.pi * 2, .58, Vector3.new(.52, .18, .98), species.Color, 12) end
    elseif key == "Tulip" then
        bloom.Size = Vector3.new(.45, .45, .45)
        for i = 1, 5 do
            local a = i / 5 * math.pi * 2
            local x = part(m, "Petal"..i, Vector3.new(.38, .76, .56), species.Color, Enum.PartType.Ball)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .2, .18, math.sin(a) * .2)) * CFrame.Angles(math.rad(-18), a, 0)
        end
    elseif key == "Sunflower" then
        bloom.Size = Vector3.new(.82, .82, .82)
        bloom.Color = species.AccentColor
        for i = 1, 12 do petal(m, "Petal"..i, center, i / 12 * math.pi * 2, .78, Vector3.new(.42, .15, 1.02), species.Color, 16) end
    elseif key == "Clover" then
        bloom:Destroy()
        for i = 1, 4 do
            local a = i / 4 * math.pi * 2 + math.rad(45)
            local x = part(m, "Petal"..i, Vector3.new(.78, .18, .78), species.Color, Enum.PartType.Ball)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .31, 0, math.sin(a) * .31))
        end
        bloom = part(m, "Bloom", Vector3.new(.24, .24, .24), species.AccentColor, Enum.PartType.Ball)
        bloom.CanCollide = false
        bloom.CFrame = CFrame.new(center)
    elseif key == "CrystalRose" or key == "PrismBloom" then
        bloom.Size = Vector3.new(.42, .42, .42)
        for i = 1, 7 do
            local a = i / 7 * math.pi * 2
            local x = part(m, "Crystal"..i, Vector3.new(.18, .72, .42), i % 2 == 0 and species.Color or species.AccentColor, Enum.PartType.Block, Enum.Material.Neon)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .34, .12, math.sin(a) * .34)) * CFrame.Angles(math.rad(28), a, math.rad(28))
        end
    elseif key == "FrostLily" or key == "MoonOrchid" then
        for i = 1, 6 do petal(m, "Petal"..i, center, i / 6 * math.pi * 2, .58, Vector3.new(.40, .14, 1.18), i % 2 == 0 and species.Color or species.AccentColor, 22) end
    elseif key == "VoidLotus" then
        bloom.Size = Vector3.new(.38, .38, .38)
        for i = 1, 9 do petal(m, "Petal"..i, center, i / 9 * math.pi * 2, .65, Vector3.new(.42, .14, 1.02), i % 2 == 0 and species.Color or species.AccentColor, 10) end
    elseif key == "StarBloom" then
        bloom.Size = Vector3.new(.30, .30, .30)
        for i = 1, 5 do
            local a = i / 5 * math.pi * 2
            local x = part(m, "Accent"..i, Vector3.new(.18, .18, 1.30), species.Color, Enum.PartType.Block, Enum.Material.Neon)
            x.CanCollide = false
            x.CFrame = CFrame.new(center + Vector3.new(math.cos(a) * .27, 0, math.sin(a) * .27)) * CFrame.Angles(0, a, math.rad(45))
        end
    elseif key == "EmberDahlia" then
        bloom.Size = Vector3.new(.46, .46, .46)
        for ring = 1, 2 do
            for i = 1, 8 do petal(m, "Petal"..ring.."_"..i, center + Vector3.new(0, (ring - 1) * .08, 0), i / 8 * math.pi * 2, .38 + ring * .18, Vector3.new(.34, .12, .80), ring == 1 and species.AccentColor or species.Color, 18) end
        end
    else
        for i = 1, 6 do petal(m, "Petal"..i, center, i / 6 * math.pi * 2, .52, Vector3.new(.42, .16, .9), species.Color, 18) end
    end

    local info = Instance.new("BillboardGui")
    info.Name = "FlowerInfo"
    info.Size = UDim2.fromOffset(178, 58)
    info.StudsOffset = Vector3.new(0, 3.9, 0)
    info.AlwaysOnTop = true
    info.MaxDistance = 68
    info.LightInfluence = 0
    info.Parent = bloom

    local card = Instance.new("Frame")
    card.Name = "Card"
    card.Size = UDim2.fromScale(1, 1)
    card.BackgroundColor3 = UIColors.Panel
    card.BackgroundTransparency = .08
    card.BorderSizePixel = 0
    card.Parent = info
    local cardCorner = Instance.new("UICorner")
    cardCorner.CornerRadius = UDim.new(0, 12)
    cardCorner.Parent = card
    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = UIColors.BorderDark
    cardStroke.Thickness = 2
    cardStroke.Transparency = .05
    cardStroke.Parent = card

    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.fromOffset(4, 28)
    accent.Position = UDim2.fromOffset(8, 8)
    accent.BackgroundColor3 = species.AccentColor
    accent.BorderSizePixel = 0
    accent.Parent = card
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 2)
    accentCorner.Parent = accent

    local tx = Instance.new("TextLabel")
    tx.Name = "LevelText"
    tx.Position = UDim2.fromOffset(18, 6)
    tx.Size = UDim2.new(1, -28, 0, 27)
    tx.BackgroundTransparency = 1
    tx.TextColor3 = UIColors.Text
    tx.TextStrokeTransparency = 1
    tx.Font = Enum.Font.GothamBold
    tx.TextSize = 11
    tx.TextXAlignment = Enum.TextXAlignment.Left
    tx.TextTruncate = Enum.TextTruncate.AtEnd
    tx.Text = species.DisplayName .. "  •  LV.1"
    tx.Parent = card

    local bg = Instance.new("Frame")
    bg.Name = "ProgressBG"
    bg.Position = UDim2.fromOffset(18, 38)
    bg.Size = UDim2.new(1, -30, 0, 8)
    bg.BackgroundColor3 = UIColors.PanelRaised
    bg.BorderSizePixel = 0
    bg.Parent = card
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(1, 0)
    c.Parent = bg

    local fl = Instance.new("Frame")
    fl.Name = "ProgressFill"
    fl.Size = UDim2.fromScale(0, 1)
    fl.BackgroundColor3 = species.AccentColor
    fl.BorderSizePixel = 0
    fl.Parent = bg
    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(1, 0)
    c2.Parent = fl
    return m
end


local S={}
S.Build=makeFlowerModel
return S
]========]
sources["ServerScriptService/Services/MapService"]=[========[local RS=game:GetService("ReplicatedStorage") local L=require(RS.Config.LocationsConfig) local C=require(RS.Config.BloomConfig) local S={Landmarks={},Gates={}}
function S:Init(x) self.X=x end
function S:Sector(player) local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") if not root then return "Center" end for id,s in pairs(L.Sectors) do if (root.Position-(self.X.Origin+s.Center)).Magnitude<55 then return id end end return "Center" end
function S:Unlock(player,id)
 local p=self.X:Profile(player) local s=L.Sectors[id] if not p or not s or not self.X.U.Near(player,self.Gates[id].Position,C.InteractionDistance) or p.Hive.Level<s.Hive then return false end
 if not p.World.UnlockedSectors[id] then p.World.UnlockedSectors[id]=true self.X:Send(player,"Ceremony",{Kind="Sector",Text=s.Name.." unlocked"}) end return true
end
function S:Build()
 local centerFlower=self.X.FlowerService.Build(1,require(RS.Config.FlowersConfig).Species.StarBloom,self.X.Origin+Vector3.new(0,1,0)) centerFlower.Name="ServerBloom" centerFlower:ScaleTo(3) centerFlower.Parent=self.X.World
 for id,s in pairs(L.Sectors) do local center=self.X.Origin+s.Center
  self.X:Part(self.X.World,id,center-Vector3.new(0,1,0),Vector3.new(95,2,95),s.Color,true)
  local dir=s.Center.Unit local gatePos=center-dir*47 local gate=self.X:Part(self.X.World,id.."Gate",gatePos+Vector3.new(0,3,0),Vector3.new(12,6,2),s.Color,false) self.Gates[id]=gate
  self.X:Prompt(gate,s.Name.." • Hive "..s.Hive,function(player) self:Unlock(player,id) end)
  for j=1,3 do local pos=center+Vector3.new((j-2)*22,1,(j%2)*15) local key=id.."_"..j
   local landmark=self.X:Part(self.X.World,key,pos,Vector3.new(3,7,3),s.Color:Lerp(Color3.new(1,1,1),.3),true) self.Landmarks[key]=pos
   self.X:Prompt(landmark,"Открыть место / активность",function(player)
    local p=self.X:Profile(player) if not p or not p.World.UnlockedSectors[id] then return end
    if not p.World.LandmarkDiscoveries[key] then p.World.LandmarkDiscoveries[key]=true p.Currencies.PetalDust=p.Currencies.PetalDust+3 self.X.RollService:Charge(player,10) self.X:Emit(player,"Landmark",1)
     if Random.new():NextNumber()<.02 then p.Cosmetics=p.Cosmetics or {} p.Cosmetics.WildBloomExplorer=true self.X:Send(player,"Message","Открыт титул Wild Bloom Explorer") end end
    self.X.GardenActivityService:Offer(player,s.Activity,pos,id)
   end)
  end
  local launch=self.X:Part(self.X.World,id.."Launch",center-dir*35,Vector3.new(5,.5,5),Color3.fromRGB(240,210,100),true)
  self.X:Prompt(launch,"Прыжок к центру",function(player) local p=self.X:Profile(player) if p and p.World.UnlockedSectors[id] and p.World.LandmarkDiscoveries[id.."_1"] and p.WorkshopV5.Nodes.EXPLORATION_6 then local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if root then root.AssemblyLinearVelocity=-dir*75+Vector3.new(0,65,0) end end end)
  local shrine=self.X:Part(self.X.World,id.."Shrine",center+Vector3.new(0,2,30),Vector3.new(6,4,6),Color3.fromRGB(230,210,150),true)
  self.X:Prompt(shrine,"Испытания сада",function(player) local p=self.X:Profile(player) if p and p.World.UnlockedSectors[id] then self.X:Send(player,"Trials",id) end end)
 end
 local workshop=self.X:Part(self.X.World,"Workshop",self.X.Origin+Vector3.new(12,2,0),Vector3.new(7,4,7),Color3.fromRGB(90,160,210),true)
 self.X:Prompt(workshop,"Открыть мастерскую",function(player) self.X:Emit(player,"WorkshopVisit",1) self.X:Send(player,"Open","Workshop") end)
 local tree=self.X:Part(self.X.World,"AncientTree",self.X.Origin+Vector3.new(-12,5,0),Vector3.new(6,10,6),Color3.fromRGB(140,100,170),true)
 self.X:Prompt(tree,"Season Turn",function(player) self.X.SeasonService:Preview(player) end)
end
function S:Tick(player)
 local p=self.X:Profile(player) local sector=self:Sector(player) if sector~="Center" and not p.World.UnlockedSectors[sector] then
  local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") if root then local s=L.Sectors[sector] root.CFrame=CFrame.new(self.X.Origin+s.Center-s.Center.Unit*62+Vector3.new(0,4,0)) end return
 end
 local pulse=self.X.SocialService.Pulse local temp=self.X.Temp[player]
 if p.Season.ActiveCard=="TwilightSeason" and sector=="TwilightGrove" and os.clock()>(temp.NextPersonalEclipse or 0) then temp.NextPersonalEclipse=os.clock()+90 temp.PersonalEclipseUntil=os.clock()+45 self.X.GardenActivityService:Offer(player,"FireflyRoute",self.X.Origin+L.Sectors[sector].Center,sector) end
 if pulse and pulse.Sector==sector and os.clock()>(temp.NextWild or 0) then temp.NextWild=os.clock()+25 self.X.GardenActivityService:Offer(player,sector=="TwilightGrove" and "ShadowBloom" or L.Sectors[sector].Activity,self.X.Origin+L.Sectors[sector].Center,sector) end
 if sector=="SunnyOrchard" then self.X:EmitOnce(player,"SunnyVisit") end
 local temp=self.X.Temp[player] if temp.Sector~=sector then temp.Sector=sector self.X.GardenSynergyService:Recalculate(player) end
end
return S
]========]
sources["ServerScriptService/Services/WorkshopService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.WorkshopConfig) local S={}
function S:Init(x) self.X=x end
function S:Point(player,key,amount) local p=self.X:Profile(player) local w=p.WorkshopV5 if w.ClaimedSources[key] then return end w.ClaimedSources[key]=true w.Points=w.Points+amount if w.Nodes.ECONOMY_4 then p.Currencies.Coins=p.Currencies.Coins+100 end end
function S:Buy(player,id)
 local p=self.X:Profile(player) local n=C.Nodes[id] if not p or not n or id=="CORE" or not p.Tutorial.FeatureUnlocks.Workshop then return false end local w=p.WorkshopV5
 if w.Nodes[id] or n.Parent~="CORE" and not w.Nodes[n.Parent] or p.Hive.Level<n.Hive or n.Branch=="LEGACY" and p.Season.Count==0 then return false end
 if w.Points<n.Cost or p.Currencies.Coins<n.Coins or p.Currencies.PetalDust<n.Dust or p.Currencies.AncientNectar<n.Nectar then return false end
 w.Points=w.Points-n.Cost p.Currencies.Coins=p.Currencies.Coins-n.Coins p.Currencies.PetalDust=p.Currencies.PetalDust-n.Dust p.Currencies.AncientNectar=p.Currencies.AncientNectar-n.Nectar w.Nodes[id]=true if n.Permanent then w.LegacyNodes[id]=true end
 self.X.GardenPlotService:RefreshCapacity(player) self.X.TutorialService:Refresh(player) self.X:Emit(player,"WorkshopPurchase",1) return true
end
function S:Respec(player)
 local p=self.X:Profile(player) if not p or not p.Tutorial.FeatureUnlocks.Workshop then return false end
 for id in pairs(p.WorkshopV5.Nodes) do local n=C.Nodes[id] if n and not n.Permanent then p.WorkshopV5.Points=p.WorkshopV5.Points+n.Cost p.Currencies.Coins=p.Currencies.Coins+n.Coins p.Currencies.PetalDust=p.Currencies.PetalDust+n.Dust p.WorkshopV5.Nodes[id]=nil end end
 -- Copies stay owned; only seasonal slot expansion is removed.
 local limit=self.X.StatsService:FlowerCapacity(p) for i=limit+1,15 do p.Garden.Slots[i]={} end
 for i=self.X.StatsService:BeeCapacity(p)+1,8 do p.Pollinators.EquippedBeeSlots[i]=nil end
 self.X.GardenPlotService:RefreshCapacity(player) self.X.TutorialService:Refresh(player) return true
end
return S
]========]
sources["ServerScriptService/Services/AnalyticsService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.AnalyticsConfig) local Analytics=game:GetService("AnalyticsService") local S={}
function S:Init(x) self.X=x end
function S:Event(player,event,n)
 local p=self.X:Profile(player) if not p then return end local t=p.Telemetry t.Counters[event]=(t.Counters[event] or 0)+n local name=C.Events[event]
 if name and not t.Once[name] then t.Once[name]=true if C.Enabled then task.spawn(function() pcall(function() Analytics:LogCustomEvent(player,name,1) end) end) end end
end
function S:Flush(player)
 local metrics=self:Snapshot(player) if not C.Enabled then return end
 task.spawn(function() for _,name in ipairs({"active_world_seconds","menu_open_seconds","idle_seconds","rolls_per_minute","auto_roll_share","activity_engagement","bloom_roll_frequency","garden_diversity","synergy_diversity","average_event_distance"}) do pcall(function() Analytics:LogCustomEvent(player,name,metrics[name] or 0) end) end end)
end
function S:Tick(player,dt)
 local p=self.X:Profile(player) local t=self.X.Temp[player] local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") local moving=root and root.AssemblyLinearVelocity.Magnitude>1
 if os.clock()>=(t.NextFlush or 0) then t.NextFlush=os.clock()+C.FlushSeconds self:Flush(player) end
 local zone=self.X.MapService:Sector(player)
 if zone~="Center" and not p.Telemetry.Counters["time_to_"..zone] then p.Telemetry.Counters["time_to_"..zone]=(p.Telemetry.Counters.active_world_seconds or 0)+(p.Telemetry.Counters.idle_seconds or 0)+(p.Telemetry.Counters.menu_open_seconds or 0) end
 if self.X.SeasonService:Eligible(p) and not p.Telemetry.Counters.season_eligibility_time then p.Telemetry.Counters.season_eligibility_time=(p.Telemetry.Counters.active_world_seconds or 0)+(p.Telemetry.Counters.idle_seconds or 0)+(p.Telemetry.Counters.menu_open_seconds or 0) end
 local key=t.MenuOpen and "menu_open_seconds" or moving and "active_world_seconds" or "idle_seconds" p.Telemetry.Counters[key]=(p.Telemetry.Counters[key] or 0)+dt
 local hive=self.X.GardenPlotService:HivePosition(player) local counters=p.Telemetry.Counters
 if root and hive and self.X.SocialService.Pulse then counters.event_distance_sum=(counters.event_distance_sum or 0)+(root.Position-hive).Magnitude counters.event_distance_samples=(counters.event_distance_samples or 0)+1 end
 if root and hive and (root.Position-hive).Magnitude>35 then p.Telemetry.Counters.outside_plot_seconds=(p.Telemetry.Counters.outside_plot_seconds or 0)+dt end
end
function S:Snapshot(player)
 local p=self.X:Profile(player) if not p then return {} end local c=self.X.U.Copy(p.Telemetry.Counters) local seconds=(c.active_world_seconds or 0)+(c.menu_open_seconds or 0)+(c.idle_seconds or 0)
 c.rolls_per_minute=(c.Roll or 0)*60/math.max(1,seconds) c.auto_roll_share=(c.AutoRoll or 0)/math.max(1,c.Roll or 0) c.activity_engagement=(c.ActivityEngaged or 0)/math.max(1,c.ActivityOffered or 0) c.bloom_roll_frequency=(c.BloomRoll or 0)*60/math.max(1,seconds)
 c.average_event_distance=(c.event_distance_sum or 0)/math.max(1,c.event_distance_samples or 0)
 local species={} for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then species[slot.SpeciesId]=true end end c.garden_diversity=self.X.U.Count(species) c.synergy_diversity=self.X.U.Count(self.X.GardenSynergyService.Active[player])
 local traits=require(RS.Config.BeesConfig).GetTraitCounts(p.Pollinators.EquippedBeeSlots) traits._total=nil c.bee_trait_diversity=self.X.U.Count(traits)
 return c
end
return S
]========]
sources["ServerScriptService/Services/PollinatorService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local B=require(RS.Config.BeesConfig) local F=require(RS.Config.FlowersConfig) local R=require(RS.Config.RarityConfig) local S={States={}}
function S:Init(x) self.X=x end
function S:Tick(player,dt)
 local p=self.X:Profile(player) local t=self.X.Temp[player] if not p or not p.StarterBeeGranted then return end local states=self.States[player] or {} self.States[player]=states local stats=self.X.StatsService:Get(p)
 local flowerSlots={} for i,s in ipairs(p.Garden.Slots) do if s.SpeciesId then table.insert(flowerSlots,i) end end if #flowerSlots==0 then return end
 for index,id in pairs(p.Pollinators.EquippedBeeSlots) do if type(index)=="number" and index<=self.X.StatsService:BeeCapacity(p) then local bee=B.Get(id) if bee then
  local state=states[index] if not state or state.Id~=id then state={Id=id,Elapsed=0,AbilityAt=os.clock()+bee.Ability.Cooldown,Slot=flowerSlots[(index-1)%#flowerSlots+1]} states[index]=state end
  if not p.Garden.Slots[state.Slot] or not p.Garden.Slots[state.Slot].SpeciesId then state.Slot=flowerSlots[1] end
  if t.Hotspot and (t.HotspotUntil or 0)>os.clock() then local best=math.huge for _,i in ipairs(flowerSlots) do local d=(self.X.GardenPlotService:Position(player,i)-t.Hotspot).Magnitude if d<best then best=d state.Slot=i end end end
  local slot=p.Garden.Slots[state.Slot] local speed=stats.Speed*((t.SwiftUntil or 0)>os.clock() and 1.2 or 1)*(p.Season.ActiveCard=="TwilightSeason" and .9 or 1)
  state.Elapsed=state.Elapsed+dt*speed self.X:EmitOnce(player,"Work")
  if t.OverchargeBee==id then state.AbilityAt=math.min(state.AbilityAt,os.clock()+1) t.OverchargeBee=nil end
  if os.clock()>=state.AbilityAt then state.AbilityAt=os.clock()+bee.Ability.Cooldown*stats.AbilityCooldown*(p.WorkshopV5.Nodes.BEES_4 and .9 or 1) state.ActiveUntil=os.clock()+bee.Ability.Duration self.X:Emit(player,"Ability",1)
   if R.Rank[bee.Rarity]>=3 and (p.WorkshopV5.Nodes.BEES_2 or p.Season.ActiveCard=="SummerSwarm" or Random.new():NextNumber()<.6) then self.X.GardenActivityService:Offer(player,"Overcharge",self.X.GardenPlotService:Position(player,state.Slot),nil,id) end
  end
  if state.Elapsed>=C.DeliverySeconds then state.Elapsed=state.Elapsed-C.DeliverySeconds
   local bonus=((t.TemporaryMutationUntil or 0)>os.clock() and 1.1 or 1)*((t.NeighbourUntil or 0)>os.clock() and 1.15 or 1)*((t.BlessingUntil or 0)>os.clock() and 1.05 or 1)
   local active=(state.ActiveUntil or 0)>os.clock() local yield=C.HoneyPerDelivery*stats.Yield*bonus*(active and (bee.Ability.RewardMultiplier or 1)*(p.WorkshopV5.Nodes.BEES_6 and 1.2 or 1)*(p.Season.ActiveCard=="TwilightSeason" and 1.15 or 1) or 1)
   p.Hive.Honey=p.Hive.Honey+yield p.Hive.TotalHoney=p.Hive.TotalHoney+yield p.Currencies.Coins=p.Currencies.Coins+C.CoinsPerDelivery*stats.Yield*bonus*(p.WorkshopV5.Nodes.ECONOMY_6 and 1.15 or 1)
   slot.XP=slot.XP+1 slot.TotalPollination=slot.TotalPollination+1 if slot.XP>=slot.Level*C.FlowerLevelXP and slot.Level<C.MasteryCap then slot.XP=0 slot.Level=slot.Level+1 local model=self.X.GardenPlotService.Plots[player].Flowers[state.Slot] if model then model:ScaleTo(1+math.min(2,(slot.Level-1)*.025)) end end
   local flowerModel=self.X.GardenPlotService.Plots[player].Flowers[state.Slot]
   if flowerModel then local text=flowerModel:FindFirstChild("LevelText",true) local fill=flowerModel:FindFirstChild("ProgressFill",true) if text then text.Text=F.Species[slot.SpeciesId].DisplayName.." • LV."..slot.Level end if fill then fill.Size=UDim2.fromScale(math.clamp(slot.XP/(slot.Level*C.FlowerLevelXP),0,1),1) end end
   self.X.FlowerProgressionService:Add(player,slot.SpeciesId,1) p.Pollinators.BeeMastery[id]=(tonumber(p.Pollinators.BeeMastery[id]) or 0)+(p.WorkshopV5.Nodes.BEES_3 and 2 or 1)
   self.X.RollService:Charge(player,C.Charge.Delivery*(p.Season.ActiveCard=="SummerSwarm" and .75 or 1)) self.X:Emit(player,"Delivery",1) self.X.SocialService:Contribute(player,1)
   for synergy in pairs(self.X.GardenSynergyService.Active[player] or {}) do p.GardenSynergies.Mastery[synergy]=(p.GardenSynergies.Mastery[synergy] or 0)+(p.WorkshopV5.Nodes.GARDEN_6 and 2 or 1) end
   state.Slot=flowerSlots[(table.find(flowerSlots,state.Slot) or 1)%#flowerSlots+1]
   if not p.Tutorial.Events.PollenSpark then self.X.GardenActivityService:Offer(player,"PollenSpark",self.X.GardenPlotService:Position(player,state.Slot)) end
  end
 end end end
 if os.clock()>=(t.NextActivity or 0) then t.NextActivity=os.clock()+C.ActivityInterval*(p.WorkshopV5.Nodes.EXPLORATION_4 and .8 or 1)*(p.Season.ActiveCard=="SpringResonance" and .8 or 1) local kinds={"PollenSpark","NectarBud","DewDrop","PollenTrail","CrossPollination","BloomSurge","PollenWind"} t.ActivityIndex=(t.ActivityIndex or 0)%#kinds+1 self.X.GardenActivityService:Offer(player,kinds[t.ActivityIndex],self.X.GardenPlotService:Position(player,flowerSlots[1])) end
end
function S:Remove(player) self.States[player]=nil end
return S
]========]
sources["ServerScriptService/Services/SeasonService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.SeasonConfig) local Plan=require(RS.Shared.SeasonPlan) local Http=game:GetService("HttpService") local S={Pending={}}
function S:Init(x) self.X=x end
function S:Eligible(p) local completed=0 for _,id in ipairs(C.TrialIds) do if p.Quests.Trials[id] then completed=completed+1 end end return p.Hive.Level>=C.Hive and p.World.UnlockedSectors.SunnyOrchard and p.World.UnlockedSectors.CrystalGreenhouse and p.World.UnlockedSectors.TwilightGrove and completed>=C.Trials and self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=C.Flowers and self.X.U.Count(p.Pollinators.DiscoveredBees)>=C.Bees end
function S:Preview(player)
 local p=self.X:Profile(player) if not p then return end if not self:Eligible(p) then self.X:Send(player,"Message","Season: Hive 8, все секторы, 3 ключевых испытания, 8 цветов, 5 пчёл") return end
 local plan=Plan.BuildSeasonTurnPlan(p) local token=Http:GenerateGUID(false) self.Pending[player]={Token=token,Revision=self.X.Revisions[player],Expires=os.clock()+30,Confirm=0,Before=self.X.U.Copy(p)}
 self.X:Send(player,"SeasonPreview",{Token=token,Diff=plan.Diff,Keep=C.Keep,Reset=C.Reset})
end
function S:Confirm(player,token)
 local p=self.X:Profile(player) local q=self.Pending[player] if not p or not q or q.Token~=token or os.clock()>q.Expires or not self:Eligible(p) then return false end
 if q.Revision~=self.X.Revisions[player] or not self.X.U.Equal(q.Before,p) then self.Pending[player]=nil self:Preview(player) return false end
 if q.Confirm==0 then q.Confirm=1 self.X:Send(player,"SeasonConfirm",token) return true end
 self.Pending[player]=nil self.X.Busy[player]=true
 local plan=Plan.BuildSeasonTurnPlan(p)
 local ok=self.X.DataService:CommitProfile(player,plan.After,token)
 self.X.Busy[player]=nil
 if ok and player.Parent then self.X.Temp[player]={} self.X.GardenActivityService:CancelGarden(player) self.X.PollinatorService:Remove(player) self.X.GardenPlotService:Build(player) self.X:Send(player,"Ceremony",{Kind="Season",Text="Новый сезон"}) self.X:Send(player,"Cards",self:Offers(plan.After)) end return ok
end
function S:Offers(p) local out={} for i=1,3 do out[i]=C.Cards[(p.Season.Count+i-2)%#C.Cards+1] end return out end
function S:Card(player,id) local p=self.X:Profile(player) if not p or p.Season.Count<1 or p.Season.ActiveCard~="" or not table.find(self:Offers(p),id) then return false end p.Season.ActiveCard=id self.X.GardenSynergyService:Recalculate(player) return true end
function S:Keepsake(player,kind,id) local p=self.X:Profile(player) if not p then return false end if kind=="Flower2" and p.WorkshopV5.Nodes.LEGACY_5 and p.FlowerCollection.DiscoveredFlowers[id] then p.Season.Keepsakes.Flower2=id return true end if kind=="Flower" and p.FlowerCollection.DiscoveredFlowers[id] or kind=="Bee" and p.Pollinators.DiscoveredBees[id] then p.Season.Keepsakes[kind]=id return true end return false end
function S:Remove(player) self.Pending[player]=nil end
return S
]========]
sources["ServerScriptService/Services/PlayerService"]=[========[local RS=game:GetService("ReplicatedStorage") local Players=game:GetService("Players") local U=require(RS.Shared.BloomUtil) local C=require(RS.Config.BloomConfig) local T=require(RS.Config.TutorialConfig) local L=require(RS.Config.LocationsConfig)
local X={Temp={},Busy={},Revisions={},Connections={},U=U}
function X:Profile(player) if self.Busy[player] then return nil end return self.DataService:GetProfile(player) end
function X:Send(player,kind,payload) if player.Parent==Players then self.RemoteService.Event:FireClient(player,kind,payload) end end
function X:Broadcast(kind,payload) for _,p in ipairs(Players:GetPlayers()) do self:Send(p,kind,payload) end end
function X:Emit(player,event,n)
 local p=self:Profile(player) if not p then return end p.Tutorial.Events[event]=(p.Tutorial.Events[event] or 0)+(n or 1) self.Revisions[player]=(self.Revisions[player] or 0)+1
 self.AnalyticsService:Event(player,event,n or 1) if event=="ActivityCompleted" then self:Send(player,"TokenCollected",true) end self.TutorialService:Refresh(player)
 if event~="Trial" then self.BuildTrialService:Event(player,event,n or 1) end
end
function X:EmitOnce(player,event) local p=self:Profile(player) if p and not p.Tutorial.Events[event] then self:Emit(player,event,1) end end
function X:Part(parent,name,pos,size,color,collide)
 local part=Instance.new("Part") part.Name=name part.Anchored=true part.Size=size part.Position=pos part.Color=color part.CanCollide=collide part.CanTouch=false part.Material=Enum.Material.SmoothPlastic part.Parent=parent return part
end
function X:Prompt(part,text,callback)
 local prompt=Instance.new("ProximityPrompt") prompt.ActionText=text prompt.ObjectText=part.Name prompt.RequiresLineOfSight=false prompt.MaxActivationDistance=12 prompt.Parent=part
 prompt.Triggered:Connect(function(player) if self:Profile(player) and U.Near(player,part.Position,C.InteractionDistance) and self.RemoteService:Accept(player) then callback(player) self:Push(player) end end) return prompt
end
function X:Push(player)
 local p=self:Profile(player) if not p then return end self.TutorialService:Refresh(player)
 local public={Profile=U.Copy(p),Synergies=self.GardenSynergyService.Active[player] or {},BeeCapacity=self.StatsService:BeeCapacity(p),HivePosition=self.GardenPlotService:HivePosition(player),Trial=self.BuildTrialService.Active[player],ServerBloom=self.SocialService.Progress,Pulse=self.SocialService.Pulse,Cards=self.SeasonService:Offers(p),Odds=self.RollService:Odds(player)}
 public.Profile.LegacyArchive=nil public.Profile.Telemetry=nil public.Profile.Migrations=nil self:Send(player,"State",public)
 local leader=player:FindFirstChild("leaderstats") if leader then leader.Coins.Value=math.floor(p.Currencies.Coins) leader.Hive.Value=p.Hive.Level end
end
function X:Request(player,action,a,b,c)
 local p=self:Profile(player) if not p then return false end
 if action=="SeasonCancel" then self.SeasonService.Pending[player]=nil return true end
 if self.SeasonService.Pending[player] and action~="SeasonConfirm" and action~="Menu" and action~="Ready" then return false,"SEASON_PREVIEW_OPEN" end
 if action=="Ready" then self.GardenActivityService:Push(player) return true
 elseif action=="Roll" then return self.RollService:Roll(player,a==true)
 elseif action=="Plant" then return self.GardenPlotService:Plant(player,a,b)
 elseif action=="EquipBee" then return self.InventoryService:EquipBee(player,a,b)
 elseif action=="Dissolve" then return p.Tutorial.FeatureUnlocks.SeedSatchel and self.InventoryService:Dissolve(player,a,b)
 elseif action=="FlowerUpgrade" then return p.Tutorial.FeatureUnlocks.SeedSatchel and self.FlowerProgressionService:Upgrade(player,a)
 elseif action=="Flag" then if not p.FlowerCollection.DiscoveredFlowers[a] or b~="LockedFlowers" and b~="FavoriteFlowers" then return false end p.FlowerCollection[b][a]=not p.FlowerCollection[b][a] return true
 elseif action=="Activity" then return self.GardenActivityService:Collect(player,a,b,c)
 elseif action=="WorkshopBuy" then return self.WorkshopService:Buy(player,a)
 elseif action=="Respec" then return self.WorkshopService:Respec(player)
 elseif action=="Trial" then return self.BuildTrialService:StartTrial(player,a)
 elseif action=="SeasonConfirm" then return self.SeasonService:Confirm(player,a)
 elseif action=="Card" then return self.SeasonService:Card(player,a)
 elseif action=="Keepsake" then return self.SeasonService:Keepsake(player,a,b)
 elseif action=="Skip" then self.TutorialService:Skip(player) return true
 elseif action=="Replay" then self.TutorialService:Replay(player) return true
 elseif action=="Menu" then if a==false then self.Temp[player].MenuOpen=false return true end if a~="Settings" and not p.Tutorial.FeatureUnlocks[a] then return false end self.Temp[player].MenuOpen=true if a=="SeedSatchel" then self:Emit(player,"SatchelOpen",1) end return true
 elseif action=="Setting" then if a=="TokenSoundVolume" and type(b)=="number" and b==b then p.Settings[a]=math.clamp(b,0,1) return true elseif ({ReducedEffects=true,ShowOtherPollinators=true,HideOtherPlayersTokens=true,RareFeed=true,AutoDissolve=true})[a] and type(b)=="boolean" then if a=="AutoDissolve" and not p.WorkshopV5.Nodes.ECONOMY_1 then return false end p.Settings[a]=b return true end return false
 elseif action=="DissolveFilter" then local R=require(RS.Config.RarityConfig) if not p.WorkshopV5.Nodes.ECONOMY_2 or not R.Rank[a] then return false end p.Settings.DissolveRarities[a]=not p.Settings.DissolveRarities[a] return true end return false
end
function X:Loaded(player)
 if self.Temp[player] then return end local p=self:Profile(player) if not p then return end player:SetAttribute("BloomGameplayReady",false) self.Temp[player]={} self.Revisions[player]=0
 local leader=Instance.new("Folder") leader.Name="leaderstats" leader.Parent=player for _,name in ipairs({"Coins","Hive"}) do local v=Instance.new("IntValue") v.Name=name v.Parent=leader end
 self.GardenPlotService:Build(player)
 if p.StarterBeeGranted and next(p.Pollinators.BeeInventory) then p.Tutorial.Events.StarterBee=math.max(1,p.Tutorial.Events.StarterBee or 0) else p.StarterBeeGranted=false end
 local function spawn() task.delay(.3,function() if not self:Profile(player) then return end local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") if root then root.CFrame=CFrame.new(self.GardenPlotService:HivePosition(player)+Vector3.new(0,4,8)) end end) end
 self.Connections[player]=player.CharacterAdded:Connect(spawn) spawn() self:EmitOnce(player,"Wake") player:SetAttribute("BloomGameplayReady",true) self:Push(player)
 if p.Migrations.BloomSummary and not p.Migrations.BloomSummaryLogged then print("[Bloom] migrated",player.UserId,p.Migrations.BloomSummary.PetalDust) p.Migrations.BloomSummaryLogged=true end
end
function X:Remove(player)
 self.AnalyticsService:Flush(player)
 for _,name in ipairs(self.ServiceNames) do local s=self[name] if s.Remove then s:Remove(player) end end
 if self.Connections[player] then self.Connections[player]:Disconnect() self.Connections[player]=nil end self.Temp[player]=nil self.Busy[player]=nil self.Revisions[player]=nil
end
function X:Start(data,services,names)
 self.DataService=data self.ServiceNames=names for _,name in ipairs(names) do self[name]=services[name] end
 local center=workspace:FindFirstChild("Garden") local marker=center and center:FindFirstChild("GardenCenter") self.Origin=(marker and marker.Position or Vector3.zero)+Vector3.new(0,5,0)
 local world=Instance.new("Folder") world.Name="BloomWorld" world.Parent=workspace self.World=world
 self:Part(world,"CentralMeadow",self.Origin-Vector3.new(0,2,0),Vector3.new(440,2,440),Color3.fromRGB(97,155,88),true)
 for _,name in ipairs(names) do local s=self[name] if s.Init then s:Init(self) end end
 self.MapService:Build() self.RemoteService:Start()
 data:GetProfileLoadedSignal():Connect(function(player) self:Loaded(player) end)
 Players.PlayerRemoving:Connect(function(player) self:Remove(player) end)
 for _,player in ipairs(Players:GetPlayers()) do if data:IsLoaded(player) then self:Loaded(player) end end
 task.spawn(function() local sync=0 while true do task.wait(C.TickSeconds) sync=sync+C.TickSeconds self.SocialService:Tick()
  for _,player in ipairs(Players:GetPlayers()) do if self:Profile(player) and self.Temp[player] then local ok,err=xpcall(function()
   if self.SeasonService.Pending[player] and os.clock()>self.SeasonService.Pending[player].Expires then self.SeasonService.Pending[player]=nil end
   if not self.SeasonService.Pending[player] then self.MapService:Tick(player) self.PollinatorService:Tick(player,C.TickSeconds) self.GardenActivityService:Tick(player) self.MetaProgressionService:Tick(player) self.AnalyticsService:Tick(player,C.TickSeconds) end
   if sync>=C.SyncSeconds then self:Push(player) end
  end,debug.traceback) if not ok then warn("[Bloom] Tick",err) end end end if sync>=C.SyncSeconds then sync=0 end
 end end)
 task.spawn(function() while true do task.wait(1) local frames={} for player,states in pairs(self.PollinatorService.States) do if self:Profile(player) then for slot,s in pairs(states) do table.insert(frames,{Owner=player.UserId,Index=slot,Id=s.Id,From=self.GardenPlotService:HivePosition(player),To=self.GardenPlotService:Position(player,s.Slot),Phase=s.Elapsed/C.DeliverySeconds}) end end end self:Broadcast("Bees",frames)
 local tokenFrames={} for owner,offers in pairs(self.GardenActivityService.Offers) do for id,o in pairs(offers) do table.insert(tokenFrames,{Id=id,Owner=owner.UserId,Position=o.Nodes[o.Index],Kind=o.Kind}) end end self:Broadcast("OtherTokens",tokenFrames)
 end end)
end
return X
]========]
sources["ServerScriptService/Services/InventoryService"]=[========[local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local C=require(RS.Config.BloomConfig)
local S={}
function S:Init(x) self.X=x end
function S:Available(p,id) local n=p.FlowerCollection.OwnedSeedCopies[id] or 0 for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then n=n-1 end end return math.max(0,n) end
function S:Grant(player,kind,id)
 local p=self.X:Profile(player) if not p then return end
 if kind=="FlowerSeed" and F.Exists(id) then local f=p.FlowerCollection local new=not f.DiscoveredFlowers[id] f.DiscoveredFlowers[id]=true f.OwnedSeedCopies[id]=(f.OwnedSeedCopies[id] or 0)+1
  if not new and p.Settings.AutoDissolve and p.WorkshopV5.Nodes.ECONOMY_1 and p.Settings.DissolveRarities[F.Species[id].Rarity] and not f.LockedFlowers[id] and not f.FavoriteFlowers[id] then self:Dissolve(player,id,1) end
  self.X:Emit(player,"SeedReward",1) return new
 elseif kind=="Bee" and B.Exists(id) then local b=p.Pollinators local new=not b.DiscoveredBees[id] b.DiscoveredBees[id]=true b.BeeInventory[id]=(b.BeeInventory[id] or 0)+1 return new end
end
function S:Dissolve(player,id,n)
 local p=self.X:Profile(player) if not p or not F.Exists(id) or type(n)~="number" or n%1~=0 or n<1 or n>10000 then return false end
 local f=p.FlowerCollection if f.LockedFlowers[id] or f.FavoriteFlowers[id] or self:Available(p,id)<n or (f.OwnedSeedCopies[id] or 0)-n<1 then return false end
 f.OwnedSeedCopies[id]=f.OwnedSeedCopies[id]-n p.Currencies.PetalDust=p.Currencies.PetalDust+n*C.DustPerCopy*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1)*(p.WorkshopV5.Nodes.ECONOMY_3 and 1.2 or 1)
 self.X.FlowerProgressionService:Add(player,id,n) return true
end
function S:EquipBee(player,id,slot)
 local p=self.X:Profile(player) if not p or not B.Exists(id) or not self.X.U.Integer(slot,self.X.StatsService:BeeCapacity(p)) then return false end
 local count=0 for i,v in pairs(p.Pollinators.EquippedBeeSlots) do if i~=slot and v==id then count=count+1 end end
 if count>=(p.Pollinators.BeeInventory[id] or 0) then return false end p.Pollinators.EquippedBeeSlots[slot]=id
 self.X.GardenSynergyService:Recalculate(player) local _,traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots) if #traits>0 then self.X:Emit(player,"Trait",1) end return true
end
return S
]========]
sources["ServerScriptService/Services/GardenSynergyService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.GardenSynergyConfig) local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local S={Active={}}
function S:Init(x) self.X=x end
function S:Recalculate(player)
 local p=self.X:Profile(player) if not p then return end local slots=p.Garden.Slots local range=1+(p.WorkshopV5.Nodes.GARDEN_2 and 1 or 0)+(p.Season.ActiveCard=="SpringResonance" and 1 or 0) local traits=B.GetTraitCounts(p.Pollinators.EquippedBeeSlots) local active={}
 local function tag(i,t) local f=slots[i] and F.Species[slots[i].SpeciesId] return f and table.find(f.Tags,t)~=nil end
 for _,r in ipairs(C.Recipes) do local matches={} local yes=false
  if r.Kind=="Pair" then for i,a in ipairs(slots) do for j,b in ipairs(slots) do if a.SpeciesId==r.Species[1] and b.SpeciesId==r.Species[2] and C.Adjacent(i,j,range) then yes=true matches={i,j} end end end
  elseif r.Kind=="Family" then
   for start in ipairs(slots) do if tag(start,r.Tag) then local queue={start} local seen={[start]=true} local k=1 while queue[k] do local i=queue[k] k=k+1 for j in ipairs(slots) do if not seen[j] and tag(j,r.Tag) and C.Adjacent(i,j,range) then seen[j]=true table.insert(queue,j) end end end if #queue>=r.Count then yes=true matches=queue break end end end
  elseif r.Kind=="Pattern" then yes=true for _,i in ipairs(r.Slots) do if not tag(i,r.Tag) then yes=false end end matches=r.Slots
  elseif r.Kind=="Bee" or r.Kind=="Biome" then for i in ipairs(slots) do if tag(i,r.Tag) then table.insert(matches,i) end end yes=#matches>0 and (r.Kind=="Bee" and (traits[r.Trait] or 0)>=r.Count or r.Kind=="Biome" and self.X.MapService:Sector(player)==r.Biome)
  elseif r.Kind=="Signature" then yes=true for _,id in ipairs(r.Species) do local found=false for i,s in ipairs(slots) do if s.SpeciesId==id then found=true table.insert(matches,i) break end end if not found then yes=false end end end
  if yes then active[r.Id]={Kind=r.Kind,Slots=matches} if not p.GardenSynergies.Discovered[r.Id] then p.GardenSynergies.Discovered[r.Id]=true self.X:Emit(player,"Synergy",1) end end
 end self.Active[player]=active if self.X.Temp and self.X.Temp[player] then self.X.Temp[player].Signature=active.AstralGarden~=nil end return active
end
function S:Remove(player) self.Active[player]=nil end
return S
]========]
sources["ServerScriptService/Services/FlowerProgressionService"]=[========[local C=require(game:GetService("ReplicatedStorage").Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:Add(player,id,xp) local p=self.X:Profile(player) if not p then return end local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0} p.FlowerCollection.FlowerMastery[id]=m m.XP=m.XP+xp while m.Level<C.MasteryCap and m.XP>=m.Level*C.MasteryXP do m.XP=m.XP-m.Level*C.MasteryXP m.Level=m.Level+1 end end
function S:Upgrade(player,id) local p=self.X:Profile(player) if not p or not p.FlowerCollection.DiscoveredFlowers[id] then return false end local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0} local cost=math.ceil(m.Level*5*(p.WorkshopV5.Nodes.ECONOMY_5 and .8 or 1)) if m.Level>=C.MasteryCap or p.Currencies.PetalDust<cost then return false end p.Currencies.PetalDust=p.Currencies.PetalDust-cost self:Add(player,id,m.Level*C.MasteryXP) return true end
return S
]========]
sources["ServerScriptService/Services/TutorialService"]=[========[local RS=game:GetService("ReplicatedStorage") local T=require(RS.Config.TutorialConfig) local Features=require(RS.Config.FeatureUnlockConfig) local S={}
function S:Init(x) self.X=x end
function S:Refresh(player)
 local p=self.X:Profile(player) if not p then return end local t=p.Tutorial local old=t.Step
 while T.Steps[t.Step] do local e=T.Steps[t.Step].Event local complete=(t.Events[e] or 0)>0 if e=="Deliveries" then complete=(t.Events.Delivery or 0)>=3 end if not complete then break end t.Step=t.Step+1 end
 for id,rule in pairs(Features) do
  local unlocked=rule.Step and t.Step>=rule.Step or rule.Event and (t.Events[rule.Event] or 0)>0 or rule.Node and p.WorkshopV5.Nodes[rule.Node]==true
  if rule.Node then t.FeatureUnlocks[id]=unlocked==true elseif unlocked then t.FeatureUnlocks[id]=true end
 end
 if old<=#T.Steps and t.Step>#T.Steps then self.X:EmitOnce(player,"TutorialComplete") end
end
function S:Skip(player)
 local p=self.X:Profile(player) if not p then return end
 if not p.StarterBeeGranted then self.X.HiveService:Interact(player) end
 p.Tutorial.Step=19 p.Tutorial.Skipped=true for id,r in pairs(Features) do if not r.Node then p.Tutorial.FeatureUnlocks[id]=true end end
end
function S:Replay(player) self.X:Send(player,"Replay",T.Steps) end
return S
]========]
sources["ServerScriptService/Services/RemoteService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local S={Buckets={}}
function S:Init(x)
 self.X=x local old=RS:FindFirstChild("BloomRemotes") if old then old:Destroy() end local folder=Instance.new("Folder") folder.Name="BloomRemotes" folder.Parent=RS
 local request=Instance.new("RemoteEvent") request.Name="Request" request.Parent=folder local event=Instance.new("RemoteEvent") event.Name="Event" event.Parent=folder self.Request=request self.Event=event
end
function S:Accept(player)
 local now=os.clock() local b=self.Buckets[player] or {Time=now,Tokens=C.RemoteBurst} self.Buckets[player]=b b.Tokens=math.min(C.RemoteBurst,b.Tokens+(now-b.Time)*C.RemoteRate) b.Time=now if b.Tokens<1 then return false end b.Tokens=b.Tokens-1 return true
end
function S:Start()
 self.Request.OnServerEvent:Connect(function(player,action,a,b,c)
  if not self:Accept(player) or type(action)~="string" or #action>32 then return end
  if type(a)=="string" and #a>100 or type(b)=="string" and #b>100 or type(c)=="string" and #c>100 then return end
  if not self.X:Profile(player) then
   if action=="Ready" then self.X:Send(player,"Ack",{Action="Ready",OK=false,Reason="PROFILE_LOADING"}) end
   return
  end
  local ok,result,reason=pcall(function() return self.X:Request(player,action,a,b,c) end)
  if not ok then warn("[Bloom] Request error",action,result) end
  self.X:Send(player,"Ack",{Action=action,OK=ok and result~=false,Reason=ok and reason or "SERVER_ERROR"})
  self.X:Push(player)
 end)
end
function S:Remove(player) self.Buckets[player]=nil end
return S
]========]
sources["ServerScriptService/Services/MetaProgressionService"]=[========[local S={}
local goals={"StarterBee","PollenSpark","Delivery","Roll","Plant","Charge","BloomRoll","Hive2","WorkshopVisit","WorkshopPurchase","Synergy","BeeSlots","Trait","SunnyVisit","SolarBloom","Discover6","CrystalGate","Trial","CrystalVisit","SeasonReady"}
function S:Init(x) self.X=x end
function S:Tick(player)
 local p=self.X:Profile(player) local q=p.Quests local key=goals[q.JourneyStep] if not key then return end local events=p.Tutorial.Events local yes=(events[key] or 0)>0
 if key=="Charge" then yes=p.RollState.SpecialRollReady or (events.BloomRoll or 0)>0 elseif key=="Hive2" then yes=p.Hive.Level>=2 elseif key=="BeeSlots" then yes=self.X.StatsService:BeeCapacity(p)>=2 elseif key=="Discover6" then yes=self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=6 elseif key=="CrystalGate" then yes=p.World.UnlockedSectors.CrystalGreenhouse elseif key=="CrystalVisit" then yes=self.X.MapService:Sector(player)=="CrystalGreenhouse" elseif key=="SeasonReady" then yes=self.X.SeasonService:Eligible(p) end
 if yes then local id="Journey_"..q.JourneyStep if not q.Claimed[id] then q.Claimed[id]=true p.Currencies.Coins=p.Currencies.Coins+10 end q.JourneyStep=q.JourneyStep+1 end
 local discovered=self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)+self.X.U.Count(p.Pollinators.DiscoveredBees)
 for _,threshold in ipairs({4,8,12,18,24}) do if discovered>=threshold then self.X.WorkshopService:Point(player,"Collection_"..threshold,2) end end
end
S.Goals=goals return S
]========]
sources["ServerScriptService/Services/StatsService"]=[========[local RS=game:GetService("ReplicatedStorage") local B=require(RS.Config.BeesConfig) local C=require(RS.Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:BeeCapacity(p) return math.min(C.MaxBeeSlots,1+(p.Hive.Level>=2 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_1 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_5 and 2 or 0)) end
function S:FlowerCapacity(p) return math.min(C.MaxFlowerSlots,3+math.max(0,p.Hive.Level-1)+(p.WorkshopV5.Nodes.GARDEN_1 and 1 or 0)+(p.WorkshopV5.Nodes.GARDEN_4 and 3 or 0)) end
function S:Get(p) local traits=B.GetTraitBonuses(p.Pollinators.EquippedBeeSlots) local passive=B.GetPassiveBonuses(p.Pollinators.EquippedBeeSlots) return {Luck=(traits.LuckMultiplier or 1)*(passive.LuckMultiplier or 1),Yield=(traits.PollinatorYieldMultiplier or 1)*(passive.PollinatorYieldMultiplier or 1),Speed=(traits.PollinatorTravelSpeedMultiplier or 1)*(passive.PollinatorTravelSpeedMultiplier or 1),AbilityCooldown=traits.AbilityCooldownMultiplier or 1} end
return S
]========]
sources["ServerScriptService/Services/GardenPlotService"]=[========[local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local G=require(RS.Config.GardenSynergyConfig) local C=require(RS.Config.BloomConfig)
local S={Plots={},Used={}}
function S:Init(x) self.X=x end
function S:Position(player,slot) local plot=self.Plots[player] return plot and plot.Origin+G.Position(slot) end
function S:HivePosition(player) local plot=self.Plots[player] return plot and plot.Origin+Vector3.new(0,1,19) end
function S:Build(player)
 local p=self.X:Profile(player) if not p then return end local plot=self.Plots[player]
 if not plot then local i=1 while self.Used[i] do i=i+1 end self.Used[i]=true local a=(i-1)%12*math.pi*2/12 local r=105+math.floor((i-1)/12)*60 local origin=self.X.Origin+Vector3.new(math.cos(a)*r,0,math.sin(a)*r)
  local m=Instance.new("Model") m.Name="Garden_"..player.UserId m:SetAttribute("OwnerUserId",player.UserId) m.Parent=self.X.World
  plot={Index=i,Origin=origin,Model=m,Flowers={}} self.Plots[player]=plot
  self.X:Part(m,"Ground",origin-Vector3.new(0,1,0),Vector3.new(44,2,48),Color3.fromRGB(95,155,90),true)
  local hive=self.X:Part(m,"Hive",self:HivePosition(player),Vector3.new(5,5,5),Color3.fromRGB(240,185,50),true)
  self.X:Prompt(hive,"Улей: получить пчелу / улучшить",function(who) if who==player then self.X.HiveService:Interact(player) else self.X.SocialService:Bless(who,player) end end)
 end
 if plot.Content then plot.Content:Destroy() end plot.Flowers={} local content=Instance.new("Folder") content.Name="Flowers" content.Parent=plot.Model plot.Content=content
 for i=1,C.MaxFlowerSlots do local pos=self:Position(player,i) local unlocked=i<=p.Garden.UnlockedSlots
  local pad=self.X:Part(content,"Slot_"..i,pos,Vector3.new(5,.3,5),unlocked and Color3.fromRGB(190,145,90) or Color3.fromRGB(75,80,85),false)
  pad:SetAttribute("OwnerUserId",player.UserId) pad:SetAttribute("SlotId",i)
  if unlocked then self.X:Prompt(pad,"Посадить / заменить",function(who) if who==player then self.X:Send(player,"PlantPicker",i) end end)
   local slot=p.Garden.Slots[i] local f=slot and F.Species[slot.SpeciesId] if f then local m=self.X.FlowerService.Build(i,f,pos+Vector3.new(0,.2,0)) m.Parent=content m:ScaleTo(1+math.min(2,(slot.Level-1)*.025)) plot.Flowers[i]=m end
  end
 end
 self.X.GardenSynergyService:Recalculate(player)
end
function S:Plant(player,i,id)
 local p=self.X:Profile(player) if not p or not self.X.U.Integer(i,p.Garden.UnlockedSlots) then return false end
 local pos=self:Position(player,i) if not pos or not self.X.U.Near(player,pos,C.InteractionDistance) then return false end
 if id~="" and (type(id)~="string" or not F.Exists(id)) then return false end
 local old=p.Garden.Slots[i] if old.SpeciesId==id then return true end
 if id~="" and self.X.InventoryService:Available(p,id)<1 then return false end
 local slot={} if id~="" then slot={SpeciesId=id,Level=1,XP=0,TotalPollination=0,Mutation=""} local mutation=self.X.Temp[player].SeedMutation if mutation and mutation.Id==id then slot.Mutation=mutation.Mutation self.X.Temp[player].SeedMutation=nil end end
 p.Garden.Slots[i]=slot p.Garden.Revision=p.Garden.Revision+1 self.X.GardenActivityService:CancelGarden(player) self:Build(player) if id~="" then self.X:Emit(player,"Plant",1) end return true
end
function S:RefreshCapacity(player) local p=self.X:Profile(player) p.Garden.UnlockedSlots=self.X.StatsService:FlowerCapacity(p) self:Build(player) end
function S:Remove(player) local plot=self.Plots[player] if plot then self.Used[plot.Index]=nil plot.Model:Destroy() self.Plots[player]=nil end end
return S
]========]
sources["ServerScriptService/Services/SocialService"]=[========[local RS=game:GetService("ReplicatedStorage") local A=require(RS.Config.ActivityConfig) local S={Blessed={},Progress=0,Contributions={},Round=0,NextEvent=0,Pulse=nil}
function S:Init(x) self.X=x self.NextEvent=os.clock()+A.EventInterval end
function S:Bless(visitor,owner)
 if visitor==owner or self.Blessed[visitor] then return false end local p=self.X:Profile(visitor) local target=self.X:Profile(owner) if not p or not target then return false end
 local pos=self.X.GardenPlotService:HivePosition(owner) if not pos or not self.X.U.Near(visitor,pos,14) then return false end
 self.Blessed[visitor]=true self.X.Temp[owner].BlessingUntil=os.clock()+60 self.X:Send(visitor,"Message","Благословение оставлено") return true
end
function S:Contribute(player,amount)
 local flower=self.X.World:FindFirstChild("ServerBloom") local text=flower and flower:FindFirstChild("LevelText",true) if text then text.Text="SERVER BLOOM • "..math.floor(self.Progress).."/"..A.ServerBloomTarget end
 self.Progress=self.Progress+amount self.Contributions[player]=(self.Contributions[player] or 0)+amount
 if self.Progress>=A.ServerBloomTarget then self.Round=self.Round+1 for who,n in pairs(self.Contributions) do local p=self.X:Profile(who) if p and n>0 then p.Currencies.PetalDust=p.Currencies.PetalDust+2+math.min(8,math.floor(n/10)) self.X.RollService:Charge(who,15) p.World.EventStats.ServerBloom=(p.World.EventStats.ServerBloom or 0)+1 self.X:Send(who,"Ceremony",{Kind="ServerBloom",Text="Server Bloom"}) end end self.Progress=0 self.Contributions={} end
end
function S:Tick()
 local now=os.clock() if self.Pulse and now>=self.Pulse.Ends then self.Pulse=nil end
 if now>=self.NextEvent then local sectors={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"} self.Round=self.Round+1 self.Pulse={Sector=sectors[self.Round%3+1],Ends=now+A.PulseDuration} self.NextEvent=now+A.EventInterval end
end
function S:IsEclipse(player) local temp=player and self.X.Temp[player] return self.Pulse and self.Pulse.Sector=="TwilightGrove" or temp and (temp.PersonalEclipseUntil or 0)>os.clock() end
function S:Remove(player) self.Blessed[player]=nil self.Contributions[player]=nil end
return S
]========]
sources["ServerScriptService/Services/HiveService"]=[========[local C=require(game:GetService("ReplicatedStorage").Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:Interact(player)
 local p=self.X:Profile(player) if not p then return false end
 if not p.StarterBeeGranted then p.StarterBeeGranted=true self.X.InventoryService:Grant(player,"Bee","WorkerBee") p.Pollinators.EquippedBeeSlots[1]="WorkerBee" self.X:Emit(player,"StarterBee",1) return true end
 local cost=C.HiveCosts[p.Hive.Level+1] if not cost then return false end
 if p.Hive.Honey<cost then self.X:Send(player,"Message","Нужно мёда: "..cost) return false end
 p.Hive.Honey=p.Hive.Honey-cost p.Hive.Level=p.Hive.Level+1
 self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..p.Hive.Level,2)
 self.X.GardenPlotService:RefreshCapacity(player) self.X:Emit(player,"HiveUpgrade",1) self.X:Send(player,"Ceremony",{Kind="Hive",Text="Hive level "..p.Hive.Level}) return true
end
return S
]========]
sources["ServerScriptService/Services/GardenActivityService"]=[========[local RS=game:GetService("ReplicatedStorage") local A=require(RS.Config.ActivityConfig) local C=require(RS.Config.BloomConfig) local G=require(RS.Config.GardenSynergyConfig) local Http=game:GetService("HttpService") local S={Offers={}}
function S:Init(x) self.X=x end
function S:Offer(player,kind,position,sector,bee)
 local p=self.X:Profile(player) local cfg=A.Types[kind] if not p or not cfg then return false end
 local offers=self.Offers[player] or {} self.Offers[player]=offers local count=0 for _ in pairs(offers) do count=count+1 end if count>=A.MaxVisible then return false end
 if kind=="Overcharge" and not bee then return false end
 local id=Http:GenerateGUID(false) local nodes={} local origin=self.X.GardenPlotService:HivePosition(player)
 if kind=="NectarBud" then
  local nearest=nil local distance=math.huge for i,s in ipairs(p.Garden.Slots) do if s.SpeciesId then local pos=self.X.GardenPlotService:Position(player,i) local d=(pos-position).Magnitude if d<distance then distance=d nearest=pos end end end
  if not nearest then return false end nodes[1]=nearest+Vector3.new(0,3,0)
 elseif kind=="CrossPollination" then for i=1,3 do if not p.Garden.Slots[i].SpeciesId then return false end nodes[i]=self.X.GardenPlotService:Position(player,i)+Vector3.new(0,3,0) end
 else for i=1,cfg.Steps do local t=(i-1)/math.max(1,cfg.Steps-1) if kind=="PollenTrail" then nodes[i]=position:Lerp(origin,t)+Vector3.new(0,2+math.sin(t*math.pi)*2,0) else nodes[i]=position+Vector3.new(math.sin(i*1.8)*7,3,math.cos(i*1.8)*7) end end end
 offers[id]={Id=id,Kind=kind,Nodes=nodes,Index=1,Expires=workspace:GetServerTimeNow()+cfg.Life,Sector=sector,Bee=bee,Revision=p.Garden.Revision}
 if kind=="BloomSurge" then self.X.Temp[player].Hotspot=position self.X.Temp[player].HotspotUntil=os.clock()+cfg.Life end
 self.X:Emit(player,"ActivityOffered",1) self:Push(player) return true
end
function S:Push(player) local list={} for _,o in pairs(self.Offers[player] or {}) do table.insert(list,{Id=o.Id,Kind=o.Kind,Position=o.Nodes[o.Index],Index=o.Index,Count=#o.Nodes,Expires=o.Expires,Hold=A.Types[o.Kind].Hold==true}) end self.X:Send(player,"Activities",list) end
function S:Collect(player,id,index,phase)
 local offers=self.Offers[player] local o=offers and offers[id] local p=self.X:Profile(player) if not o or not p or o.Expires<workspace:GetServerTimeNow() or index~=o.Index then return false end
 if o.Sector and not p.World.UnlockedSectors[o.Sector] then return false end
 if not self.X.U.Near(player,o.Nodes[o.Index],A.PickupDistance) then return false end
 if not o.Engaged then o.Engaged=true self.X:Emit(player,"ActivityEngaged",1) end
 if A.Types[o.Kind].Hold then if phase=="Begin" then o.HoldStarted=os.clock() return true elseif phase=="Cancel" then o.HoldStarted=nil return true elseif not o.HoldStarted or os.clock()-o.HoldStarted<A.HoldSeconds then return false end end
 if o.Kind=="CrossPollination" and o.Revision~=p.Garden.Revision then offers[id]=nil self:Push(player) return false end
 o.Index=o.Index+1 if o.Kind=="FireflyRoute" then self.X:Emit(player,"Firefly",1) end
 if o.Index>#o.Nodes then offers[id]=nil local temp=self.X.Temp[player] local kind=o.Kind
  if kind=="DewDrop" then temp.Dew=math.min(A.DewMax,(temp.Dew or 0)+1)
  elseif kind=="NectarBud" then p.Currencies.Coins=p.Currencies.Coins+5
   local Flowers=require(RS.Config.FlowersConfig)
   for i,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId and (self.X.GardenPlotService:Position(player,i)-o.Nodes[1]).Magnitude<15 then local effect=Flowers.Species[slot.SpeciesId].PollinationEffect
    if effect=="NeighbourBoost" then temp.NeighbourUntil=os.clock()+20 elseif effect=="SwiftWindow" then temp.SwiftUntil=os.clock()+15 elseif effect=="LuckDew" then temp.Dew=math.min(A.DewMax,(temp.Dew or 0)+1) elseif effect=="CoinPod" then p.Currencies.Coins=p.Currencies.Coins+3 elseif effect=="Astral" then temp.Eclipse=true elseif effect=="Pulse" then slot.XP=slot.XP+3 slot.TotalPollination=slot.TotalPollination+3 end
   end end if Random.new():NextNumber()<A.MutationChance then for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then slot.Mutation="Dewkissed" self.X:Emit(player,"Mutation",1) break end end end
  elseif kind=="NectarBud" then
  local nearest=nil local distance=math.huge for i,s in ipairs(p.Garden.Slots) do if s.SpeciesId then local pos=self.X.GardenPlotService:Position(player,i) local d=(pos-position).Magnitude if d<distance then distance=d nearest=pos end end end
  if not nearest then return false end nodes[1]=nearest+Vector3.new(0,3,0)
 elseif kind=="CrossPollination" then temp.NeighbourUntil=os.clock()+20
  elseif kind=="Overcharge" then temp.OverchargeBee=o.Bee
  elseif kind=="CrystalResonance" then temp.Crystal=true temp.NeighbourUntil=os.clock()+30+(p.WorkshopV5.Nodes.EXPLORATION_3 and 20 or 0) if p.Season.ActiveCard=="CrystalSeason" then temp.TemporaryMutationUntil=os.clock()+60 end
  elseif kind=="FireflyRoute" or kind=="ShadowBloom" then temp.Eclipse=true end
  self.X.RollService:Charge(player,A.Types[kind].Charge*(p.WorkshopV5.Nodes.BLOOM_2 and 1.2 or 1)*(o.Sector and p.WorkshopV5.Nodes.EXPLORATION_2 and 1.2 or 1)*(p.Season.ActiveCard=="SummerSwarm" and 1.25 or 1))
  self.X:Emit(player,kind,1) self.X:Emit(player,"ActivityCompleted",1)
  if o.Sector then self.X:Emit(player,"WorldActivity",1) end
  self.X.SocialService:Contribute(player,2)
  for _,bee in pairs(p.Pollinators.EquippedBeeSlots) do p.Pollinators.BeeMastery[bee]=(tonumber(p.Pollinators.BeeMastery[bee]) or 0)+1 end
 end self:Push(player) return true
end
function S:Tick(player)
 local changed=false local offers=self.Offers[player] or {} local p=self.X:Profile(player)
 for id,o in pairs(offers) do if o.HoldStarted and not self.X.U.Near(player,o.Nodes[o.Index],A.PickupDistance) then o.HoldStarted=nil end if o.Expires<workspace:GetServerTimeNow() or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character:FindFirstChildOfClass("Humanoid").Health<=0 then offers[id]=nil changed=true end end
 if changed then self:Push(player) end
end
function S:CancelGarden(player) self.Offers[player]={} self:Push(player) end
function S:Remove(player) self.Offers[player]=nil end
return S
]========]
sources["ServerScriptService/Services/RollService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local Pool=require(RS.Config.RollPoolConfig) local S={Last={}} local rng=Random.new()
function S:Init(x) self.X=x end
function S:Charge(player,amount) local p=self.X:Profile(player) if p then p.RollState.BloomCharge=math.min(C.BloomMax,p.RollState.BloomCharge+amount) p.RollState.SpecialRollReady=p.RollState.BloomCharge>=C.BloomMax end end
function S:Odds(player) local p=self.X:Profile(player) if not p then return {} end local t=self.X.Temp[player] return Pool.Build(p,self.X.StatsService:Get(p).Luck+(t.Dew or 0)*.1,t) end
function S:Roll(player,automatic)
 local p=self.X:Profile(player) if not p or not p.Tutorial.FeatureUnlocks.Roll then return false,"LOCKED" end
 local cd=p.WorkshopV5.Nodes.ROLL_6 and .8 or p.WorkshopV5.Nodes.ROLL_5 and 1.2 or p.WorkshopV5.Nodes.ROLL_1 and 1.4 or C.RollCooldown if os.clock()-(self.Last[player] or -100)<cd then return false,"COOLDOWN" end
 local pool,total=self:Odds(player) if total<=0 then return false,"EMPTY_POOL" end
 local target=rng:NextNumber()*total local item=pool[#pool] for _,v in ipairs(pool) do target=target-v.Weight if target<=0 then item=v break end end
 self.Last[player]=os.clock() local special=p.RollState.SpecialRollReady local new=self.X.InventoryService:Grant(player,item.Kind,item.Id)
 p.RollState.TotalRolls=p.RollState.TotalRolls+1 p.RollState.DiscoveryPity=new and 0 or p.RollState.DiscoveryPity+1
 local temp=self.X.Temp[player] temp.Dew=0
 if special then p.RollState.BloomCharge=(p.WorkshopV5.Nodes.ROLL_2 and 10 or 0)+(p.WorkshopV5.Nodes.BLOOM_4 and 10 or 0) p.RollState.SpecialRollReady=false
  if item.Kind=="FlowerSeed" and p.WorkshopV5.Nodes.BLOOM_1 and rng:NextNumber()<C.SpecialMutationChance+(temp.Crystal and .15 or 0)+(p.WorkshopV5.Nodes.BLOOM_5 and .1 or 0) then temp.SeedMutation={Id=item.Id,Mutation="Radiant"} end temp.Crystal=nil temp.Eclipse=nil self.X:Emit(player,"BloomRoll",1)
 end
 self.X:Emit(player,"Roll",1) if automatic then self.X:Emit(player,"AutoRoll",1) end
 local result={Kind=item.Kind,Id=item.Id,DisplayName=item.DisplayName,Rarity=item.Rarity,Odds=item.Odds,Chance=item.Chance,IsNew=new,IsSpecialRoll=special,Cooldown=cd}
 self.X:Send(player,"Reward",result) if item.Rarity=="Mythic" or item.Rarity=="Celestial" then self.X:Broadcast("RareFeed",{Player=player.DisplayName,Name=item.DisplayName,Rarity=item.Rarity}) end return true
end
function S:Remove(player) self.Last[player]=nil end
return S
]========]
sources["ServerScriptService/Services/BuildTrialService"]=[========[local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BuildTrialConfig) local B=require(RS.Config.BeesConfig) local S={Active={}}
function S:Init(x) self.X=x end
function S:StartTrial(player,id)
 local p=self.X:Profile(player) local cfg=C[id] if not p or not cfg or not p.Tutorial.FeatureUnlocks.Trials or self.X.MapService:Sector(player)~=cfg.Sector or not p.World.UnlockedSectors[cfg.Sector] then return false end
 local location=require(RS.Config.LocationsConfig).Sectors[cfg.Sector] local pos=self.X.Origin+location.Center+Vector3.new(0,2,30)
 if not self.X.U.Near(player,pos,14) then return false end
 self.Active[player]={Advanced=p.WorkshopV5.Nodes.LEGACY_4==true,Id=id,Start=os.clock(),Counts={},Revision=p.Garden.Revision} self.X:Send(player,"Message",cfg.Name.." started") return true
end
function S:Event(player,event,n)
 local a=self.Active[player] local p=self.X:Profile(player) if not a or not p then return end local cfg=C[a.Id] if os.clock()-a.Start>cfg.Seconds then self.Active[player]=nil return end
 a.Counts[event]=(a.Counts[event] or 0)+n local synergies=self.X.GardenSynergyService.Active[player] or {} local yes=(a.Counts[cfg.Event] or 0)>=cfg.Target*(a.Advanced and 2 or 1)
 if a.Id=="MeadowCircuit" then local pairCount=0 for _,v in pairs(synergies) do if v.Kind=="Pair" then pairCount=pairCount+1 end end local traits=B.GetTraitCounts(p.Pollinators.EquippedBeeSlots) yes=yes and pairCount>=2 and (traits.Meadow or 0)>=2
 elseif a.Id=="SwiftRoute" then yes=yes and os.clock()-a.Start<=60
 elseif a.Id=="CrystalTriangle" then yes=yes and synergies.CrystalTriangle~=nil
 elseif a.Id=="NoCelestial" then for _,id in pairs(p.Pollinators.EquippedBeeSlots) do if B.Get(id).Rarity=="Celestial" then a.Invalid=true end end yes=yes and not a.Invalid
 elseif a.Id=="SignatureBloom" then yes=synergies.AstralGarden~=nil
 elseif a.Id=="TwilightPulse" then yes=yes and (a.Counts.Firefly or 0)>=5 and self.X.SocialService:IsEclipse(player)
 elseif a.Id=="MinimalGarden" then local count=0 for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then count=count+1 end end if count>3 then a.Invalid=true end yes=yes and not a.Invalid
 end
 if not yes then return end self.Active[player]=nil
 local first=not p.Quests.Trials[a.Id] if first then p.Quests.Trials[a.Id]=true self.X.WorkshopService:Point(player,"Trial_"..a.Id,2) p.Season.CompletedGoals[a.Id]=true else p.Currencies.Coins=p.Currencies.Coins+5 end
 if a.Advanced then self.X.WorkshopService:Point(player,"AdvancedTrial_"..a.Id,1) end self.X:Emit(player,"Trial",1) self.X:Send(player,"Ceremony",{Kind="Trial",Text=cfg.Name.." complete"})
end
function S:Remove(player) self.Active[player]=nil end
return S
]========]
sources["ServerScriptService/Services/DataService"]=[========[--!strict
local Players =
game:GetService("Players")
local DataStoreService =
game:GetService("DataStoreService")
local HttpService =
game:GetService("HttpService")
local ReplicatedStorage =
game:GetService("ReplicatedStorage")
local ServerScriptService =
game:GetService("ServerScriptService")
local SharedFolder =
ReplicatedStorage:WaitForChild(
"Shared"
)
local DataFolder =
ServerScriptService:WaitForChild(
"Data"
)
local TableUtil =
require(
SharedFolder:WaitForChild(
"TableUtil"
)
)
local DataConfig =
require(
DataFolder:WaitForChild(
"DataConfig"
)
)
local ProfileSchema =
require(
DataFolder:WaitForChild(
"ProfileSchema"
)
)
local DataService = {}
local profileStore = nil
local recordsByUserId: {
[number]: any
} = {}
local saveLocks: {
[number]: boolean
} = {}
local profileLoadedEvent =
Instance.new("BindableEvent")
local randomGenerator =
Random.new()
local started = false
local shuttingDown =
false
local serverSessionToken =
HttpService:GenerateGUID(
false
)
local serverId =
game.JobId
if serverId == "" then
serverId =
"studio-"
.. HttpService:GenerateGUID(
false
)
end
local function getKey(
userId: number
): string
return DataConfig.KeyPrefix
.. tostring(userId)
end
local function getRetryDelay(
attempt: number
): number
return DataConfig.RetryBaseSeconds
* (
2 ^ (attempt - 1)
)
end
local function makeSession(
now: number
)
return {
ServerId =
serverId,
Token =
serverSessionToken,
ExpiresAt =
now
+ DataConfig.SessionLeaseSeconds,
}
end
local function normalizeStoredRecord(
stored
)
if type(stored)
== "table"
and type(stored.Data)
== "table"
then
return stored
end
if type(stored)
== "table"
then
return {
RecordVersion = 1,
Revision = 0,
UpdatedAt = 0,
Session = nil,
Data =
TableUtil.DeepCopy(
stored
),
}
end
return {
RecordVersion = 1,
Revision = 0,
UpdatedAt = 0,
Session = nil,
Data = nil,
}
end
function DataService:Init()
local storeName =
DataConfig.GetStoreName()
profileStore =
DataStoreService:GetDataStore(
storeName
)
print(
"[DataService] Store:",
storeName
)
print(
"[DataService] Server session:",
serverId
)
print(
"[DataService] Init complete"
)
end
function DataService:Start()
if started then
return
end
started =
true
assert(
profileStore ~= nil,
"DataService was not initialized"
)
Players.PlayerAdded:Connect(
function(player)
task.spawn(
function()
self:LoadProfile(
player
)
end
)
end
)
Players.PlayerRemoving:Connect(
function(player)
self:ReleaseProfile(
player
)
end
)
for _, player in ipairs(
Players:GetPlayers()
) do
task.spawn(
function()
self:LoadProfile(
player
)
end
)
end
task.spawn(
function()
self:AutosaveLoop()
end
)
game:BindToClose(
function()
self:Shutdown()
end
)
print(
"[DataService] Started"
)
end
function DataService:LoadProfile(
player: Player
)
local userId =
player.UserId
if recordsByUserId[
userId
] then
return
end
player:SetAttribute("BloomProfileState","Loading")
player:SetAttribute("BloomProfileLoaded",false)
player:SetAttribute("BloomProfileError",nil)
print("[DataService] Loading profile:",player.Name,userId)
local record = {
Player =
player,
State =
"Loading",
Data =
nil,
Cancelled =
false,
LastSaveAt =
0,
}
recordsByUserId[
userId
] = record
task.delay(8,function()
 if recordsByUserId[userId]==record and record.State=="Loading" and player.Parent==Players then
  warn("[DataService] Profile load still pending after 8s:",player.Name,userId)
 end
end)
local key =
getKey(
userId
)
local finalError:
string? = nil
for attempt = 1,
DataConfig.MaxRetries
do
local callbackFailure:
string? = nil
local success,
resultOrError =
pcall(
function()
return profileStore:UpdateAsync(
key,
function(
currentValue
)
local now =
os.time()
local stored =
normalizeStoredRecord(
currentValue
)
local session =
stored.Session
if type(session)
== "table"
then
local token =
session.Token
local expiresAt =
session.ExpiresAt
if typeof(token)
== "string"
and token
~= serverSessionToken
and typeof(
expiresAt
) == "number"
and expiresAt
> now
then
callbackFailure =
"SESSION_LOCKED"
return nil
end
end
local profile
if type(stored.Data)
== "table"
then
profile =
TableUtil.DeepCopy(
stored.Data
)
else
profile =
ProfileSchema.CreateDefault()
end
local prepared,
prepareError =
ProfileSchema.Prepare(
profile
)
if not prepared then
callbackFailure =
"INVALID_PROFILE: "
.. tostring(
prepareError
)
return nil
end
local oldRevision =
stored.Revision
if typeof(oldRevision)
~= "number"
then
oldRevision =
0
end
return {
RecordVersion =
1,
Revision =
math.floor(
oldRevision
) + 1,
UpdatedAt =
now,
Session =
makeSession(
now
),
Data =
profile,
}
end
)
end
)
if success then
local storedRecord =
resultOrError
if type(storedRecord)
== "table"
and type(
storedRecord.Session
) == "table"
and storedRecord.Session.Token
== serverSessionToken
and type(
storedRecord.Data
) == "table"
then
record.Data =
storedRecord.Data
record.State =
"Active"
record.LastSaveAt =
os.time()
player:SetAttribute("BloomProfileState","Active")
player:SetAttribute("BloomProfileLoaded",true)
print(
"[DataService] Profile loaded:",
player.Name
)
if record.Cancelled
or player.Parent
~= Players
then
self:ReleaseProfile(
player
)
return
end
profileLoadedEvent:Fire(
player
)
return
end
finalError =
callbackFailure
or "LOAD_CANCELLED"
if finalError
== "SESSION_LOCKED"
then
break
end
if string.find(
finalError,
"INVALID_PROFILE",
1,
true
) then
break
end
else
finalError =
tostring(
resultOrError
)
end
if attempt
< DataConfig.MaxRetries
then
task.wait(
getRetryDelay(
attempt
)
)
end
end
recordsByUserId[
userId
] = nil
player:SetAttribute("BloomProfileState","Failed")
player:SetAttribute("BloomProfileLoaded",false)
player:SetAttribute("BloomProfileError",tostring(finalError or "UNKNOWN"))
warn(
"[DataService] Failed to load profile:",
player.Name,
finalError
)
if player.Parent
== Players
then
if finalError
== "SESSION_LOCKED"
then
player:Kick(
"Your profile is already active on another server. Please try again shortly."
)
else
player:Kick(
"Your data could not be loaded safely. Please rejoin."
)
end
end
end
function DataService:SaveProfile(
player: Player,
releaseSession: boolean
): boolean
local userId =
player.UserId
local record =
recordsByUserId[
userId
]
if not record then
return false
end
if record.State ~= "Active"
and record.State ~= "Closing"
then
return false
end
if saveLocks[
userId
] then
if not releaseSession then
return false
end
local deadline =
os.clock() + 10
while saveLocks[
userId
]
and os.clock()
< deadline
do
task.wait(
0.05
)
end
if saveLocks[
userId
] then
warn(
"[DataService] Save lock timeout:",
player.Name
)
return false
end
end
saveLocks[
userId
] = true
local snapshot =
TableUtil.DeepCopy(
record.Data
)
local valid,
validationError =
ProfileSchema.Prepare(
snapshot
)
if not valid then
saveLocks[
userId
] = nil
warn(
"[DataService] Refusing to save invalid profile:",
player.Name,
validationError
)
return false
end
local key =
getKey(
userId
)
local lostOwnership =
false
local finalError:
string? = nil
for attempt = 1,
DataConfig.MaxRetries
do
local success,
resultOrError =
pcall(
function()
return profileStore:UpdateAsync(
key,
function(
currentValue
)
local stored =
normalizeStoredRecord(
currentValue
)
local session =
stored.Session
if type(session)
~= "table"
or session.Token
~= serverSessionToken
then
lostOwnership =
true
return nil
end
local now =
os.time()
local revision =
stored.Revision
if typeof(revision)
~= "number"
then
revision =
0
end
return {
RecordVersion =
1,
Revision =
math.floor(
revision
) + 1,
UpdatedAt =
now,
Session =
if releaseSession
then nil
else makeSession(
now
),
Data =
snapshot,
}
end
)
end
)
if success then
if lostOwnership then
finalError =
"SESSION_OWNERSHIP_LOST"
break
end
if type(
resultOrError
) == "table"
then
record.LastSaveAt =
os.time()
saveLocks[
userId
] = nil
print(
"[DataService] Saved:",
player.Name,
releaseSession
and "(released)"
or ""
)
return true
end
finalError =
"SAVE_CANCELLED"
else
finalError =
tostring(
resultOrError
)
end
if attempt
< DataConfig.MaxRetries
and not lostOwnership
then
task.wait(
getRetryDelay(
attempt
)
)
end
end
saveLocks[
userId
] = nil
if lostOwnership then
record.State =
"Lost"
warn(
"[DataService] Session ownership lost:",
player.Name
)
if player.Parent
== Players
then
player:Kick(
"Your data session changed unexpectedly. Please rejoin."
)
end
else
warn(
"[DataService] Save failed:",
player.Name,
finalError
)
end
return false
end
function DataService:ReleaseProfile(
player: Player
)
local userId =
player.UserId
local record =
recordsByUserId[
userId
]
if not record then
return
end
if record.State=="Transaction" then
 local deadline=os.clock()+20
 while record.State=="Transaction" and os.clock()<deadline do task.wait(.05) end
 if record.State=="Transaction" then return end
 self:ReleaseProfile(player) return
end
if record.State
== "Closing"
then
local deadline =
os.clock() + 12
while recordsByUserId[
userId
] == record
and os.clock()
< deadline
do
task.wait(
0.05
)
end
return
end
if record.State
== "Loading"
then
record.Cancelled =
true
local deadline =
os.clock() + 12
while recordsByUserId[
userId
] == record
and record.State
== "Loading"
and os.clock()
< deadline
do
task.wait(
0.05
)
end
local updatedRecord =
recordsByUserId[
userId
]
if updatedRecord
and updatedRecord.State
== "Active"
then
self:ReleaseProfile(
player
)
end
return
end
if record.State
== "Lost"
then
recordsByUserId[
userId
] = nil
return
end
record.State =
"Closing"
local saved =
self:SaveProfile(
player,
true
)
if not saved then
warn(
"[DataService] Final save failed:",
player.Name
)
end
recordsByUserId[
userId
] = nil
saveLocks[
userId
] = nil
print(
"[DataService] Profile released:",
player.Name
)
end
function DataService:AutosaveLoop()
while started
and not shuttingDown
do
local waitTime =
randomGenerator:NextNumber(
DataConfig.AutosaveMinSeconds,
DataConfig.AutosaveMaxSeconds
)
task.wait(
waitTime
)
if shuttingDown then
break
end
for _, record in pairs(
recordsByUserId
) do
if record.State
~= "Active"
then
continue
end
local player =
record.Player
if not player then
continue
end
task.spawn(
function()
self:SaveProfile(
player,
false
)
end
)
end
end
end
function DataService:Shutdown()
if shuttingDown then
return
end
shuttingDown =
true
print(
"[DataService] Server shutting down..."
)
local remaining =
0
for _, record in pairs(
recordsByUserId
) do
local player =
record.Player
if player then
remaining += 1
task.spawn(
function()
self:ReleaseProfile(
player
)
remaining -= 1
end
)
end
end
local deadline =
os.clock() + 25
while remaining > 0
and os.clock()
< deadline
do
task.wait(
0.1
)
end
print(
"[DataService] Shutdown finished"
)
end
function DataService:GetProfile(
player: Player
)
local record =
recordsByUserId[
player.UserId
]
if not record then
return nil
end
if record.State
~= "Active"
then
return nil
end
return record.Data
end
function DataService:IsLoaded(
player: Player
): boolean
local record =
recordsByUserId[
player.UserId
]
return record ~= nil
and record.State
== "Active"
end
function DataService:GetProfileLoadedSignal():
RBXScriptSignal
return profileLoadedEvent.Event
end
function DataService:CommitProfile(player, candidate, transactionId)
 local userId=player.UserId local record=recordsByUserId[userId]
 if not record or record.State~="Active" or saveLocks[userId] then return false end
 local snapshot=TableUtil.DeepCopy(candidate) local valid=ProfileSchema.Prepare(snapshot) if not valid then return false end
 snapshot.LastTransactionId=transactionId saveLocks[userId]=true record.State="Transaction"
 for attempt=1,DataConfig.MaxRetries do
  local ok,result=pcall(function() return profileStore:UpdateAsync(getKey(userId),function(value)
   local stored=normalizeStoredRecord(value)
   if type(stored.Session)~="table" or stored.Session.Token~=serverSessionToken then return nil end
   if stored.Data and stored.Data.LastTransactionId==transactionId then return stored end
   return {RecordVersion=1,Revision=(stored.Revision or 0)+1,UpdatedAt=os.time(),Session=makeSession(os.time()),Data=snapshot}
  end) end)
  if ok and type(result)=="table" and result.Data and result.Data.LastTransactionId==transactionId then
   record.Data=TableUtil.DeepCopy(result.Data) record.State="Active" record.LastSaveAt=os.time() saveLocks[userId]=nil return true
  end
  if attempt<DataConfig.MaxRetries then task.wait(getRetryDelay(attempt)) end
 end
 -- Unknown durable outcome: never overwrite the store with the pre-turn snapshot.
 record.State="Lost" saveLocks[userId]=nil player:Kick("Season save could not be confirmed. Please rejoin safely.") return false
end
return DataService
]========]
sources["ServerScriptService/Tests/SmokeTests"]=[========[local RS=game:GetService("ReplicatedStorage")
local Schema=require(script.Parent.Parent.Data.ProfileSchema)
local U=require(RS.Shared.BloomUtil)
local Pool=require(RS.Config.RollPoolConfig)
local S={}
function S.Run()
 assert(require(script.Parent.ConfigValidation).Run())
 local p=Schema.CreateDefault() assert(Schema.Prepare(p))
 local legacy={Inventory={Apple=2,Unknown=1},Currencies={FruitDust=10}}
 assert(Schema.Prepare(legacy)) local dust=legacy.Currencies.PetalDust local copies=legacy.FlowerCollection.OwnedSeedCopies.Daisy
 assert(Schema.Prepare(legacy)) assert(legacy.Currencies.PetalDust==dust and legacy.FlowerCollection.OwnedSeedCopies.Daisy==copies)
 local plan=require(RS.Shared.SeasonPlan).BuildSeasonTurnPlan(p) assert(p.Season.Count==0 and plan.After.Season.Count==1)
 local pool,total=Pool.Build(p,1,{}) local sum=0 for _,v in ipairs(pool) do sum=sum+v.Chance end assert(math.abs(sum-1)<1e-9)
 local rng=Random.new(42) for _=1,10000 do local value=rng:NextNumber()*total local found=false for _,v in ipairs(pool) do value=value-v.Weight if value<=0 then assert(v.Kind=="FlowerSeed" or v.Kind=="Bee") found=true break end end assert(found) end
 print("[Bloom] native smoke tests passed: config, migration, season plan, 10k pool samples") return true
end
return S
]========]
sources["ServerScriptService/Tests/ConfigValidation"]=[========[local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local R=require(RS.Config.RarityConfig) local W=require(RS.Config.WorkshopConfig) local L=require(RS.Config.LocationsConfig) local G=require(RS.Config.GardenSynergyConfig) local S={}
function S.Run()
 local seen={} for _,id in ipairs(R.Order) do assert(not seen[id],"Duplicate rarity") seen[id]=true end
 for _,registry in ipairs({F.Species,B.Bees}) do for id,item in pairs(registry) do assert(item.Id==id and R.Rank[item.Rarity],"Invalid registry item "..id) assert(item.DropWeight==item.DropWeight and item.DropWeight>=0 and item.DropWeight<math.huge,"Invalid weight") if item.AllowedBiomes then for biome in pairs(item.AllowedBiomes) do assert(L.Sectors[biome],"Unknown biome") end end end end
 local count=0 for id,n in pairs(W.Nodes) do count=count+1 if n.Parent then assert(W.Nodes[n.Parent],"Broken Workshop prerequisite") end end assert(count==43,"Workshop must contain 43 nodes")
 for _,recipe in ipairs(G.Recipes) do for _,id in ipairs(recipe.Species or {}) do assert(F.Species[id],"Broken recipe") end for _,i in ipairs(recipe.Slots or {}) do assert(i>=1 and i<=15 and i%1==0,"Invalid slot") end end
 return true
end return S
]========]
sources["ReplicatedStorage/Config/WorkshopEffectsConfig"]=[========[-- Every V5 node is consumed here or by its named feature handler.
return {
ROLL_1={RollCooldown=1.4},ROLL_2={Reserve=10},ROLL_3={RevealScale=.75},ROLL_4={Feature="PityDetails"},ROLL_5={RollCooldown=1.2},ROLL_6={RollCooldown=.8},
GARDEN_1={FlowerSlots=1},GARDEN_2={Adjacency=1},GARDEN_3={Feature="RepeatPlant"},GARDEN_4={FlowerSlots=3},GARDEN_5={Feature="PatternHints"},GARDEN_6={SynergyXP=2},
BEES_1={BeeSlots=1},BEES_2={TokenChance=.2},BEES_3={BeeXP=2},BEES_4={TraitCooldown=.9},BEES_5={BeeSlots=2},BEES_6={AbilityYield=1.2},
ECONOMY_1={Feature="AutoDissolve"},ECONOMY_2={Feature="DissolveFilters"},ECONOMY_3={DustYield=1.2},ECONOMY_4={MilestoneCoins=100},ECONOMY_5={StudyDiscount=.2},ECONOMY_6={CoinYield=1.15},
BLOOM_1={Feature="SeedMutation"},BLOOM_2={ManualCharge=1.2},BLOOM_3={NewWeight=1.2},BLOOM_4={Reserve=10},BLOOM_5={MutationChance=.1},BLOOM_6={SignatureWeight=1.5},
EXPLORATION_1={Feature="EventRadar"},EXPLORATION_2={RouteCharge=1.2},EXPLORATION_3={CrystalSeconds=20},EXPLORATION_4={WildInterval=.8},EXPLORATION_5={EclipseWeight=1.3},EXPLORATION_6={Feature="LaunchPads"},
LEGACY_1={Feature="KeepSeasonCard"},LEGACY_2={MemoryMastery=25},LEGACY_3={Feature="MemoryMutation"},LEGACY_4={Feature="AdvancedTrials"},LEGACY_5={Feature="ThirdMemory"},LEGACY_6={SeasonNectar=2}
}
]========]
sources["ReplicatedStorage/Config/TutorialConfig"]=[========[return {Version=2,Steps={{Event="Wake",Text="Проснись у своего улья",Target="Hive"},{Event="StarterBee",Text="Получи пчелу у улья",Target="Hive"},{Event="Work",Text="Посмотри, как пчела опыляет цветок",Target="Garden"},{Event="PollenSpark",Text="Подбери искру пыльцы",Target="Token"},{Event="Delivery",Text="Дождись доставки мёда",Target="Hive"},{Event="Roll",Text="Нажми ROLL",Target="Roll"},{Event="SeedReward",Text="Получи семя цветка",Target="Roll"},{Event="Plant",Text="Посади семя в свободную клумбу",Target="Garden"},{Event="SatchelOpen",Text="Открой сумку семян",Target="SeedSatchel"},{Event="Deliveries",Text="Сделай три доставки мёда",Target="Hive"},{Event="BloomRoll",Text="Заполни Bloom и сделай особый roll",Target="Roll"},{Event="HiveUpgrade",Text="Улучши улей",Target="Hive"},{Event="WorkshopVisit",Text="Посети мастерскую в центре",Target="Workshop"},{Event="WorkshopPurchase",Text="Купи первый узел",Target="Workshop"},{Event="Synergy",Text="Посади соседние цветы для синергии",Target="Garden"},{Event="Trait",Text="Собери две пчелы с общим свойством",Target="SeedSatchel"},{Event="SunnyVisit",Text="Пройди в Sunny Orchard",Target="SunnyOrchard"},{Event="WorldActivity",Text="Заверши активность в секторе",Target="Token"}}}
]========]
sources["ReplicatedStorage/Config/RewardPresentationConfig"]=[========[return {Common={Duration=.4,Min=.2},Uncommon={Duration=.55,Min=.25},Rare={Duration=.8,Min=.35},Epic={Duration=1.2,Min=.5},Legendary={Duration=1.8,Min=.7},Mythic={Duration=2.5,Min=1},Celestial={Duration=3.5,Min=1.2}}
]========]
sources["ReplicatedStorage/Config/SeasonConfig"]=[========[return {Hive=8,Flowers=8,Bees=5,Trials=3,TrialIds={"MeadowCircuit","SwiftRoute","CrystalTriangle"},Cards={"SpringResonance","SummerSwarm","AutumnFortune","CrystalSeason","TwilightSeason"},KeepsakeSlots=2,Reset={"Coins","Hive Honey","Hive Level","Garden Layout","Seasonal Slots","Zone Progress","Temporary Buffs"},Keep={"Discoveries","Mastery","Permanent Workshop","Core Mechanics","Cosmetics","Legacy","Seed Ownership","Bee Ownership"}}
]========]
sources["ReplicatedStorage/Config/BloomConfig"]=[========[return {SchemaVersion=5,MaxFlowerSlots=15,StartingSlots=3,MaxBeeSlots=8,MasteryCap=100,MasteryXP=25,FlowerLevelXP=20,RollCooldown=1.55,MinRollCooldown=.45,DiscoveryThreshold=30,BloomMax=100,SpecialRareMultiplier=2,SpecialNewMultiplier=2,SpecialMutationChance=.12,UnknownCopyDust=5,ComboCompensation=5,DustPerCopy=3,TickSeconds=.5,DeliverySeconds=8,HoneyPerDelivery=4,CoinsPerDelivery=6,ActivityInterval=18,SyncSeconds=1,InteractionDistance=14,RemoteBurst=12,RemoteRate=6,HiveCosts={0,40,100,220,450,850,1500,2500},Charge={Delivery=2,Token=4,Nectar=6,World=12,Event=15},SeasonReward=5,ActivityBurstCoins=5,CloverBurstCoins=3,NeighbourBonus=1.15,NeighbourSeconds=20,SwiftBonus=1.2,SwiftSeconds=15,MaxBlessings=1,BlessingSeconds=60,BlessingMultiplier=1.05,WorldCooldown=25,LandmarkDust=3,LandmarkCharge=10,JourneyCoins=10,RepeatTrialCoins=5,AbilityTokenChance=.6,RollRhythmCooldown=1.2,OverclockCooldown=.8}
]========]
sources["ReplicatedStorage/Config/UIThemeConfig"]=[========[-- Shared visual language for Bloom RNG.
local T={}

T.Colors={
 Background=Color3.fromRGB(13,18,24),
 Panel=Color3.fromRGB(20,27,36),
 PanelSoft=Color3.fromRGB(27,36,47),
 PanelRaised=Color3.fromRGB(34,45,58),
 PanelHover=Color3.fromRGB(42,56,72),
 BorderDark=Color3.fromRGB(7,10,14),
 Border=Color3.fromRGB(74,96,118),
 BorderSoft=Color3.fromRGB(55,72,89),
 Text=Color3.fromRGB(245,248,252),
 Muted=Color3.fromRGB(166,184,202),
 Faint=Color3.fromRGB(116,136,156),
 Blue=Color3.fromRGB(84,174,255),
 BlueDeep=Color3.fromRGB(37,116,198),
 BlueSoft=Color3.fromRGB(31,67,101),
 Green=Color3.fromRGB(102,224,166),
 GreenDeep=Color3.fromRGB(34,130,91),
 Gold=Color3.fromRGB(255,205,91),
 Honey=Color3.fromRGB(255,176,72),
 Dust=Color3.fromRGB(187,139,255),
 Nectar=Color3.fromRGB(98,231,214),
 Danger=Color3.fromRGB(255,111,128),
 Overlay=Color3.fromRGB(5,8,12),
 White=Color3.fromRGB(255,255,255),
 Black=Color3.fromRGB(0,0,0),
}

T.Radius={Small=8,Medium=12,Large=16,Window=20,Pill=999}
T.Stroke={Window=3,Panel=2,Control=2,Subtle=1,DarkTransparency=.08,SoftTransparency=.28}
T.Spacing={XS=5,S=8,M=12,L=16,XL=22}
T.Layout={
 Edge=16,
 ObjectiveWidth=680,
 CurrencyWidth=236,
 DockButton=52,
 DockGap=8,
 RollWidth=330,
 RollHeight=124,
 PanelMaxWidth=1040,
 PanelMaxHeight=700,
 PanelMinWidth=420,
 PanelMinHeight=360,
}
T.Motion={Fast=.10,Normal=.18,Slow=.32}

return table.freeze(T)
]========]
sources["ReplicatedStorage/Config/RarityConfig"]=[========[local C={Order={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Celestial"},Rank={},Colors={}}
local colors={Color3.fromRGB(210,215,225),Color3.fromRGB(92,220,133),Color3.fromRGB(90,165,255),Color3.fromRGB(190,110,255),Color3.fromRGB(255,190,75),Color3.fromRGB(255,95,150),Color3.fromRGB(100,245,255)}
for i,id in ipairs(C.Order) do C.Rank[id]=i C.Colors[id]=colors[i] end
return C
]========]
sources["ReplicatedStorage/Config/LocationsConfig"]=[========[return {Order={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"},Sectors={SunnyOrchard={Name="Sunny Orchard",Hive=2,Center=Vector3.new(0,0,-170),Color=Color3.fromRGB(140,210,90),Activity="SolarBloom"},CrystalGreenhouse={Name="Crystal Greenhouse",Hive=4,Center=Vector3.new(165,0,90),Color=Color3.fromRGB(90,190,235),Activity="CrystalResonance"},TwilightGrove={Name="Twilight Grove",Hive=6,Center=Vector3.new(-165,0,90),Color=Color3.fromRGB(125,90,180),Activity="FireflyRoute"}}}
]========]
sources["ReplicatedStorage/Config/GardenSynergyConfig"]=[========[local C={Recipes={
{Id="MeadowPair",Kind="Pair",Species={"Daisy","Tulip"}},
{Id="GoldenPair",Kind="Pair",Species={"Sunflower","Clover"}},
{Id="MeadowFamily",Kind="Family",Tag="Meadow",Count=3},
{Id="CrystalTriangle",Kind="Pattern",Tag="Crystal",Slots={1,2,6}},
{Id="MeadowLine",Kind="Pattern",Tag="Meadow",Slots={1,2,3}},
{Id="MeadowRing",Kind="Pattern",Tag="Meadow",Slots={1,2,3,8,13,12,11,6}},
{Id="TwilightOpposite",Kind="Pattern",Tag="Twilight",Slots={1,15}},
{Id="MeadowSwarm",Kind="Bee",Tag="Meadow",Trait="Meadow",Count=2},
{Id="CrystalResonance",Kind="Biome",Tag="Crystal",Biome="CrystalGreenhouse"},
{Id="AstralGarden",Kind="Signature",Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"}}
}}
function C.Position(i) return Vector3.new(((i-1)%5-2)*7,0,(math.floor((i-1)/5)-1)*7) end
function C.Adjacent(a,b,range) local x,y=C.Position(a),C.Position(b) return a~=b and (x-y).Magnitude<=7.1*(range or 1) end
return C
]========]
sources["ReplicatedStorage/Config/BuildTrialConfig"]=[========[return {MeadowCircuit={Id="MeadowCircuit",Name="Meadow Circuit",Sector="SunnyOrchard",Event="Delivery",Target=12,Seconds=120},SwiftRoute={Id="SwiftRoute",Name="Swift Route",Sector="SunnyOrchard",Event="PollenTrail",Target=1,Seconds=120},CrystalTriangle={Id="CrystalTriangle",Name="Crystal Triangle",Sector="CrystalGreenhouse",Event="CrystalResonance",Target=1,Seconds=120},NoCelestial={Id="NoCelestial",Name="No-Celestial Trial",Sector="CrystalGreenhouse",Event="WorldActivity",Target=1,Seconds=120},SignatureBloom={Id="SignatureBloom",Name="Signature Bloom",Sector="TwilightGrove",Event="Synergy",Target=1,Seconds=120},TwilightPulse={Id="TwilightPulse",Name="Twilight Pulse",Sector="TwilightGrove",Event="Ability",Target=3,Seconds=120},MinimalGarden={Id="MinimalGarden",Name="Minimal Garden",Sector="SunnyOrchard",Event="Delivery",Target=15,Seconds=120},MutationStudy={Id="MutationStudy",Name="Mutation Study",Sector="CrystalGreenhouse",Event="Mutation",Target=1,Seconds=120}}
]========]
sources["ReplicatedStorage/Config/RollPoolConfig"]=[========[local F=require(script.Parent.FlowersConfig) local B=require(script.Parent.BeesConfig) local R=require(script.Parent.RarityConfig) local C=require(script.Parent.BloomConfig)
local S={}
function S.Build(p,luck,temp)
 local pool={} local function add(kind,items) for id,v in pairs(items) do
  local unlocked=kind=="Bee" if kind=="FlowerSeed" then for sector in pairs(v.AllowedBiomes) do if p.World.UnlockedSectors[sector] or sector=="SunnyOrchard" then unlocked=true end end end
  if unlocked then local discovered=kind=="Bee" and p.Pollinators.DiscoveredBees[id] or kind=="FlowerSeed" and p.FlowerCollection.DiscoveredFlowers[id]
   local rank=R.Rank[v.Rarity] local w=v.DropWeight*(1+(luck-1)*(rank-1)*.25)
   if p.RollState.SpecialRollReady then if rank>=3 then w=w*C.SpecialRareMultiplier end if not discovered then w=w*C.SpecialNewMultiplier*(p.WorkshopV5.Nodes.BLOOM_3 and 1.2 or 1)*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1) end if temp.Eclipse then w=w*(rank>=5 and (p.WorkshopV5.Nodes.EXPLORATION_5 and 1.95 or 1.5) or 1) end if p.WorkshopV5.Nodes.BLOOM_6 and temp.Signature and rank>=5 then w=w*1.5 end end
   table.insert(pool,{Kind=kind,Id=id,DisplayName=v.DisplayName,Rarity=v.Rarity,Weight=w,Undiscovered=not discovered})
  end end end
 add("FlowerSeed",F.Species) add("Bee",B.Bees) table.sort(pool,function(a,b) return a.Kind..a.Id<b.Kind..b.Id end)
 if p.RollState.DiscoveryPity+1>=C.DiscoveryThreshold then local new={} for _,v in ipairs(pool) do if v.Undiscovered then table.insert(new,v) end end if #new>0 then pool=new end end
 local total=0 for _,v in ipairs(pool) do total=total+v.Weight end for _,v in ipairs(pool) do v.Chance=v.Weight/total v.Odds=total/v.Weight end return pool,total
end
return S
]========]
sources["ReplicatedStorage/Config/WorkshopConfig"]=[========[local C={Version=5,Nodes={},Branches={"ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"},Tree={HexSize=52,HexSpacing=1.55,CanvasWidth=1760,CanvasHeight=1320,BaseRadius=132,RadialStep=92}}
local names={ROLL={"Roll Tempo","Bloom Reserve","Fast Reveal","Discovery Lens","Roll Rhythm","Overclock"},GARDEN={"Flower Slot","Wide Adjacency","Quick Replant","Flower Slots","Pattern Lens","Living Garden"},BEES={"Bee Slot","Ability Tokens","Mastery Practice","Trait Depth","Bee Slots","Swarm Protocol"},ECONOMY={"Auto Dissolve","Rarity Filters","Duplicate Conversion","Milestone Chest","Dust Study","Prosperity"},BLOOM={"Mutation Slot","Active Nectar","Rare Seed Rule","Charge Reserve","Mutation Study","Signature Rule"},EXPLORATION={"Event Radar","Route Bonus","Crystal Interaction","Wild Bloom Sense","Twilight Interaction","Wayfinder"},LEGACY={"Season Memory","Keepsake","Legacy Mutation","Advanced Trials","Third Memory","Season Scholar"}}
C.Nodes.CORE={Id="CORE",Name="Bloom Core",Cost=0,Branch="CORE",Index=0}
for b,branch in ipairs(C.Branches) do for i,name in ipairs(names[branch]) do local id=branch.."_"..i C.Nodes[id]={Id=id,Name=name,Branch=branch,Index=i,Cost=1,Coins=i*30,Dust=(branch=="ECONOMY" or branch=="BLOOM") and i*3 or 0,Nectar=branch=="LEGACY" and i or 0,Parent=i==1 and "CORE" or branch.."_"..(i-1),Hive=math.min(5,math.ceil(i/2)),Angle=(b-1)*math.pi*2/7,Radius=132+(i-1)*92,Permanent=branch=="LEGACY"} end end
return C
]========]
sources["ReplicatedStorage/Config/FeatureUnlockConfig"]=[========[return {Roll={Step=6},SeedSatchel={Event="SeedReward"},FieldGuide={Step=9},Workshop={Event="WorkshopVisit"},Map={Event="SunnyVisit"},Trials={Event="SunnyVisit"}}
]========]
sources["ReplicatedStorage/Config/RollAudioConfig"]=[========[return {
 SpinSound="rbxasset://sounds/button.wav",
 RewardSound="rbxasset://sounds/electronicpingshort.wav",
 SpinVolume=.055,
 RewardVolume=.14,
 SpinPlaybackSpeed=1.08,
 RewardPlaybackSpeed=1.02,
 MinimumVisualSpin=2.35,
 StepPixels=48,
 CruiseStep=.18,
 SettleSteps={.10,.10,.11,.12,.14,.17,.21,.27,.34,.42},
 ResultHold=.5,
}
]========]
sources["ReplicatedStorage/Config/BeesConfig"]=[========[--!strict
local C={}
C.RarityOrder={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Exotic","Celestial"}
C.RarityRank={Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6,Exotic=7,Celestial=8}
C.RarityColors={
 Common=Color3.fromRGB(220,220,220),Uncommon=Color3.fromRGB(96,230,132),Rare=Color3.fromRGB(91,173,255),Epic=Color3.fromRGB(194,115,255),
 Legendary=Color3.fromRGB(255,187,82),Mythic=Color3.fromRGB(255,108,131),Exotic=Color3.fromRGB(255,92,220),Celestial=Color3.fromRGB(91,230,255),
}
C.Traits={
 Meadow={Id="Meadow",Name="MEADOW",Short="M",Color=Color3.fromRGB(92,202,112),Description="Garden synergy. Matching bees can splash their work and occasionally cross-pollinate a second flower at the same time.",Breakpoints={{Count=2,Bonus={FlowerGrowthMultiplier=1.10,SplashChance=.12,SplashPercent=.20,DualPollinationChance=.08,DualPollinationPercent=.35}},{Count=4,Bonus={FlowerGrowthMultiplier=1.25,SplashChance=.22,SplashPercent=.35,DualPollinationChance=.18,DualPollinationPercent=.65}}}},
 Swift={Id="Swift",Name="SWIFT",Short="S",Color=Color3.fromRGB(70,190,242),Description="Mobility synergy. Faster travel and shorter active-ability cooldowns.",Breakpoints={{Count=2,Bonus={PollinatorTravelSpeedMultiplier=1.15,AbilityCooldownMultiplier=.90}},{Count=3,Bonus={PollinatorTravelSpeedMultiplier=1.35,AbilityCooldownMultiplier=.78}}}},
 Bloom={Id="Bloom",Name="BLOOM",Short="B",Color=Color3.fromRGB(238,112,175),Description="Harvest synergy. More pollination yield and more Honey delivered to your personal Hive.",Breakpoints={{Count=2,Bonus={PollinatorYieldMultiplier=1.15,HiveHoneyMultiplier=1.12}},{Count=3,Bonus={PollinatorYieldMultiplier=1.35,HiveHoneyMultiplier=1.30}}}},
 Arcane={Id="Arcane",Name="ARCANE",Short="A",Color=Color3.fromRGB(145,104,235),Description="Knowledge synergy. Better roll luck and much faster Bee Mastery growth.",Breakpoints={{Count=2,Bonus={LuckMultiplier=1.10,BeeMasteryXPMultiplier=1.25}},{Count=3,Bonus={LuckMultiplier=1.28,BeeMasteryXPMultiplier=1.65}}}},
 Royal={Id="Royal",Name="ROYAL",Short="R",Color=Color3.fromRGB(235,180,61),Description="Economy synergy. More coins and a chance for critical pollination bursts.",Breakpoints={{Count=1,Bonus={CoinMultiplier=1.12,CriticalChance=.08,CriticalMultiplier=1.75}},{Count=2,Bonus={CoinMultiplier=1.30,CriticalChance=.16,CriticalMultiplier=2.00}}}},
 Mirror={Id="Mirror",Name="MIRROR",Short="M",Color=Color3.fromRGB(222,96,236),Description="Ability synergy. Clone effects become stronger and active abilities last longer.",Breakpoints={{Count=1,Bonus={ClonePowerMultiplier=1.15,AbilityDurationMultiplier=1.10}},{Count=2,Bonus={ClonePowerMultiplier=1.45,AbilityDurationMultiplier=1.30}}}},
 Twilight={Id="Twilight",Name="TWILIGHT",Short="T",Color=Color3.fromRGB(113,88,211),Description="Late-game synergy. Stronger bees, better yield and substantially faster abilities.",Breakpoints={{Count=1,Bonus={PollinatorPowerMultiplier=1.10,PollinatorYieldMultiplier=1.07,AbilityCooldownMultiplier=.94}},{Count=2,Bonus={PollinatorPowerMultiplier=1.30,PollinatorYieldMultiplier=1.22,AbilityCooldownMultiplier=.80}}}},
}
C.Bees={
 WorkerBee={Id="WorkerBee",DisplayName="Worker Bee",SortOrder=1,DropWeight=220000,Rarity="Common",Color=Color3.fromRGB(255,193,48),Traits={"Meadow","Bloom"},Passive={PollinatorPowerMultiplier=1.03},Ability={Id="PollenBurst",Name="Pollen Burst",Duration=8,Cooldown=48,WorkMultiplier=1.35,RewardMultiplier=1.12,Visual="Glow",Description="Every 48s, works 35% harder and earns 12% more for 8s."}},
 SprinterBee={Id="SprinterBee",DisplayName="Sprinter Bee",SortOrder=2,DropWeight=160000,Rarity="Common",Color=Color3.fromRGB(255,229,110),Traits={"Swift","Meadow"},Passive={PollinatorTravelSpeedMultiplier=1.08},Ability={Id="Afterburner",Name="Afterburner",Duration=9,Cooldown=46,WorkMultiplier=1.45,RewardMultiplier=1.05,Visual="Speed",Description="Every 46s, enters overdrive for 9s and works 45% harder."}},
 NectarBee={Id="NectarBee",DisplayName="Nectar Bee",SortOrder=3,DropWeight=120000,Rarity="Uncommon",Color=Color3.fromRGB(255,145,75),Traits={"Bloom","Meadow"},Passive={PollinatorYieldMultiplier=1.08},Ability={Id="HoneyFlood",Name="Honey Flood",Duration=12,Cooldown=62,WorkMultiplier=1.16,RewardMultiplier=1.65,HiveHoneyMultiplier=1.45,Visual="Honey",Description="Every 62s, floods its flower with nectar for 12s, boosting rewards and Hive Honey."}},
 ScholarBee={Id="ScholarBee",DisplayName="Scholar Bee",SortOrder=4,DropWeight=80000,Rarity="Uncommon",Color=Color3.fromRGB(110,180,255),Traits={"Arcane","Swift"},Passive={LuckMultiplier=1.05},Ability={Id="FieldStudy",Name="Field Study",Duration=14,Cooldown=66,WorkMultiplier=1.25,RewardMultiplier=1.10,PlayerXPMultiplier=1.75,BeeMasteryXPMultiplier=2.0,Visual="Arcane",Description="Every 66s, studies a flower for 14s, greatly boosting player and Bee Mastery XP."}},
 TwinBee={Id="TwinBee",DisplayName="Twin Bee",SortOrder=5,DropWeight=32000,Rarity="Rare",Color=Color3.fromRGB(165,120,255),Traits={"Mirror","Swift"},Passive={PollinatorPowerMultiplier=1.05},Ability={Id="CloneBurst",Name="Clone Burst",Duration=30,Cooldown=100,WorkMultiplier=2.00,RewardMultiplier=1.85,Visual="Clone",Description="Every 100s, creates a clone for 30s. The pair works at roughly x2 power."}},
 RoyalBee={Id="RoyalBee",DisplayName="Royal Bee",SortOrder=6,DropWeight=9000,Rarity="Epic",Color=Color3.fromRGB(255,205,82),Traits={"Royal","Meadow"},Passive={CoinMultiplier=1.10,PollinatorYieldMultiplier=1.06},Ability={Id="RoyalDecree",Name="Royal Decree",Duration=14,Cooldown=82,WorkMultiplier=1.50,RewardMultiplier=1.90,CriticalChanceBonus=.12,Visual="Royal",Description="Every 82s, issues a decree for 14s: stronger work, better rewards and extra crit chance."}},
 PrismBee={Id="PrismBee",DisplayName="Prism Bee",SortOrder=7,DropWeight=1600,Rarity="Legendary",Color=Color3.fromRGB(100,255,255),Traits={"Arcane","Bloom","Royal","Twilight"},Passive={LuckMultiplier=1.08,PollinatorYieldMultiplier=1.10,FlowerGrowthMultiplier=1.05},Ability={Id="PrismOverload",Name="Prism Overload",Duration=16,Cooldown=92,WorkMultiplier=2.10,RewardMultiplier=1.55,PlayerXPMultiplier=1.35,BeeMasteryXPMultiplier=1.40,Visual="Prism",Description="Every 92s, overloads for 16s: huge work, reward and XP boost."}},
 TwilightBee={Id="TwilightBee",DisplayName="Twilight Bee",SortOrder=8,DropWeight=220,Rarity="Mythic",Color=Color3.fromRGB(210,95,255),Traits={"Twilight","Mirror","Arcane"},Passive={PollinatorPowerMultiplier=1.12,PollinatorTravelSpeedMultiplier=1.06,PollinatorYieldMultiplier=1.08},Ability={Id="Eclipse",Name="Eclipse",Duration=12,Cooldown=80,WorkMultiplier=2.70,RewardMultiplier=2.05,PlayerXPMultiplier=1.55,HiveHoneyMultiplier=1.35,Visual="Eclipse",Description="Every 80s, triggers Eclipse for 12s: massive work, rewards and Hive Honey."}},

 BloomQueenBee={Id="BloomQueenBee",DisplayName="Bloom Queen Bee",SortOrder=9,DropWeight=120,Rarity="Exotic",Color=Color3.fromRGB(255,118,190),Traits={"Bloom","Meadow","Royal"},Passive={PollinatorYieldMultiplier=1.14,FlowerGrowthMultiplier=1.08,CoinMultiplier=1.05},Ability={Id="RoyalBloom",Name="Royal Bloom",Duration=14,Cooldown=95,WorkMultiplier=1.55,RewardMultiplier=1.30,HiveHoneyMultiplier=1.65,ExtraTargetCount=1,ExtraTargetPercent=.55,Visual="Bloom",Description="Every 95s, rules the garden for 14s: +55% work, +65% Hive Honey, and every pollination also blooms a second flower for 55% power."}},
 CrystalBee={Id="CrystalBee",DisplayName="Crystal Bee",SortOrder=10,DropWeight=60,Rarity="Exotic",Color=Color3.fromRGB(116,220,255),Traits={"Arcane","Mirror","Twilight"},Passive={LuckMultiplier=1.10,PollinatorPowerMultiplier=1.10},Ability={Id="CrystalResonance",Name="Crystal Resonance",Duration=7,Cooldown=100,WorkMultiplier=1.35,RewardMultiplier=1.20,TickCount=4,TickInterval=1.25,TickWorkSeconds=.70,TickRewardMultiplier=1.35,TickHiveMultiplier=1.20,Visual="Crystal",Description="Every 100s, crystallizes its flower and releases 4 resonance pulses. Each pulse adds extra pollination, coins and Honey while the bee keeps working."}},
 MagmaBee={Id="MagmaBee",DisplayName="Magma Bee",SortOrder=11,DropWeight=30,Rarity="Exotic",Color=Color3.fromRGB(255,93,35),Traits={"Royal","Bloom","Twilight"},Passive={PollinatorPowerMultiplier=1.15,PollinatorYieldMultiplier=1.08},Ability={Id="MagmaSpill",Name="Magma Spill",Duration=6,Cooldown=90,WorkMultiplier=1.25,RewardMultiplier=1.20,TickCount=5,TickInterval=1.10,TickWorkSeconds=.85,TickRewardMultiplier=1.40,TickHiveMultiplier=1.15,Visual="Magma",Description="Every 90s, spills magma on its flower. The magma pollinates it 5 extra times over 5.5s and each tick produces boosted coin value and Honey."}},
 ShadowBee={Id="ShadowBee",DisplayName="Shadow Bee",SortOrder=12,DropWeight=12,Rarity="Celestial",Color=Color3.fromRGB(122,55,226),Traits={"Twilight","Mirror","Swift"},Passive={PollinatorTravelSpeedMultiplier=1.14,LuckMultiplier=1.12,PollinatorPowerMultiplier=1.12},Ability={Id="ShadowEcho",Name="Shadow Echo",Duration=12,Cooldown=84,WorkMultiplier=1.65,RewardMultiplier=1.45,ExtraTargetCount=1,ExtraTargetPercent=.85,Visual="Shadow",Description="Every 84s, creates a shadow echo for 12s. The echo copies 85% of its work onto a second flower while the original bee gains stronger work and rewards."}},
 StormBee={Id="StormBee",DisplayName="Storm Bee",SortOrder=13,DropWeight=4,Rarity="Celestial",Color=Color3.fromRGB(55,185,255),Traits={"Swift","Royal","Arcane","Twilight"},Passive={PollinatorPowerMultiplier=1.18,PollinatorTravelSpeedMultiplier=1.15,PollinatorYieldMultiplier=1.12},Ability={Id="ChainTempest",Name="Chain Tempest",Duration=7,Cooldown=110,WorkMultiplier=1.85,RewardMultiplier=1.55,BurstTargets=4,BurstWorkSeconds=2.20,BurstRewardMultiplier=1.45,BurstHiveMultiplier=1.20,Visual="Storm",Description="Every 110s, calls a chain tempest that instantly strikes up to 4 flowers, then supercharges the bee for 7s."}},
}
local Rarity=require(script.Parent.RarityConfig)
C.RarityOrder=Rarity.Order C.RarityRank=Rarity.Rank C.RarityColors=Rarity.Colors
for _,bee in pairs(C.Bees) do if bee.Rarity=="Exotic" then bee.Rarity="Mythic" end end
function C.Get(id) return C.Bees[id] end
function C.Exists(id) return C.Bees[id]~=nil end
function C.GetTraitCounts(equipped) local out={} for _,id in pairs(equipped) do for _,tag in ipairs(C.Bees[id].Traits) do out[tag]=(out[tag] or 0)+1 end end return out end
function C.GetTraitBonuses() return {LuckMultiplier=1,PollinatorYieldMultiplier=1},{} end
function C.GetPassiveBonuses() return {LuckMultiplier=1,PollinatorYieldMultiplier=1} end
return C]========]
sources["ReplicatedStorage/Config/AnalyticsConfig"]=[========[return {Enabled=false,FlushSeconds=60,Events={Wake="tutorial_started",StarterBee="first_bee_granted",Work="first_pollination_work",PollenSpark="first_active_token_collected",Delivery="first_hive_delivery",Roll="first_roll",SeedReward="first_flower_discovered",Plant="first_flower_planted",BloomRoll="first_bloom_roll",WorkshopVisit="first_workshop_open",WorkshopPurchase="first_workshop_purchase",Synergy="first_garden_synergy",Trait="first_bee_trait",SunnyVisit="first_public_zone_entered",WorldActivity="first_world_activity_complete",TutorialComplete="tutorial_completed"}}
]========]
sources["ReplicatedStorage/Config/UIAssetsConfig"]=[========[-- Compatibility adapter; edit asset IDs only in IconsConfig.
return require(script.Parent.IconsConfig)
]========]
sources["ReplicatedStorage/Config/FlowersConfig"]=[========[--!strict
local C={Species={}}
local function s(id,name,rarity,shape,color,yield,sectors,accent)
 local a={}for _,x in ipairs(sectors)do a[x]=true end
 C.Species[id]={Id=id,DisplayName=name,Rarity=rarity,ShapeKey=shape,Color=color,AccentColor=accent or color:Lerp(Color3.new(1,1,1),.35),BaseYield=yield,AllowedSectors=a}
end
s("Daisy","Daisy","Common","Daisy",Color3.fromRGB(245,245,245),.20,{"StarterOrchard"},Color3.fromRGB(245,210,80))
s("Tulip","Tulip","Common","Tulip",Color3.fromRGB(235,80,100),.25,{"StarterOrchard"},Color3.fromRGB(255,176,84))
s("Sunflower","Sunflower","Uncommon","Sunflower",Color3.fromRGB(245,190,45),.35,{"StarterOrchard"},Color3.fromRGB(95,64,24))
s("Clover","Clover","Uncommon","Clover",Color3.fromRGB(80,210,100),.30,{"StarterOrchard"},Color3.fromRGB(140,255,165))
s("CrystalRose","Crystal Rose","Rare","CrystalRose",Color3.fromRGB(120,220,255),.48,{"CrystalGreenhouse"},Color3.fromRGB(210,247,255))
s("FrostLily","Frost Lily","Rare","FrostLily",Color3.fromRGB(190,235,255),.52,{"CrystalGreenhouse"},Color3.fromRGB(255,255,255))
s("PrismBloom","Prism Bloom","Epic","PrismBloom",Color3.fromRGB(185,120,255),.60,{"CrystalGreenhouse"},Color3.fromRGB(255,153,218))
s("MoonOrchid","Moon Orchid","Epic","MoonOrchid",Color3.fromRGB(110,145,255),.66,{"CrystalGreenhouse"},Color3.fromRGB(213,230,255))
s("Nightshade","Nightshade","Legendary","Nightshade",Color3.fromRGB(105,55,145),.82,{"TwilightGrove"},Color3.fromRGB(160,110,255))
s("VoidLotus","Void Lotus","Legendary","VoidLotus",Color3.fromRGB(80,40,115),.90,{"TwilightGrove"},Color3.fromRGB(220,120,255))
s("StarBloom","Star Bloom","Mythic","StarBloom",Color3.fromRGB(255,210,105),1.05,{"TwilightGrove"},Color3.fromRGB(255,248,195))
s("EmberDahlia","Ember Dahlia","Mythic","EmberDahlia",Color3.fromRGB(255,95,65),1.15,{"TwilightGrove"},Color3.fromRGB(255,190,105))
function C.GetSpecies(id)local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C.Species[id]end
function C.Exists(id) local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C.Species[id]~=nil end
local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C
]========]
sources["ReplicatedStorage/Config/ActivityConfig"]=[========[return {MaxVisible=2,PickupDistance=10,HoldSeconds=.6,MutationChance=.08,DewMax=3,TokenSound="rbxasset://sounds/electronicpingshort.wav",Types={PollenSpark={Life=8,Steps=1,Charge=4},NectarBud={Life=10,Steps=1,Charge=6,Hold=true},DewDrop={Life=8,Steps=1,Charge=0},PollenTrail={Life=25,Steps=4,Charge=8},CrossPollination={Life=20,Steps=3,Charge=8},Overcharge={Life=8,Steps=1,Charge=4},BloomSurge={Life=45,Steps=5,Charge=12},PollenWind={Life=45,Steps=5,Charge=12},SolarBloom={Life=30,Steps=3,Charge=12},CrystalResonance={Life=35,Steps=3,Charge=12},ShadowBloom={Life=10,Steps=1,Charge=12},FireflyRoute={Life=40,Steps=5,Charge=12}},EventInterval=180,PulseDuration=90,ServerBloomTarget=120}
]========]
sources["ReplicatedStorage/Config/IconsConfig"]=[========[--!strict
local C={}
local function asset(id:number):string return id>0 and("rbxassetid://"..id)or""end
local function thumb(id:number):string return id>0 and("rbxthumb://type=Asset&id="..id.."&w=420&h=420")or""end

C.Ids={
Fruits={Apple=137259411920180,Banana=120948463128434,Lemon=103009882213725,Pear=92207064875831,Kiwi=70401616307003,Watermelon=100292298966757,Coconut=113261714314494,Pomegranate=123178380279789,Dragonfruit=94108458069090,Peach=77058315830936,Grape=109914546442995,Pineapple=130286215947765,Starfruit=129937365073228},
Bees={WorkerBee=120474399887250,SprinterBee=81841357837322,NectarBee=125666499506926,ScholarBee=113247515668453,TwinBee=79186329071015,RoyalBee=90863269031200,PrismBee=71487091178305,TwilightBee=114763891690754,BloomQueenBee=111205051533608,CrystalBee=105869326934726,MagmaBee=138449294199376,ShadowBee=133728580716533,StormBee=94635050980764},

-- New uploaded UI set.
Actions={Roll=125311014921608,AutoRoll=95369396982504},
Menus={Index=95009714203350,Inventory=102678620554602,Workshop=121024323846687,Settings=74677124320045,Shop=88512137472413},
Currencies={Coins=110435036629715,FruitDust=111742972197656},
System={
 ArrowLeft=77190512602362,
 ArrowRight=122373491010297,
 Bee=89451566883771,
 Close=136238101956753,
 Confirm=112568733630169,
 Flower=117046422836136,
 Garden=74690198578201,
 Hive=112708830524820,
 Info=72782667939249,
 Lock=139746584718669,
 Minus=120883253848128,
 Plus=123220293807442,
 Quests=131527836752075,
 Settings=74677124320045,
 Shop=88512137472413,
 Tutorial=110567723791302,
 Upgrade=131390447056966,
 Warning=72509884923996,
},
Traits={
 Arcane=107235778675419,
 Bloom=98986636122613,
 Meadow=94835696478747,
 Mirror=139563396062519,
 Royal=96988868577523,
 Twilight=90171956399486,
 -- Swift has no uploaded icon yet; UI automatically falls back to its letter.
},
WorkshopHex={
Core=71682727693014,Luck=73022903468214,Roll=96003454739859,AutoRoll=119772472490649,
Economy=130962287537873,Garden=95197859726989,Duplicate=79588703542322,FruitDust=85961992422194,
Loadout=77453527674761,Locked=135546891455390,Mastery=85961992422194,Bee=89451566883771,
},
}

function C.GetFruitIcon(id:string):string local v=C.Ids.Fruits[id]return typeof(v)=="number"and asset(v)or""end
function C.GetBeeIcon(id:string):string local v=C.Ids.Bees[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetActionIcon(id:string):string local v=C.Ids.Actions[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetMenuIcon(id:string):string local v=C.Ids.Menus[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetCurrencyIcon(id:string):string local v=C.Ids.Currencies[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetSystemIcon(id:string):string local v=C.Ids.System[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetTraitIcon(id:string):string local v=C.Ids.Traits[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetWorkshopHexIcon(id:string):string local v=C.Ids.WorkshopHex[id]return typeof(v)=="number"and thumb(v)or""end
-- All IDs are from the supplied project. Zero means no uploaded asset yet.
C.Ids.LegacyFruits=C.Ids.Fruits
C.Ids.Flowers={Daisy=0,Tulip=0,Sunflower=0,Clover=0,CrystalRose=0,FrostLily=0,PrismBloom=0,MoonOrchid=0,Nightshade=0,VoidLotus=0,StarBloom=0,EmberDahlia=0}
C.Ids.Activities={PollenSpark=0,NectarBud=0,DewDrop=0,PollenTrail=0,CrossPollination=0,Overcharge=0,BloomSurge=0,PollenWind=0,SolarBloom=0,CrystalResonance=0,FireflyRoute=0,ShadowBloom=0}
C.Ids.Seasons={SpringResonance=0,SummerSwarm=0,AutumnFortune=0,CrystalSeason=0,TwilightSeason=0}
C.Ids.Currencies.PetalDust=C.Ids.Currencies.FruitDust C.Ids.Currencies.AncientNectar=0
C.Ids.Menus.SeedSatchel=C.Ids.Menus.Inventory C.Ids.Menus.FieldGuide=C.Ids.System.Flower C.Ids.Menus.Map=0 C.Ids.Menus.Trials=C.Ids.System.Quests
C.Ids.Traits.Swift=0
function C.Get(group,id) local t=C.Ids[group] local value=t and t[id] if type(value)~="number" or value<=0 then return "" end return group=="Fruits" and asset(value) or thumb(value) end
function C.GetFlowerIcon(id) return C.Get("Flowers",id) end
function C.GetRewardIcon(kind,id) if kind=="Bee" then return C.Get("Bees",id) end local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end
return C
]========]
sources["ReplicatedStorage/Shared/WorkshopEffects"]=[========[local Config=require(game:GetService("ReplicatedStorage").Config.WorkshopEffectsConfig)
local S={}
function S.Get(p,key,default)
 local result=default or 0
 for id,owned in pairs(p.WorkshopV5.Nodes) do if owned and Config[id] and Config[id][key]~=nil then local v=Config[id][key] if type(v)=="number" then if string.find(key,"Scale") or string.find(key,"Yield") or string.find(key,"Charge") or string.find(key,"Weight") or string.find(key,"Interval") or string.find(key,"Cooldown") then result=result==0 and v or math.min(result,v) else result=result+v end end end end
 return result
end return S
]========]
sources["ReplicatedStorage/Shared/BloomUtil"]=[========[local U={}
function U.Copy(t) if type(t)~="table" then return t end local r={} for k,v in pairs(t) do r[k]=U.Copy(v) end return r end
function U.Count(t) local n=0 for _,v in pairs(t or {}) do if v then n=n+1 end end return n end
function U.Number(x,default,max) if type(x)~="number" or x~=x or math.abs(x)==math.huge then return default or 0 end return math.clamp(x,0,max or 1e12) end
function U.Integer(x,max) return type(x)=="number" and x==x and x>=1 and x<=max and x%1==0 end
function U.Near(player,pos,distance) local c=player.Character local r=c and c:FindFirstChild("HumanoidRootPart") local h=c and c:FindFirstChildOfClass("Humanoid") return r~=nil and h~=nil and h.Health>0 and (r.Position-pos).Magnitude<=distance end
function U.Equal(a,b) if type(a)~=type(b) then return false end if type(a)~="table" then return a==b end for k,v in pairs(a) do if not U.Equal(v,b[k]) then return false end end for k in pairs(b) do if a[k]==nil then return false end end return true end
return U
]========]
sources["ReplicatedStorage/Shared/TableUtil"]=[========[--!strict
local TableUtil = {}
function TableUtil.DeepCopy(source)
local copy = {}
for key, value in pairs(source) do
if type(value) == "table" then
copy[key] = TableUtil.DeepCopy(value)
else
copy[key] = value
end
end
return copy
end
return TableUtil
]========]
sources["ReplicatedStorage/Shared/SeasonPlan"]=[========[local RS=game:GetService("ReplicatedStorage") local U=require(RS.Shared.BloomUtil) local C=require(RS.Config.BloomConfig) local S={}
function S.BuildSeasonTurnPlan(profile)
 local before=U.Copy(profile) local after=U.Copy(profile)
 after.Currencies.Coins=0 after.Currencies.AncientNectar=after.Currencies.AncientNectar+C.SeasonReward+(profile.WorkshopV5.Nodes.LEGACY_6 and 2 or 0)
 after.Hive={Level=1,Honey=0,TotalHoney=profile.Hive.TotalHoney}
 after.Garden={UnlockedSlots=3,Slots={},Revision=profile.Garden.Revision+1} for i=1,15 do after.Garden.Slots[i]={} end
 local flower=profile.Season.Keepsakes.Flower or "Daisy" after.FlowerCollection.OwnedSeedCopies[flower]=math.max(1,after.FlowerCollection.OwnedSeedCopies[flower] or 0)
 after.Garden.Slots[1]={SpeciesId=flower,Level=1,XP=0,Mutation=profile.WorkshopV5.Nodes.LEGACY_3 and profile.Season.Keepsakes.Flower and "Memory" or "",TotalPollination=0}
 after.World.UnlockedSectors={Center=true} after.Season.Count=profile.Season.Count+1 after.Season.ActiveCard=profile.WorkshopV5.Nodes.LEGACY_1 and profile.Season.ActiveCard or "" after.Season.CompletedGoals={}
 after.RollState.BloomCharge=0 after.RollState.SpecialRollReady=false
 for id in pairs(after.WorkshopV5.Nodes) do if not after.WorkshopV5.LegacyNodes[id] then after.WorkshopV5.Nodes[id]=nil after.WorkshopV5.Points=after.WorkshopV5.Points+1 end end
 local bee=profile.Season.Keepsakes.Bee or "WorkerBee" after.Pollinators.BeeInventory[bee]=math.max(1,after.Pollinators.BeeInventory[bee] or 0) after.Pollinators.EquippedBeeSlots={bee}
 if profile.WorkshopV5.Nodes.LEGACY_2 and profile.Season.Keepsakes.Bee then after.Pollinators.BeeMastery[bee]=(tonumber(after.Pollinators.BeeMastery[bee]) or 0)+25 end
 if profile.WorkshopV5.Nodes.LEGACY_5 and profile.Season.Keepsakes.Flower2 then local id=profile.Season.Keepsakes.Flower2 after.FlowerCollection.OwnedSeedCopies[id]=math.max(id==flower and 2 or 1,after.FlowerCollection.OwnedSeedCopies[id] or 0) after.Garden.Slots[2]={SpeciesId=id,Level=1,XP=0,Mutation="Memory",TotalPollination=0} end
 after.StarterBeeGranted=true
 local diff={} local function walk(a,b,path) if type(a)=="table" and type(b)=="table" then local keys={} for k in pairs(a) do keys[k]=true end for k in pairs(b) do keys[k]=true end local ordered={} for k in pairs(keys) do table.insert(ordered,k) end table.sort(ordered,function(x,y) return tostring(x)<tostring(y) end) for _,k in ipairs(ordered) do walk(a[k],b[k],path.."."..tostring(k)) end elseif a~=b then table.insert(diff,{Path=path,Before=U.Copy(a),After=U.Copy(b)}) end end
 walk(before,after,"Profile") return {Before=before,After=after,Diff=diff}
end
return S
]========]
sources["ReplicatedStorage/Shared/ReactPackages"]=[========[--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local function findPackage(names: {string}): Instance
for _, name in ipairs(names) do
local package = Packages:FindFirstChild(name)
if package then
return package
end
end
error("[ReactPackages] Package not found: " .. table.concat(names, " / "))
end
local React = require(findPackage({
"React",
"react",
}))
local ReactRoblox = require(findPackage({
"ReactRoblox",
"react-roblox",
}))
return {
React = React,
ReactRoblox = ReactRoblox,
}
]========]
sources["ReplicatedStorage/Shared/NumberFormatter"]=[========[--!strict
local NumberFormatter = {}
function NumberFormatter.Compact(
value: number
): string
if typeof(value) ~= "number" then
return "0"
end
if value ~= value
or value == math.huge
or value == -math.huge
then
return "0"
end
local negative =
value < 0
local absolute =
math.abs(value)
local suffix = ""
local divisor = 1
if absolute >= 1_000_000_000 then
suffix = "B"
divisor = 1_000_000_000
elseif absolute >= 1_000_000 then
suffix = "M"
divisor = 1_000_000
elseif absolute >= 1_000 then
suffix = "K"
divisor = 1_000
end
if divisor == 1 then
local rounded =
math.floor(
absolute
)
return (
negative
and "-"
or ""
)
.. tostring(
rounded
)
end
local compact =
absolute / divisor
local text
if compact >= 100 then
text =
string.format(
"%.0f",
compact
)
elseif compact >= 10 then
text =
string.format(
"%.1f",
compact
)
else
text =
string.format(
"%.2f",
compact
)
end
text =
string.gsub(
text,
"(%..-)0+$",
"%1"
)
text =
string.gsub(
text,
"%.$",
""
)
return (
negative
and "-"
or ""
)
.. text
.. suffix
end
return NumberFormatter
]========]
sources["StarterPlayer/StarterPlayerScripts/ClientBootstrap.client"]=[========[require(script.Parent.Controllers.BloomUI):Start()
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/GardenPresentationController"]=[========[local RS=game:GetService("ReplicatedStorage") local G=require(RS.Config.GardenSynergyConfig) local S={Key=""}
function S:Init(ui) self.UI=ui self.Folder=Instance.new("Folder") self.Folder.Name="LocalSynergyLines" self.Folder.Parent=workspace end
function S:Update()
 local state=self.UI.State if not state then return end local keys={} for id in pairs(state.Synergies) do table.insert(keys,id) end table.sort(keys) local key=table.concat(keys,",")..":"..state.Profile.Garden.Revision if key==self.Key then return end self.Key=key self.Folder:ClearAllChildren()
 local origin=state.HivePosition-Vector3.new(0,1,19)
 for _,r in pairs(state.Synergies) do for i=2,#r.Slots do local previous=r.Slots[i-1] local current=r.Slots[i] local a=Instance.new("Part") a.Anchored=true a.CanCollide=false a.CanTouch=false a.Transparency=1 a.Size=Vector3.new(.1,.1,.1) a.Position=origin+G.Position(previous)+Vector3.new(0,2,0) a.Parent=self.Folder local b=a:Clone() b.Position=origin+G.Position(current)+Vector3.new(0,2,0) b.Parent=self.Folder local aa=Instance.new("Attachment") aa.Parent=a local ab=Instance.new("Attachment") ab.Parent=b local beam=Instance.new("Beam") beam.Attachment0=aa beam.Attachment1=ab beam.Width0=.08 beam.Width1=.08 beam.FaceCamera=true beam.Color=ColorSequence.new(Color3.fromRGB(115,235,165)) beam.Parent=a end end
end return S
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/BloomUI"]=[========[local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
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

local C=Theme.Colors
local UI={Player=Players.LocalPlayer,Pending=false,Auto=false,NextRoll=0,Menu=nil,State=nil,Connections={},RouletteRunning=false,RouletteLanding=false,RouletteGeneration=0}

local MENU_NAMES={
 SeedSatchel="Сумка семян",
 Workshop="Мастерская",
 FieldGuide="Справочник",
 Map="Карта",
 Trials="Испытания",
 Settings="Настройки",
 Plant="Посадка",
 Season="Смена сезона",
 Replay="Подсказки",
 Cards="Карты сезона",
}
local MENU_HINTS={
 SeedSatchel="Цветы, пчёлы, мастерство и экипировка",
 Workshop="Постоянные улучшения и ветви прогрессии",
 FieldGuide="Коллекция, шансы и открытые синергии",
 Map="Сектора, открытия и переходы",
 Trials="Короткие испытания билда",
 Settings="Эффекты, звук и автоматизация",
 Plant="Выберите семя для свободной клумбы",
 Season="Проверьте изменения перед подтверждением",
 Replay="Повтор обучения без сброса прогресса",
 Cards="Выберите эффект нового сезона",
}
local SETTINGS_NAMES={
 ReducedEffects="Уменьшенные эффекты",
 ShowOtherPollinators="Показывать чужих пчёл",
 HideOtherPlayersTokens="Скрывать чужие активности",
 RareFeed="Показывать редкие находки",
 AutoDissolve="Авторастворение дубликатов",
}
local JOURNEY={
 "Получи первую пчелу","Собери Pollen Spark","Доставка мёда","Сделай roll","Посади цветок","Заполни Bloom Meter","Сделай Bloom Roll","Улей уровня 2","Посети мастерскую","Купи узел Workshop","Создай синергию","Открой второй слот пчелы","Активируй Bee Trait","Посети Sunny Orchard","Пройди Solar Bloom","Открой 6 цветов","Открой Crystal Gate","Пройди испытание","Посети Crystal Greenhouse","Подготовь Season Turn",
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
 local label=self:Text(parent,text,UDim2.new(1,0,0,height or 32),{
  BackgroundTransparency=.38,
  BackgroundColor3=C.PanelSoft,
  TextColor3=C.Muted,
  TextSize=12,
  TextWrapped=true,
 })
 corner(label,Theme.Radius.Medium)
 outline(label,C.BorderSoft,1,.5)
 pad(label,10,10,4,4)
 return label
end

function UI:Section(parent,text)
 local label=self:Text(parent,text,UDim2.new(1,0,0,20),{
  TextColor3=C.Blue,
  TextSize=11,
  Font=Enum.Font.GothamBold,
 })
 label.Text=string.upper(text)
 pad(label,2,2,0,0)
 return label
end

function UI:Button(parent,text,fn,icon)
 local base=C.PanelRaised
 local b=make("TextButton",parent,{
  Size=UDim2.new(1,0,0,38),
  BackgroundColor3=base,
  BorderSizePixel=0,
  Text=text,
  TextColor3=C.Text,
  TextSize=12,
  TextWrapped=true,
  TextXAlignment=icon and icon~="" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,
  Font=Enum.Font.GothamMedium,
  ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1,
 })
 corner(b,Theme.Radius.Medium)
 outline(b,C.BorderDark,Theme.Stroke.Control,.08)
 if icon and icon~="" then
  make("ImageLabel",b,{Name="Icon",Size=UDim2.fromOffset(24,24),Position=UDim2.fromOffset(8,7),BackgroundTransparency=1,Image=icon,ScaleType=Enum.ScaleType.Fit,ZIndex=b.ZIndex+1})
  pad(b,40,10,0,0)
 else
  pad(b,10,10,0,0)
 end
 hover(b,base,C.PanelHover)
 b.Activated:Connect(fn)
 return b
end

function UI:Send(action,a,b,c)
 self.Request:FireServer(action,a,b,c)
end

function UI:Toast(text)
 self.ToastLabel.Text=tostring(text or "")
 self.ToastRoot.Visible=true
 self.ToastUntil=os.clock()+4
 if self.ToastScale then
  self.ToastScale.Scale=.94
  TweenService:Create(self.ToastScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
end

function UI:ClearPanel()
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
 self.ReplayIndex=nil
 if self.Menu=="Season" then self:Send("SeasonCancel") end
 self.Menu=nil
 self:SetPanelVisible(false)
 self:Send("Menu",false)
end

function UI:Open(name,arg)
 if self.Menu==name and arg==nil then self:Close() return end
 if not self.State then return end
 if name~="Settings" and name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" and not self.State.Profile.Tutorial.FeatureUnlocks[name] then return end
 self.Menu=name
 self.MenuArg=arg
 self:SetPanelVisible(true)
 if name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" then self:Send("Menu",name) end
 self:RenderMenu()
end

function UI:RenderMenu()
 if not self.Menu or not self.State then return end
 local p=self.State.Profile
 local name=self.Menu
 self:ClearPanel()
 self.PanelTitle.Text=MENU_NAMES[name] or name
 self.PanelSubtitle.Text=MENU_HINTS[name] or ""
 self.Content.CanvasPosition=Vector2.new()

 if name=="Plant" then
  local slot=self.MenuArg
  self:Section(self.Content,"Клумба "..slot)
  self:Label(self.Content,"Выберите свободное семя. Уже посаженные копии автоматически вычитаются из доступного количества.",50)
  if p.WorkshopV5.Nodes.GARDEN_3 and self.LastSeed then
   self:Button(self.Content,"Повторить посадку • "..self.LastSeed,function() self:Send("Plant",slot,self.LastSeed) self:Close() end,Icons.GetRewardIcon("FlowerSeed",self.LastSeed))
  end
  local available={}
  for id,f in pairs(F.Species) do
   local owned=p.FlowerCollection.OwnedSeedCopies[id] or 0
   local planted=0
   for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then planted=planted+1 end end
   local count=math.max(0,owned-planted)
   if count>0 then table.insert(available,{Id=id,Flower=f,Count=count,Owned=owned}) end
  end
  table.sort(available,function(a,b)
   local ar=R.Rank[a.Flower.Rarity] or 1 local br=R.Rank[b.Flower.Rarity] or 1
   if ar==br then return a.Flower.DisplayName<b.Flower.DisplayName end
   return ar<br
  end)
  if #available==0 then
   self:Label(self.Content,"Нет свободных семян. Получи семя из рулетки или выкопай уже посаженный цветок — после награды инвентарь обновляется автоматически.",68)
  else
   for _,entry in ipairs(available) do
    local id=entry.Id local f=entry.Flower local count=entry.Count
    self:Button(self.Content,f.DisplayName.."  •  свободно "..count.." / всего "..entry.Owned,function() self.LastSeed=id self:Send("Plant",slot,id) self:Close() end,Icons.GetRewardIcon("FlowerSeed",id))
   end
  end
  self:Button(self.Content,"Выкопать цветок • семя сохранится",function() self:Send("Plant",slot,"") self:Close() end,Icons.Get("System","Minus"))

 elseif name=="SeedSatchel" then
  self:Section(self.Content,"Семена и цветы")
  self:Label(self.Content,"Слева все семена квадратами, справа выбранный цветок и быстрые действия. Посадка выполняется через клумбу.",54)
  local items={}
  for id,count in pairs(p.FlowerCollection.OwnedSeedCopies) do
   local f=F.Species[id]
   if f and count>0 then
    local planted=0
    for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then planted=planted+1 end end
    local mastery=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
    table.insert(items,{Id=id,Flower=f,Count=count,Planted=planted,Free=math.max(0,count-planted),Mastery=mastery})
   end
  end
  table.sort(items,function(a,b)
   local ar=R.Rank[a.Flower.Rarity] or 1 local br=R.Rank[b.Flower.Rarity] or 1
   if ar==br then return a.Flower.DisplayName<b.Flower.DisplayName end
   return ar<br
  end)
  if #items==0 then
   self:Label(self.Content,"Нет семян. Сделай roll и получи семя, после чего инвентарь заполнится автоматически.",58)
  else
   local selected=self.SelectedSatchelItem
   local active=items[1]
   for _,entry in ipairs(items) do if entry.Id==selected then active=entry break end end
   self.SelectedSatchelItem=active.Id

   local split=make("Frame",self.Content,{Size=UDim2.new(1,0,0,324),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=self.Content.ZIndex+1})
   local left=make("ScrollingFrame",split,{Name="InventoryGrid",Size=UDim2.new(0,244,1,0),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Panel,BackgroundTransparency=.12,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ZIndex=split.ZIndex+1})
   corner(left,Theme.Radius.Large)
   outline(left,C.BorderSoft,1,.4)
   pad(left,12,12,12,12)
   local grid=make("UIGridLayout",left,{CellSize=UDim2.fromOffset(68,68),CellPadding=UDim2.fromOffset(8,8),SortOrder=Enum.SortOrder.LayoutOrder})

   local right=make("Frame",split,{Name="SelectedDetails",Size=UDim2.new(1,-256,1,0),Position=UDim2.fromOffset(256,0),BackgroundColor3=C.Panel,BackgroundTransparency=.08,BorderSizePixel=0,ZIndex=split.ZIndex+1})
   corner(right,Theme.Radius.Large)
   outline(right,C.BorderDark,Theme.Stroke.Panel,.08)
   local info=make("Frame",right,{Name="Info",Size=UDim2.new(1,-20,0,110),Position=UDim2.fromOffset(10,10),BackgroundColor3=C.PanelSoft,BackgroundTransparency=.18,BorderSizePixel=0,ZIndex=right.ZIndex+1})
   corner(info,Theme.Radius.Medium)
   outline(info,C.BorderSoft,1,.45)

   local iconWrap=make("Frame",info,{Size=UDim2.fromOffset(74,74),Position=UDim2.fromOffset(10,10),BackgroundColor3=C.PanelRaised,BorderSizePixel=0,ZIndex=info.ZIndex+1})
   corner(iconWrap,Theme.Radius.Large)
   outline(iconWrap,C.BorderDark,Theme.Stroke.Control,.12)
   local infoIcon=make("ImageLabel",iconWrap,{Name="Icon",Size=UDim2.fromOffset(50,50),Position=UDim2.fromOffset(12,12),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image=Icons.GetRewardIcon("FlowerSeed",active.Id),ZIndex=iconWrap.ZIndex+1})
   local title=self:Text(info,active.Flower.DisplayName,UDim2.new(1,-98,0,24),{Position=UDim2.fromOffset(94,10),TextSize=18,Font=Enum.Font.GothamBold,ZIndex=info.ZIndex+1})
   local rarity=self:Text(info,active.Flower.Rarity.."   •   copies "..active.Count,UDim2.new(1,-98,0,16),{Position=UDim2.fromOffset(94,34),TextSize=11,TextColor3=C.Gold,ZIndex=info.ZIndex+1})
   local meta=self:Text(info,"Mastery "..active.Mastery.Level.."   •   XP "..active.Mastery.XP.."/"..(active.Mastery.Level*25).."   •   свободно "..active.Free.." / всего "..active.Count,UDim2.new(1,-98,0,28),{Position=UDim2.fromOffset(94,54),TextSize=11,TextColor3=C.Muted,TextWrapped=true,ZIndex=info.ZIndex+1})
   local hint=self:Text(info,"Защищай любимые цветы и растворяй только свободные дубликаты.",UDim2.new(1,-20,0,16),{Position=UDim2.fromOffset(10,88),TextSize=10,TextColor3=C.Muted,ZIndex=info.ZIndex+1})

   local actions=make("ScrollingFrame",right,{Name="Actions",Size=UDim2.new(1,-20,1,-132),Position=UDim2.fromOffset(10,122),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ZIndex=right.ZIndex+1})
   local actionsLayout=make("UIListLayout",actions,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})

   local function addAction(text,fn,icon)
    local btn=self:Button(actions,text,fn,icon)
    btn.Size=UDim2.new(1,0,0,34)
    btn.TextSize=12
    return btn
   end

   addAction((p.FlowerCollection.LockedFlowers[active.Id] and "Снять защиту" or "Защитить").." • "..active.Flower.DisplayName,function() self:Send("Flag",active.Id,"LockedFlowers") end,Icons.GetRewardIcon("FlowerSeed",active.Id))
   addAction(p.FlowerCollection.FavoriteFlowers[active.Id] and "Убрать из избранного" or "Добавить в избранное",function() self:Send("Flag",active.Id,"FavoriteFlowers") end,Icons.Get("System","Confirm"))
   addAction("Растворить 1 свободный дубликат",function() self:Send("Dissolve",active.Id,1) end,Icons.Get("WorkshopHex","Duplicate"))
   addAction("Mastery +XP  •  "..(active.Mastery.Level*5).." Petal Dust",function() self:Send("FlowerUpgrade",active.Id) end,Icons.GetCurrencyIcon("PetalDust"))
   addAction("Flower Memory",function() self:Send("Keepsake","Flower",active.Id) end,Icons.Get("System","Flower"))
   if p.WorkshopV5.Nodes.LEGACY_5 then addAction("Third Memory Slot",function() self:Send("Keepsake","Flower2",active.Id) end,Icons.Get("System","Flower")) end

   for index,entry in ipairs(items) do
    local tile=make("ImageButton",left,{Name="Tile_"..entry.Id,BackgroundColor3=entry.Id==active.Id and C.BlueDeep or C.PanelRaised,BorderSizePixel=0,AutoButtonColor=false,Image="",LayoutOrder=index,ZIndex=left.ZIndex+1})
    corner(tile,Theme.Radius.Medium)
    outline(tile,entry.Id==active.Id and C.Gold or C.BorderDark,entry.Id==active.Id and 2 or 1,entry.Id==active.Id and .05 or .2)
    local img=make("ImageLabel",tile,{Name="Icon",Size=UDim2.fromOffset(38,38),Position=UDim2.fromOffset(15,4),BackgroundTransparency=1,Image=Icons.GetRewardIcon("FlowerSeed",entry.Id),ScaleType=Enum.ScaleType.Fit,ZIndex=tile.ZIndex+1})
    make("TextLabel",tile,{Name="Count",Size=UDim2.fromOffset(24,16),Position=UDim2.fromOffset(42,2),BackgroundColor3=C.Blue,BorderSizePixel=0,Text="x"..entry.Count,TextColor3=C.Text,TextSize=10,Font=Enum.Font.GothamBold,ZIndex=tile.ZIndex+2})
    make("TextLabel",tile,{Name="Name",Size=UDim2.new(1,-8,0,16),Position=UDim2.fromOffset(4,48),BackgroundTransparency=1,Text=entry.Flower.DisplayName,TextColor3=C.Text,TextSize=9,Font=Enum.Font.GothamMedium,TextWrapped=true,ZIndex=tile.ZIndex+1})
    local lock=make("TextLabel",tile,{Name="Flags",Size=UDim2.fromOffset(18,18),Position=UDim2.fromOffset(4,4),BackgroundTransparency=1,Text=(p.FlowerCollection.LockedFlowers[entry.Id] and "🔒" or (p.FlowerCollection.FavoriteFlowers[entry.Id] and "★" or "")),TextColor3=C.Gold,TextSize=12,Font=Enum.Font.GothamBold,ZIndex=tile.ZIndex+2})
    tile.MouseEnter:Connect(function() if entry.Id~=self.SelectedSatchelItem then TweenService:Create(tile,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play() end end)
    tile.MouseLeave:Connect(function() if entry.Id~=self.SelectedSatchelItem then TweenService:Create(tile,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelRaised}):Play() end end)
    tile.Activated:Connect(function() self.SelectedSatchelItem=entry.Id self:RenderMenu() end)
   end

   self:Section(self.Content,"Пчёлы • слотов "..self.State.BeeCapacity)
   for id,count in pairs(p.Pollinators.BeeInventory) do
    local bee=B.Get(id)
    if bee then
     self:Label(self.Content,bee.DisplayName.."  ×"..count.."   •   "..table.concat(bee.Traits,", "),42)
    end
   end
  end

 elseif name=="Workshop" then
  self:Section(self.Content,"Workshop Tree")
  self:Label(self.Content,"Points "..p.WorkshopV5.Points.."   •   Coins "..compact(p.Currencies.Coins).."   •   Petal Dust "..compact(p.Currencies.PetalDust),44)
  self:Button(self.Content,"Alpha respec • вернуть стоимость обычных узлов",function() self:Send("Respec") end,Icons.Get("System","Warning"))
  local canvas=make("ScrollingFrame",self.Content,{Size=UDim2.new(1,0,0,360),CanvasSize=UDim2.fromOffset(1440,1300),BackgroundColor3=C.Background,BackgroundTransparency=.12,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ScrollingDirection=Enum.ScrollingDirection.XY})
  corner(canvas,Theme.Radius.Large)
  outline(canvas,C.BorderDark,Theme.Stroke.Panel,.08)
  local center=Vector2.new(720,650)
  for id,n in pairs(W.Nodes) do
   local pos=id=="CORE" and center or center+Vector2.new(math.cos(n.Angle),math.sin(n.Angle))*n.Radius
   if n.Parent then
    local prev=W.Nodes[n.Parent]
    local from=n.Parent=="CORE" and center or center+Vector2.new(math.cos(prev.Angle),math.sin(prev.Angle))*prev.Radius
    local d=pos-from
    make("Frame",canvas,{Size=UDim2.fromOffset(d.Magnitude,3),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((pos.X+from.X)/2,(pos.Y+from.Y)/2),Rotation=math.deg(math.atan2(d.Y,d.X)),BackgroundColor3=p.WorkshopV5.Nodes[n.Parent] and C.GreenDeep or C.BorderSoft,BorderSizePixel=0,ZIndex=1})
   end
   local b=make("TextButton",canvas,{Size=UDim2.fromOffset(94,84),Position=UDim2.fromOffset(pos.X-47,pos.Y-42),BackgroundTransparency=1,Text="",ZIndex=2})
   local selected=self.SelectedNode==id
   local owned=p.WorkshopV5.Nodes[id]
   local icon=make("ImageLabel",b,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=Icons.GetWorkshopHexIcon(owned and "Core" or "Locked"),ImageColor3=owned and C.Green or C.White,ScaleType=Enum.ScaleType.Fit,ZIndex=2})
   if selected then icon.ImageColor3=C.Gold end
   make("TextLabel",b,{Size=UDim2.new(1,-12,1,-16),Position=UDim2.fromOffset(6,8),BackgroundTransparency=1,Text=n.Name,TextColor3=C.Text,TextStrokeColor3=C.Black,TextStrokeTransparency=.55,TextSize=11,Font=Enum.Font.GothamBold,TextWrapped=true,ZIndex=3})
   b.Activated:Connect(function() if id~="CORE" then self.SelectedNode=id self:RenderMenu() end end)
  end
  canvas.CanvasPosition=Vector2.new(480,410)
  local n=W.Nodes[self.SelectedNode]
  if n then
   local rules=require(RS.Config.WorkshopEffectsConfig)[n.Id] or {}
   local descriptions={}
   for key,value in pairs(rules) do table.insert(descriptions,key..": "..tostring(value)) end
   self:Section(self.Content,"Выбранный узел")
   self:Label(self.Content,n.Name.."   •   Hive "..n.Hive.."   •   "..n.Cost.." point   •   "..n.Coins.." coins   •   "..n.Dust.." dust   •   "..n.Nectar.." nectar",56)
   if #descriptions>0 then self:Label(self.Content,table.concat(descriptions,"  •  "),52) end
   self:Button(self.Content,p.WorkshopV5.Nodes[n.Id] and "Куплено" or "Купить узел",function() self:Send("WorkshopBuy",n.Id) end,Icons.Get("System",p.WorkshopV5.Nodes[n.Id] and "Confirm" or "Upgrade"))
  end

 elseif name=="FieldGuide" then
  self:Section(self.Content,"Коллекция и реальные шансы")
  self:Label(self.Content,"Шансы учитывают текущие модификаторы и гарантию нового открытия.",48)
  for _,item in ipairs(self.State.Odds) do
   self:Label(self.Content,item.DisplayName.."   •   "..item.Rarity..string.format("   •   %.6f%%",item.Chance*100)..(item.Undiscovered and "   •   НЕ ОТКРЫТ" or "   •   открыт"),46)
  end
  self:Section(self.Content,"Синергии")
  self:Label(self.Content,"Пары: Daisy + Tulip; Sunflower + Clover.",44)
  if p.WorkshopV5.Nodes.GARDEN_5 then self:Label(self.Content,"Crystal triangle: 1, 2, 6; Meadow line: 1, 2, 3; opposite: 1, 15.",62) end
  for id in pairs(p.GardenSynergies.Discovered) do self:Label(self.Content,id.."   •   mastery "..(p.GardenSynergies.Mastery[id] or 0),42) end

 elseif name=="Map" then
  self:Section(self.Content,"Мир Bloom RNG")
  if p.WorkshopV5.Nodes.EXPLORATION_1 and self.State.Pulse then self:Label(self.Content,"Biome Pulse  •  "..self.State.Pulse.Sector,44) end
  for _,id in ipairs(L.Order) do self:Label(self.Content,L.Sectors[id].Name.."   •   "..(p.World.UnlockedSectors[id] and "ОТКРЫТО" or "требуется Hive "..L.Sectors[id].Hive),44) end
  self:Section(self.Content,"Landmarks")
  local any=false
  for id in pairs(p.World.LandmarkDiscoveries) do any=true self:Label(self.Content,"✓  "..id,40) end
  if not any then self:Label(self.Content,"Пока ничего не найдено.",40) end
  self:Button(self.Content,"Открыть Build Trials",function() self:Open("Trials") end,Icons.Get("System","Quests"))

 elseif name=="Trials" then
  self:Section(self.Content,"Build Trials")
  for id,t in pairs(Trials) do
   self:Button(self.Content,(p.Quests.Trials[id] and "✓  " or "")..t.Name.."   •   "..t.Sector,function() self:Send("Trial",id) end,Icons.Get("System","Quests"))
  end

 elseif name=="Settings" then
  self:Section(self.Content,"Интерфейс и эффекты")
  for _,id in ipairs({"ReducedEffects","ShowOtherPollinators","HideOtherPlayersTokens","RareFeed","AutoDissolve"}) do
   local on=p.Settings[id]==true
   self:Button(self.Content,(SETTINGS_NAMES[id] or id).."   •   "..(on and "ВКЛ" or "ВЫКЛ"),function() self:Send("Setting",id,not on) end,Icons.Get("System",on and "Confirm" or "Minus"))
  end
  self:Button(self.Content,"Громкость активностей   •   "..math.floor((p.Settings.TokenSoundVolume or 0)*100).."%",function() self:Send("Setting","TokenSoundVolume",(p.Settings.TokenSoundVolume+.25)%1.25) end,Icons.Get("System","Info"))
  if p.WorkshopV5.Nodes.ECONOMY_2 then
   self:Section(self.Content,"Фильтр авторастворения")
   for _,rarity in ipairs(R.Order) do
    local on=p.Settings.DissolveRarities[rarity]==true
    self:Button(self.Content,"Dissolve "..rarity.."   •   "..(on and "ВКЛ" or "ВЫКЛ"),function() self:Send("DissolveFilter",rarity) end,Icons.Get("WorkshopHex","Duplicate"))
   end
  end
  self:Section(self.Content,"Обучение")
  self:Button(self.Content,"Пропустить обучение",function() self:Send("Skip") end,Icons.Get("System","Warning"))
  self:Button(self.Content,"Повторить подсказки",function() self:Send("Replay") end,Icons.Get("System","Tutorial"))

 elseif name=="Season" then
  local preview=self.MenuArg
  self:Section(self.Content,"Что сохранится")
  self:Label(self.Content,table.concat(preview.Keep,", "),78)
  self:Section(self.Content,"Изменения")
  for _,diff in ipairs(preview.Diff) do self:Label(self.Content,diff.Path..":  "..tostring(diff.Before).."  →  "..tostring(diff.After),46) end
  self:Button(self.Content,self.SeasonSecond and "ПОДТВЕРДИТЬ СБРОС СЕЗОНА" or "Продолжить",function() self:Send("SeasonConfirm",preview.Token) end,Icons.Get("System",self.SeasonSecond and "Warning" or "Confirm"))

 elseif name=="Replay" then
  local i=self.ReplayIndex or 1
  self.ReplayIndex=i
  self:Section(self.Content,"Шаг "..i.." из "..#T.Steps)
  self:Label(self.Content,T.Steps[i].Text,78)
  self:Button(self.Content,"Следующий шаг",function() self.ReplayIndex=i%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowRight"))
  self:Button(self.Content,"Предыдущий шаг",function() self.ReplayIndex=(i-2)%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowLeft"))

 elseif name=="Cards" then
  self:Section(self.Content,"Выбор карты")
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
 self.ObjectiveCard.Size=UDim2.fromOffset(math.max(280,width-24),82)
 self.CurrencyHUD.Position=UDim2.fromOffset(10,96)
 self.Dock.AnchorPoint=Vector2.new(1,.5)
 self.Dock.Position=UDim2.new(1,-10,.56,0)
 self.Guide.Size=UDim2.fromOffset(math.max(260,width-24),38)
 self.RollHUD.Size=UDim2.fromOffset(math.min(300,width-18),58)
 self.RollHUD.AnchorPoint=Vector2.new(.5,1)
 self.RollHUD.Position=UDim2.new(.5,0,1,-72)
 self.Roll.AnchorPoint=Vector2.new(.5,1)
 self.Roll.Position=UDim2.new(.5,0,1,-10)
 self.RouletteViewport.AnchorPoint=Vector2.new(.5,0)
 self.RouletteViewport.Position=UDim2.new(.5,0,0,108)
 self.ToastRoot.Size=UDim2.fromOffset(math.max(260,width-24),44)
 self.Panel.Size=UDim2.fromOffset(math.max(300,width-16),math.max(300,height-120))
 self.Panel.Position=UDim2.new(.5,0,.52,0)
 self.Reveal.Size=UDim2.fromOffset(math.max(280,width-24),124)
end

function UI:Render()
 local p=self.State.Profile
 local step=T.Steps[p.Tutorial.Step]
 if step then
  self.ObjectiveTitle.Text="ОБУЧЕНИЕ  •  "..p.Tutorial.Step.."/"..#T.Steps
  self.ObjectiveText.Text=step.Text
  self.ObjectiveProgressFill.Size=UDim2.fromScale(math.clamp((p.Tutorial.Step-1)/#T.Steps,0,1),1)
  self.ObjectiveProgress.Visible=true
 else
  self.ObjectiveTitle.Text="JOURNEY  •  ШАГ "..tostring(p.Quests.JourneyStep or 1)
  self.ObjectiveText.Text=JOURNEY[p.Quests.JourneyStep] or "Продолжай развивать сад"
  self.ObjectiveProgress.Visible=false
 end

 self.CurrencyRows.Coins.Value.Text=compact(p.Currencies.Coins)
 self.CurrencyRows.Honey.Value.Text=compact(p.Hive.Honey)
 self.CurrencyRows.Hive.Value.Text="Уровень "..tostring(p.Hive.Level)
 self.CurrencyRows.PetalDust.Value.Text=compact(p.Currencies.PetalDust)
 self.CurrencyRows.PetalDust.Root.Visible=p.Tutorial.FeatureUnlocks.SeedSatchel==true
 self.CurrencyRows.AncientNectar.Value.Text=compact(p.Currencies.AncientNectar)
 self.CurrencyRows.AncientNectar.Root.Visible=(p.Season.Count or 0)>0 or (p.Currencies.AncientNectar or 0)>0

 local rollUnlocked=p.Tutorial.FeatureUnlocks.Roll==true
 self.RollHUD.Visible=rollUnlocked
 self.Roll.Visible=rollUnlocked
 self.RouletteViewport.Visible=rollUnlocked
 if not rollUnlocked and self.Auto then
  self.Auto=false
  self:StopRouletteAnimation()
 end

 local special=p.RollState.SpecialRollReady==true
 if self.Auto then
  self.Roll.Text="STOP ROLL"
  self.Roll.BackgroundColor3=C.GreenDeep
  self.RollStroke.Color=C.Green
  self.RollIcon.Image=Icons.GetActionIcon("AutoRoll")
 else
  self.Roll.Text=special and "BLOOM ROLL" or "AUTO ROLL"
  self.Roll.BackgroundColor3=special and C.GreenDeep or C.BlueDeep
  self.RollStroke.Color=special and C.Gold or C.Blue
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
 self.GuideController:Update()
 self.GardenPresentation:Update()
end

function UI:RollNow(automatic)
 if self.Pending or self.RouletteLanding or (self.Rewards and self.Rewards.Busy) or os.clock()<self.NextRoll or not self.State then return end
 self.Pending=true
 self.PendingAt=os.clock()
 self:Send("Roll",automatic==true)
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
 self.RouletteRunning=true self.RouletteGeneration=self.RouletteGeneration+1
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
 self.RouletteRunning=false self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 if self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
 self:RefreshRouletteSlots()
end

function UI:SetAutoRolling(enabled)
 if enabled and (not self.State or self.State.Profile.Tutorial.FeatureUnlocks.Roll~=true) then return end
 self.Auto=enabled==true
 if self.Auto then
  if not self.RouletteLanding then self:StartRouletteAnimation() end
  task.defer(function() self:RollNow(true) end)
 else
  if not self.RouletteLanding then self:StopRouletteAnimation() else self.RouletteRunning=false end
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
 self.RouletteLanding=true self.RouletteRunning=false self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 local generation=self.RouletteGeneration
 task.spawn(function()
  local visualStart=os.clock()
  local target=self:FindRouletteTarget(payload)
  local steps=RollAudio.SettleSteps
  for i,duration in ipairs(steps) do
   if generation~=self.RouletteGeneration then break end
   local final=i==#steps
   if not self:StepRoulette(duration,final and target or nil,nil) then break end
  end
  if generation==self.RouletteGeneration then
   local remaining=math.max(0,(RollAudio.MinimumVisualSpin or 0)-(os.clock()-visualStart))
   if remaining>0 then task.wait(remaining) end
   self:PlayRouletteRewardSound()
   self:AnimateRouletteResult()
   task.wait(RollAudio.ResultHold)
  end
  self.RouletteLanding=false
  if self.Rewards then self.Rewards:Enqueue(payload) end
  if self.Auto then self:StartRouletteAnimation() end
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
 self.RouletteStrip=self.RouletteViewport:WaitForChild("ReelStrip")
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
 self.PanelTitle=header:WaitForChild("PanelTitle")
 self.PanelSubtitle=header:WaitForChild("PanelSubtitle")
 local close=header:WaitForChild("Close")
 close.Activated:Connect(function() self:Close() end)
 close.MouseEnter:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Danger}):Play() end)
 close.MouseLeave:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelRaised}):Play() end)
 self.Content=self.Panel:WaitForChild("Content")
 self.ContentLayout=self.Content:FindFirstChildOfClass("UIListLayout")

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
end

function UI:ResolveBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")
 local existing=playerGui:FindFirstChild("BloomUI")

 -- In Studio, Rojo can update StarterGui after the player has already spawned.
 -- Roblox does not guarantee that a newly synced ScreenGui is cloned into the
 -- current PlayerGui, so prefer a fresh clone of the authored StarterGui tree.
 if RunService:IsStudio() then
  local template=StarterGui:FindFirstChild("BloomUI") or StarterGui:WaitForChild("BloomUI",8)
  if template and template:IsA("ScreenGui") then
   if existing then existing:Destroy() end
   local clone=template:Clone()
   clone.Name="BloomUI"
   clone.Parent=playerGui
   return clone
  end

  -- If live sync has not mounted StarterGui yet but an engine clone already
  -- exists, keep the usable clone instead of failing the whole client UI.
  if existing and existing:IsA("ScreenGui") then return existing end
 end

 -- Published/runtime path: normally Roblox clones StarterGui automatically.
 existing=existing or playerGui:WaitForChild("BloomUI",10)
 if existing and existing:IsA("ScreenGui") then return existing end

 -- Defensive fallback for unusual replication/startup timing.
 local template=StarterGui:FindFirstChild("BloomUI") or StarterGui:WaitForChild("BloomUI",5)
 if template and template:IsA("ScreenGui") then
  local clone=template:Clone()
  clone.Name="BloomUI"
  clone.Parent=playerGui
  return clone
 end

 error("[BloomUI] BloomUI is missing from both PlayerGui and StarterGui")
end

function UI:Start()
 self.Player:SetAttribute("BloomClientReady",false)
 local remotes=RS:WaitForChild("BloomRemotes")
 self.Request=remotes:WaitForChild("Request")
 local event=remotes:WaitForChild("Event")
 self.Gui=self:ResolveBloomGui()
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
   self.State=payload
   self.Player:SetAttribute("BloomClientReady",true)
   if not self.RouletteLanding then self:BuildRouletteVisualPool(true) end
   self:Render()
  elseif kind=="Ack" then
   if payload.Action=="Roll" then
    self.Pending=false
    self.NextRoll=math.max(self.NextRoll,os.clock()+.2)
    if self.State then self:Render() end
   end
   if not payload.OK then
    if payload.Action=="Roll" and self.Auto then self:SetAutoRolling(false) end
    if not (payload.Action=="Ready" and payload.Reason=="PROFILE_LOADING") then
     self:Toast(payload.Reason or "Действие пока недоступно")
    end
   end
   if self.Menu and payload.Action~="Menu" and payload.Action~="Roll" and payload.Action~="Ready" then task.defer(function() self:RenderMenu() end) end
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
  while self.Gui.Parent and not self.State do
   self:Send("Ready")
   local status=self.Player:GetAttribute("BloomProfileState")
   if status~=lastStatus then
    lastStatus=status
    if status then print("[BloomUI] Profile state:",status) end
   end
   if os.clock()-started>20 then
    local reason=self.Player:GetAttribute("BloomProfileError")
    warn("[BloomUI] Still waiting for profile state",status,reason)
    self:Toast(reason and ("Профиль: "..tostring(reason)) or "Профиль всё ещё загружается…")
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
    self:Toast("Ответ сервера задержался. Auto выключен.")
    if self.State then self:Render() end
   end
   if self.State then self.GuideController:Update() end
   if self.ToastUntil and os.clock()>self.ToastUntil then self.ToastRoot.Visible=false self.ToastUntil=nil end
  end
 end)
end

return UI
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController"]=[========[local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local T=require(RS.Config.TutorialConfig)
local L=require(RS.Config.LocationsConfig)
local Theme=require(RS.Config.UIThemeConfig)

local C=Theme.Colors
local S={}

local function corner(x,r)
 local c=Instance.new("UICorner")
 c.CornerRadius=UDim.new(0,r)
 c.Parent=x
 return c
end

local function outline(x,color,thickness,transparency)
 local s=Instance.new("UIStroke")
 s.Color=color
 s.Thickness=thickness
 s.Transparency=transparency or 0
 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
 s.Parent=x
 return s
end

function S:Init(ui)
 self.UI=ui

 local a=Instance.new("Part")
 a.Name="LocalGuideTarget"
 a.Transparency=1
 a.Anchored=true
 a.CanCollide=false
 a.CanTouch=false
 a.CanQuery=false
 a.Size=Vector3.new(.25,.25,.25)
 a.Parent=workspace
 self.Target=a

 local bill=Instance.new("BillboardGui")
 bill.Name="BloomTutorialWorldArrow"
 bill.Size=UDim2.fromOffset(190,72)
 bill.StudsOffset=Vector3.new(0,1.5,0)
 bill.AlwaysOnTop=true
 bill.MaxDistance=220
 bill.Enabled=false
 bill.Parent=a
 self.Billboard=bill

 local billText=Instance.new("TextLabel")
 billText.Size=UDim2.fromScale(1,1)
 billText.BackgroundTransparency=1
 billText.Text="ЦЕЛЬ\n▼"
 billText.TextSize=19
 billText.TextColor3=C.Gold
 billText.TextStrokeColor3=C.Black
 billText.TextStrokeTransparency=.35
 billText.Font=Enum.Font.GothamBlack
 billText.TextWrapped=true
 billText.Parent=bill
 self.BillboardText=billText

 self.Attachment=Instance.new("Attachment")
 self.Attachment.Parent=a
 self.Beam=Instance.new("Beam")
 self.Beam.Attachment1=self.Attachment
 self.Beam.Width0=.09
 self.Beam.Width1=.14
 self.Beam.FaceCamera=true
 self.Beam.Color=ColorSequence.new({
  ColorSequenceKeypoint.new(0,C.Blue),
  ColorSequenceKeypoint.new(1,C.Gold),
 })
 self.Beam.Transparency=NumberSequence.new({
  NumberSequenceKeypoint.new(0,.12),
  NumberSequenceKeypoint.new(1,.42),
 })
 self.Beam.Enabled=false
 self.Beam.Parent=a

 local frame=Instance.new("Frame")
 frame.Name="TutorialSpotlight"
 frame.AnchorPoint=Vector2.new(.5,.5)
 frame.BackgroundColor3=C.Gold
 frame.BackgroundTransparency=.92
 frame.BorderSizePixel=0
 frame.Visible=false
 frame.ZIndex=90
 frame.Parent=ui.SafeRoot
 corner(frame,Theme.Radius.Large)
 self.Spotlight=frame
 self.SpotlightStroke=outline(frame,C.Gold,4,0)
 self.SpotlightScale=Instance.new("UIScale")
 self.SpotlightScale.Scale=1
 self.SpotlightScale.Parent=frame

 local callout=Instance.new("TextLabel")
 callout.Name="TutorialCallout"
 callout.AnchorPoint=Vector2.new(.5,.5)
 callout.Size=UDim2.fromOffset(190,38)
 callout.BackgroundColor3=C.Panel
 callout.BackgroundTransparency=.02
 callout.BorderSizePixel=0
 callout.Text=""
 callout.TextColor3=C.Text
 callout.TextSize=12
 callout.Font=Enum.Font.GothamBold
 callout.TextWrapped=true
 callout.Visible=false
 callout.ZIndex=92
 callout.Parent=ui.SafeRoot
 corner(callout,Theme.Radius.Medium)
 outline(callout,C.BorderDark,2,0)
 self.Callout=callout

 TweenService:Create(self.SpotlightScale,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Scale=1.06}):Play()
 TweenService:Create(self.SpotlightStroke,TweenInfo.new(.6,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,-1,true),{Transparency=.4,Thickness=2}):Play()
end

function S:HideScreenTarget()
 self.Spotlight.Visible=false
 self.Callout.Visible=false
end

function S:PlaceScreenTarget(button,label)
 local ui=self.UI
 local root=ui.SafeRoot
 if not button or not button.Parent or not button.Visible or not root or root.AbsoluteSize.X<=0 then
  self:HideScreenTarget()
  return false
 end

 local rootPos=root.AbsolutePosition
 local rootSize=root.AbsoluteSize
 local absolute=button.AbsolutePosition
 local targetSize=button.AbsoluteSize
 local localX=absolute.X-rootPos.X
 local localY=absolute.Y-rootPos.Y
 local w=math.clamp(targetSize.X+18,58,math.max(58,rootSize.X-20))
 local h=math.clamp(targetSize.Y+18,54,math.max(54,rootSize.Y-20))
 local cx=math.clamp(localX+targetSize.X*.5,w*.5+8,rootSize.X-w*.5-8)
 local cy=math.clamp(localY+targetSize.Y*.5,h*.5+8,rootSize.Y-h*.5-8)

 self.Spotlight.Size=UDim2.fromOffset(w,h)
 self.Spotlight.Position=UDim2.fromOffset(cx,cy)
 self.Spotlight.Visible=true

 local calloutW=math.min(210,math.max(140,rootSize.X-20))
 self.Callout.Size=UDim2.fromOffset(calloutW,38)
 self.Callout.Text=label
 local above=cy-h*.5-30
 local calloutY
 if above>26 then
  calloutY=above
 else
  calloutY=cy+h*.5+30
 end
 calloutY=math.clamp(calloutY,22,rootSize.Y-22)
 local calloutX=math.clamp(cx,calloutW*.5+8,rootSize.X-calloutW*.5-8)
 self.Callout.Position=UDim2.fromOffset(calloutX,calloutY)
 self.Callout.Visible=true
 return true
end

function S:SetWorldTarget(pos,label)
 if not pos then
  self.Billboard.Enabled=false
  self.Beam.Enabled=false
  return
 end
 self.Target.Position=pos+Vector3.new(0,7,0)
 self.BillboardText.Text=(label or "ЦЕЛЬ").."\n▼"
 self.Billboard.Enabled=true

 local root=self.UI.Player.Character and self.UI.Player.Character:FindFirstChild("HumanoidRootPart")
 if not root then
  self.Beam.Enabled=false
  return
 end
 if not self.RootAttachment or self.RootAttachment.Parent~=root then
  if self.RootAttachment then self.RootAttachment:Destroy() end
  self.RootAttachment=Instance.new("Attachment")
  self.RootAttachment.Parent=root
  self.Beam.Attachment0=self.RootAttachment
 end
 local distance=(root.Position-pos).Magnitude
 self.Beam.Enabled=distance>30
 self.UI.Guide.Text=(label or "Цель").."   •   "..math.floor(distance).." м"
 self.UI.Guide.Visible=true
end

function S:ResolveWorldTarget(target)
 local ui=self.UI
 local world=workspace:FindFirstChild("BloomWorld")
 local hivePos=ui.State and ui.State.HivePosition
 if target=="Hive" then return hivePos,"УЛЕЙ" end
 if target=="Garden" then
  local plot=world and world:FindFirstChild("Garden_"..ui.Player.UserId)
  local ground=plot and plot:FindFirstChild("Ground")
  if ground and ground:IsA("BasePart") then return ground.Position+Vector3.new(0,1,0),"САД" end
  if hivePos then return hivePos-Vector3.new(0,1,19),"САД" end
 elseif target=="Token" then
  local token=ui.Activities:Target()
  if token then return token.Position,"АКТИВНОСТЬ" end
 elseif target=="Workshop" then
  local part=world and world:FindFirstChild("Workshop")
  if part and part:IsA("BasePart") then return part.Position,"МАСТЕРСКАЯ" end
 elseif L.Sectors[target] then
  local part=world and world:FindFirstChild(target.."Gate")
  if part and part:IsA("BasePart") then return part.Position,string.upper(L.Sectors[target].Name) end
 end
 return nil,nil
end

function S:Update()
 local ui=self.UI
 if not ui.State then return end
 local p=ui.State.Profile
 local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]
 local target=step and step.Target

 self.Billboard.Enabled=false
 self.Beam.Enabled=false
 self:HideScreenTarget()
 ui.Guide.Visible=false
 if not target then return end

 if target=="Roll" then
  if self:PlaceScreenTarget(ui.Roll,"НАЖМИ ROLL") then
   -- The persistent guide banner already explains the action. Keeping a second
   -- callout above the bottom HUD caused it to overlap Bloom/Roll on short screens.
   self.Callout.Visible=false
   ui.Guide.Text="Следующий шаг: запусти auto roll"
   ui.Guide.Visible=true
  end
  return
 end

 if target=="SeedSatchel" then
  if ui.DockButtons.SeedSatchel and ui.DockButtons.SeedSatchel.Visible then ui.Dock.Visible=true end
  if self:PlaceScreenTarget(ui.DockButtons.SeedSatchel,"ОТКРОЙ СУМКУ СЕМЯН") then
   ui.Guide.Text="Следующий шаг: открой сумку семян"
   ui.Guide.Visible=true
  end
  return
 end

 local pos,label=self:ResolveWorldTarget(target)
 if target=="Token" and not pos then
  ui.Guide.Text="Ожидай следующую активность — указатель появится автоматически"
  ui.Guide.Visible=true
  return
 end
 if pos then self:SetWorldTarget(pos,label) end
end

return S
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController"]=[========[local RS=game:GetService("ReplicatedStorage") local B=require(RS.Config.BeesConfig) local Tween=game:GetService("TweenService") local S={Models={}}
function S:Init(ui) self.UI=ui local f=Instance.new("Folder") f.Name="LocalBees" f.Parent=workspace self.Folder=f end
function S:Update(frames)
 local keep={} for _,v in ipairs(frames) do if v.Owner==self.UI.Player.UserId or self.UI.State and self.UI.State.Profile.Settings.ShowOtherPollinators then
  local key=v.Owner.."_"..v.Index keep[key]=true local item=self.Models[key]
  if not item then local part=Instance.new("Part") part.Name=v.Id part.Size=Vector3.new(1.4,.8,1) part.Anchored=true part.CanCollide=false part.CanTouch=false part.Color=B.Get(v.Id).Color part.Parent=self.Folder item={Part=part} self.Models[key]=item end
  local phase=v.Phase local pos=phase<.25 and v.From:Lerp(v.To,phase*4) or phase<.7 and v.To or v.To:Lerp(v.From,(phase-.7)/.3)
  if item.Tween then item.Tween:Cancel() end item.Tween=Tween:Create(item.Part,TweenInfo.new(1,Enum.EasingStyle.Linear),{Position=pos+Vector3.new(0,4,0)}) item.Tween:Play()
 end end
 for key,item in pairs(self.Models) do if not keep[key] then if item.Tween then item.Tween:Cancel() end item.Part:Destroy() self.Models[key]=nil end end
end
return S
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/RewardPresentationController"]=[========[local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Cfg=require(RS.Config.RewardPresentationConfig)
local Icons=require(RS.Config.IconsConfig)
local R=require(RS.Config.RarityConfig)
local Theme=require(RS.Config.UIThemeConfig)

local S={Queue={},Busy=false,Generation=0}

function S:Init(ui)
 self.UI=ui
end

function S:ShowCard(r)
 local ui=self.UI
 local rarityColor=R.Colors[r.Rarity] or Theme.Colors.Blue
 ui.Reveal.Visible=true
 ui.Reveal.BackgroundColor3=Theme.Colors.Panel
 ui.RewardStripe.BackgroundColor3=rarityColor
 ui.RewardStroke.Color=Theme.Colors.BorderDark
 ui.RewardTitle.Text=(r.IsSpecialRoll and "BLOOM ROLL  •  " or "")..tostring(r.DisplayName or "Reward")
 ui.RewardTitle.TextColor3=Theme.Colors.Text
 local meta=tostring(r.Rarity or "Common")
 if not r.Ceremony then meta=meta..string.format("   •   %.5f%%",(tonumber(r.Chance) or 0)*100) end
 if r.IsNew then meta=meta.."   •   NEW" end
 ui.RewardMeta.Text=meta
 ui.RewardMeta.TextColor3=rarityColor
 ui.RewardHint.Text=r.Ceremony and "" or "нажмите, чтобы ускорить показ"
 ui.RewardIcon.Image=r.Ceremony and Icons.Get("System",r.Ceremony=="Hive" and "Hive" or "Flower") or Icons.GetRewardIcon(r.Kind,r.Id)
 ui.RewardIcon.Rotation=0
 ui.RevealScale.Scale=.9
 TweenService:Create(ui.RevealScale,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
end

function S:Enqueue(reward)
 table.insert(self.Queue,reward)
 if self.Busy then return end
 self.Busy=true
 task.spawn(function()
  while #self.Queue>0 do
   local r=table.remove(self.Queue,1)
   local tier=Cfg[r.Rarity] or Cfg.Common
   local began=os.clock()
   self.Skip=false
   self:ShowCard(r)

   local reduced=self.UI.State.Profile.Settings.ReducedEffects
   if not r.Ceremony and not reduced then
    local finalImage=Icons.GetRewardIcon(r.Kind,r.Id)
    self.UI.RewardTitle.Text="ROLLING…"
    self.UI.RewardMeta.Text="Определяем награду"
    self.UI.RewardMeta.TextColor3=Theme.Colors.Muted
    self.UI.RewardIcon.Image=Icons.Get("Actions","Roll")
    local spin=TweenService:Create(self.UI.RewardIcon,TweenInfo.new(.28,Enum.EasingStyle.Linear),{Rotation=360})
    spin:Play()
    task.wait(.28)
    spin:Cancel()
    spin:Destroy()
    self.UI.RewardIcon.Rotation=0
    self:ShowCard(r)
    self.UI.RewardIcon.Image=finalImage
   end

   local cam=workspace.CurrentCamera
   local originalFOV=cam and cam.FieldOfView
   local pulse=nil
   local emitter=nil
   if not reduced and (R.Rank[r.Rarity] or 1)>=5 then
    local root=self.UI.Player.Character and self.UI.Player.Character:FindFirstChild("HumanoidRootPart")
    if root then
     emitter=Instance.new("ParticleEmitter")
     emitter.Rate=0
     emitter.Lifetime=NumberRange.new(.4,.9)
     emitter.Speed=NumberRange.new(3,7)
     emitter.Color=ColorSequence.new(R.Colors[r.Rarity] or Theme.Colors.Blue)
     emitter.Parent=root
     emitter:Emit(r.Rarity=="Celestial" and 32 or r.Rarity=="Mythic" and 20 or 10)
    end
    if cam then
     pulse=TweenService:Create(cam,TweenInfo.new(.3,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true),{FieldOfView=originalFOV+4})
     pulse:Play()
    end
   end

   local duration=reduced and math.min(.6,tier.Duration) or tier.Duration*(self.UI.State.Profile.WorkshopV5.Nodes.ROLL_3 and .75 or 1)
   repeat task.wait(.03) until os.clock()-began>=duration or (self.Skip and os.clock()-began>=tier.Min)
   if pulse then pulse:Cancel() pulse:Destroy() end
   if cam and originalFOV then cam.FieldOfView=originalFOV end
   if emitter then emitter:Destroy() end
   self.UI.Reveal.Visible=false
  end
  self.Busy=false
 end)
end

function S:SkipCurrent()
 self.Skip=true
end

return S
]========]
sources["StarterPlayer/StarterPlayerScripts/Controllers/ActivityController"]=[========[local RS=game:GetService("ReplicatedStorage") local A=require(RS.Config.ActivityConfig) local S={Items={}}
function S:Init(ui) self.UI=ui local folder=Instance.new("Folder") folder.Name="LocalBloomTokens" folder.Parent=workspace self.Folder=folder end
function S:Update(list)
 local keep={} for _,o in ipairs(list) do keep[o.Id]=true local item=self.Items[o.Id]
  if item and item.Index~=o.Index then item.Part:Destroy() self.Items[o.Id]=nil item=nil end
  if not item then local part=Instance.new("Part") part.Name=o.Kind part.Shape=Enum.PartType.Ball part.Size=Vector3.new(1.5,1.5,1.5) part.Anchored=true part.CanCollide=false part.CanTouch=false part.Material=Enum.Material.Neon part.Color=Color3.fromRGB(240,220,120) part.Position=o.Position
   if o.Kind=="CrystalResonance" then part.Shape=Enum.PartType.Block part.Size=Vector3.new(1,2.5,1) part.Color=Color3.fromRGB(115,220,255) elseif o.Kind=="NectarBud" then part.Size=Vector3.new(2,2,2) part.Color=Color3.fromRGB(120,230,160) elseif o.Kind=="DewDrop" then part.Color=Color3.fromRGB(150,220,255) elseif o.Kind=="Overcharge" then part.Size=Vector3.new(3,3,3) part.Color=Color3.fromRGB(205,115,250) elseif o.Kind=="FireflyRoute" then part.Color=Color3.fromRGB(220,240,120) end
   if self.UI.State and self.UI.State.Profile.Settings.ReducedEffects then part.Material=Enum.Material.SmoothPlastic end
   part.Parent=self.Folder
   if o.Kind=="NectarBud" or o.Kind=="BloomSurge" then
    local world=workspace:FindFirstChild("BloomWorld") local plot=world and world:FindFirstChild("Garden_"..self.UI.Player.UserId)
    if plot then local nearest=nil local distance=math.huge for _,model in ipairs(plot:GetDescendants()) do if model:IsA("Model") and model.Name:find("FlowerSlot_") and model.PrimaryPart then local d=(model.PrimaryPart.Position-o.Position).Magnitude if d<distance then distance=d nearest=model end end end
     if nearest then local highlight=Instance.new("Highlight") highlight.Adornee=nearest highlight.FillColor=part.Color highlight.FillTransparency=self.UI.State and self.UI.State.Profile.Settings.ReducedEffects and .85 or .6 highlight.Parent=part end
    end
   end
   local prompt=Instance.new("ProximityPrompt") prompt.ActionText=o.Kind.." "..o.Index.."/"..o.Count prompt.MaxActivationDistance=A.PickupDistance prompt.RequiresLineOfSight=false prompt.HoldDuration=o.Hold and A.HoldSeconds or 0 prompt.Parent=part
   prompt.PromptButtonHoldBegan:Connect(function() self.UI:Send("Activity",o.Id,o.Index,"Begin") end)
   prompt.Triggered:Connect(function() self.UI:Send("Activity",o.Id,o.Index,"Collect") end)
   item={Part=part,Index=o.Index,Expires=o.Expires} self.Items[o.Id]=item
  end
 end
 for id,item in pairs(self.Items) do if not keep[id] then item.Part:Destroy() self.Items[id]=nil end end
end
function S:Others(list)
 if not self.OtherFolder then self.OtherFolder=Instance.new("Folder") self.OtherFolder.Name="OtherBloomTokens" self.OtherFolder.Parent=workspace end
 self.OtherItems=self.OtherItems or {} local keep={}
 if self.UI.State and not self.UI.State.Profile.Settings.HideOtherPlayersTokens then for _,o in ipairs(list) do if o.Owner~=self.UI.Player.UserId then keep[o.Id]=true local part=self.OtherItems[o.Id] if not part then part=Instance.new("Part") part.Shape=Enum.PartType.Ball part.Size=Vector3.new(1,1,1) part.Transparency=.6 part.Anchored=true part.CanCollide=false part.CanTouch=false part.Color=Color3.fromRGB(170,200,140) part.Parent=self.OtherFolder self.OtherItems[o.Id]=part end part.Position=o.Position end end end
 for id,part in pairs(self.OtherItems) do if not keep[id] then part:Destroy() self.OtherItems[id]=nil end end
end
function S:Target() for _,item in pairs(self.Items) do return item.Part end end
function S:Cleanup() self:Update({}) end
return S
]========]
local cache={}
function require(ref)
 if cache[ref.path] then return cache[ref.path] end
 local source=assert(sources[ref.path],"Unknown require "..ref.path)
 local env=setmetatable({script=node(ref.path)},{__index=_G})
 local f,err=load(source,ref.path,"t",env) assert(f,err) local result=f() cache[ref.path]=result return result
end
local passed=0
local function test(name,fn) local ok,err=pcall(fn) if not ok then error(name..": "..tostring(err)) end passed=passed+1 print("PASS "..name) end
local Schema=require(node("ServerScriptService/Data/ProfileSchema"))
local U=require(rs.Shared.BloomUtil)
local function equal(a,b) if type(a)~=type(b) then return false end if type(a)~="table" then return a==b end for k,v in pairs(a) do if not equal(v,b[k]) then return false end end for k in pairs(b) do if a[k]==nil then return false end end return true end
test("default profile",function() local p=Schema.CreateDefault() assert(Schema.Prepare(p)) assert(p.SchemaVersion==5 and p.Inventory==nil and p.Currencies.Coins==0) end)
test("legacy mapping, dust, planted ownership",function()
 local p={Inventory={Apple=2,UnknownFruit=3},Currencies={FruitDust=12,Coins=9,AncientSeeds=77},DiscoveredFruits={Apple=true},Garden={UnlockedSlots=3,Slots={{SpeciesId="Tulip",Level=2}}},FruitMastery={Apple={Level=999}}}
 assert(Schema.Prepare(p)) assert(p.FlowerCollection.OwnedSeedCopies.Daisy==3) assert(p.FlowerCollection.OwnedSeedCopies.Tulip==1) assert(p.Currencies.PetalDust==27) assert(p.Currencies.AncientNectar==0) assert(p.LegacyArchive.AncientSeeds==77) assert(p.FlowerCollection.FlowerMastery.Daisy.Level==100)
 local before=U.Copy(p) assert(Schema.Prepare(p)) assert(equal(before,p),"migration not idempotent")
end)
test("empty garden stays empty",function() local p=Schema.CreateDefault() p.Garden.Slots={{},{},{}} p.FlowerCollection.OwnedSeedCopies={} assert(Schema.Prepare(p)) assert(not p.Garden.Slots[1].SpeciesId) assert(not p.FlowerCollection.OwnedSeedCopies.Daisy) end)
test("migration rejects NaN without mutation",function() local p={Currencies={Coins=0/0},Inventory={Apple=2}} assert(not Schema.Prepare(p)) assert(p.Inventory.Apple==2 and p.Migrations==nil) end)
test("malformed nested containers repaired",function() local p={Currencies="oops",Garden={Slots="oops"},FlowerCollection="oops"} assert(Schema.Prepare(p)) assert(type(p.Garden.Slots)=="table") end)
test("all registries valid, Workshop 43",function() assert(require(node("ServerScriptService/Tests/ConfigValidation")).Run()) end)
test("odds normalized, 10000 samples known",function()
 local p=Schema.CreateDefault() local Pool=require(rs.Config.RollPoolConfig) local F=require(rs.Config.FlowersConfig) local B=require(rs.Config.BeesConfig)
 local pool,total=Pool.Build(p,1,{}) local sum=0 for _,v in ipairs(pool) do sum=sum+v.Chance end assert(math.abs(sum-1)<1e-9)
 for i=1,10000 do local t=math.random()*total local selected=pool[#pool] for _,v in ipairs(pool) do t=t-v.Weight if t<=0 then selected=v break end end assert(selected.Kind=="FlowerSeed" and F.Exists(selected.Id) or selected.Kind=="Bee" and B.Exists(selected.Id)) end
end)
test("discovery guarantee only undiscovered",function() local p=Schema.CreateDefault() p.RollState.DiscoveryPity=29 local pool=require(rs.Config.RollPoolConfig).Build(p,1,{}) for _,v in ipairs(pool) do assert(v.Undiscovered) end end)
test("all-discovered guarantee safe fallback",function() local p=Schema.CreateDefault() for id in pairs(require(rs.Config.FlowersConfig).Species) do p.FlowerCollection.DiscoveredFlowers[id]=true end for id in pairs(require(rs.Config.BeesConfig).Bees) do p.Pollinators.DiscoveredBees[id]=true end p.RollState.DiscoveryPity=29 local pool,total=require(rs.Config.RollPoolConfig).Build(p,1,{}) assert(#pool>0 and total>0) end)
test("ownership, dissolve protection, remaining copy",function()
 local p=Schema.CreateDefault() p.FlowerCollection.OwnedSeedCopies.Daisy=3 local inv=require(node("ServerScriptService/Services/InventoryService"))
 inv:Init({Profile=function() return p end,FlowerProgressionService={Add=function() end},Emit=function() end}) assert(inv:Available(p,"Daisy")==2)
 p.FlowerCollection.LockedFlowers.Daisy=true assert(not inv:Dissolve({},"Daisy",1)) p.FlowerCollection.LockedFlowers.Daisy=nil
 assert(inv:Dissolve({},"Daisy",2)) assert(p.Currencies.PetalDust==6) assert(not inv:Dissolve({},"Daisy",1)) assert(not inv:Dissolve({},"Daisy",0/0))
end)
test("season dry run deterministic and preserves mastery",function()
 local p=Schema.CreateDefault() p.FlowerCollection.FlowerMastery.Daisy={Level=15,XP=8} p.Season.Keepsakes.Flower="Tulip" p.FlowerCollection.OwnedSeedCopies.Tulip=2 p.WorkshopV5.Nodes.ROLL_1=true p.WorkshopV5.Nodes.LEGACY_1=true p.WorkshopV5.LegacyNodes.LEGACY_1=true
 local before=U.Copy(p) local fn=require(rs.Shared.SeasonPlan).BuildSeasonTurnPlan local a=fn(p) local b=fn(p) assert(equal(a,b) and equal(p,before)) assert(a.After.Season.Count==1 and a.After.Currencies.AncientNectar==5) assert(a.After.FlowerCollection.FlowerMastery.Daisy.Level==15 and a.After.WorkshopV5.Nodes.LEGACY_1) assert(not a.After.WorkshopV5.Nodes.ROLL_1 and a.After.Garden.Slots[1].SpeciesId=="Tulip")
end)
test("trait copies cannot be equipped beyond ownership",function()
 local p=Schema.CreateDefault() p.Pollinators.BeeInventory.WorkerBee=1 local inv=require(node("ServerScriptService/Services/InventoryService"))
 inv:Init({Profile=function() return p end,U=U,StatsService={BeeCapacity=function() return 3 end},GardenSynergyService={Recalculate=function() end},Emit=function() end})
 assert(inv:EquipBee({},"WorkerBee",1)) assert(not inv:EquipBee({},"WorkerBee",2)) assert(not inv:EquipBee({},"WorkerBee",0/0))
end)
test("synergies use physical adjacency, not equipped legacy",function()
 local p=Schema.CreateDefault() p.Garden.Slots[1]={SpeciesId="Daisy"} p.Garden.Slots[2]={SpeciesId="Tulip"} p.EquippedFruitIds={"Starfruit"}
 local service=require(node("ServerScriptService/Services/GardenSynergyService")) local player={}
 local x={Profile=function() return p end,Temp={[player]={}},Emit=function() end,MapService={Sector=function() return "Center" end}}
 service:Init(x) assert(service:Recalculate(player).MeadowPair) p.Garden.Slots[2]={} p.Garden.Slots[15]={SpeciesId="Tulip"} assert(not service:Recalculate(player).MeadowPair)
end)
test("roll independent players, 100 cycles, cooldown and one-time Bloom",function()
 local a,b={},{} local profiles={[a]=Schema.CreateDefault(),[b]=Schema.CreateDefault()} local temp={[a]={},[b]={}} local rewards=0 local inv=require(node("ServerScriptService/Services/InventoryService")) local roll=require(node("ServerScriptService/Services/RollService"))
 local x={Temp=temp,Profile=function(_,pl) return profiles[pl] end,StatsService={Get=function() return {Luck=1} end},Send=function(_,pl,kind,r) if kind=="Reward" then rewards=rewards+1 end end,Broadcast=function() end,Emit=function() end,FlowerProgressionService={Add=function() end}}
 x.InventoryService=inv inv:Init(x) roll:Init(x) for _,p in pairs(profiles) do p.Tutorial.FeatureUnlocks.Roll=true p.Tutorial.FeatureUnlocks.AutoRoll=false end
 profiles[a].RollState.SpecialRollReady=true profiles[a].RollState.BloomCharge=100
 assert(roll:Roll(a,false)) assert(profiles[a].RollState.BloomCharge==0) assert(roll:Roll(b,false)) assert(not roll:Roll(a,false))
 for i=1,100 do roll.Last[a]=-100 assert(roll:Roll(a,true)) end assert(profiles[a].RollState.TotalRolls==101 and profiles[b].RollState.TotalRolls==1 and rewards==102)
end)
test("activity owner, distance, order, expiry, duplicate rejection",function()
 local player,other={},{} local p=Schema.CreateDefault() local near=true local events={}
 local service=require(node("ServerScriptService/Services/GardenActivityService")) local x={Profile=function(_,who) if who==player then return p end end,Temp={[player]={}},U={Near=function() return near end},Emit=function(_,pl,event) events[event]=(events[event] or 0)+1 end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},GardenPlotService={HivePosition=function() return Vector3.zero end,Position=function(_,pl,i) return Vector3.new(i*7,0,0) end}}
 service:Init(x) service.Offers[player]={token={Id="token",Kind="PollenTrail",Index=1,Nodes={Vector3.zero,Vector3.new(3,0,0)},Expires=os.clock()+5,Revision=0}}
 assert(not service:Collect(other,"token",1,"Collect")) near=false assert(not service:Collect(player,"token",1,"Collect")) near=true assert(not service:Collect(player,"token",2,"Collect")) assert(service:Collect(player,"token",1,"Collect")) assert(service:Collect(player,"token",2,"Collect")) assert(not service:Collect(player,"token",2,"Collect")) assert(events.PollenTrail==1)
 service.Offers[player].expired={Id="expired",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=-1} assert(not service:Collect(player,"expired",1,"Collect"))
end)
test("Nectar hold cannot finish immediately",function()
 local player={} local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/GardenActivityService"))
 s:Init({Profile=function() return p end,Temp={[player]={}},U={Near=function() return true end},Emit=function() end,Send=function() end})
 s.Offers[player]={hold={Id="hold",Kind="NectarBud",Index=1,Nodes={Vector3.zero},Expires=os.clock()+10}}
 assert(not s:Collect(player,"hold",1,"Collect")) assert(s:Collect(player,"hold",1,"Begin")) assert(not s:Collect(player,"hold",1,"Collect")) assert(s:Collect(player,"hold",1,"Cancel")) assert(not s:Collect(player,"hold",1,"Collect"))
end)
test("Workshop purchase prerequisites, balance, idempotence",function()
 local p=Schema.CreateDefault() p.Hive.Level=8 p.Tutorial.FeatureUnlocks.Workshop=true p.WorkshopV5.Points=5 p.Currencies.Coins=1000
 local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end,GardenPlotService={RefreshCapacity=function() end},TutorialService={Refresh=function() end},Emit=function() end})
 assert(not s:Buy({},"ROLL_2")) assert(s:Buy({},"ROLL_1")) assert(not s:Buy({},"ROLL_1")) assert(p.WorkshopV5.Points==4 and p.Currencies.Coins==970) assert(not s:Buy({},"LEGACY_1"))
end)
test("tutorial has 18 steps, reconnect progress, unlocks",function()
 local p=Schema.CreateDefault() local service=require(node("ServerScriptService/Services/TutorialService")) service:Init({Profile=function() return p end,EmitOnce=function() end})
 local T=require(rs.Config.TutorialConfig) assert(#T.Steps==18)
 for i=1,18 do local e=T.Steps[i].Event if e=="Deliveries" then p.Tutorial.Events.Delivery=3 else p.Tutorial.Events[e]=1 end service:Refresh({}) assert(p.Tutorial.Step>=i+1) end
 local copy=U.Copy(p) assert(Schema.Prepare(copy)) assert(copy.Tutorial.Step==19 and copy.Tutorial.FeatureUnlocks.Roll and copy.Tutorial.FeatureUnlocks.Trials)
end)
test("one-time point source and preservation of Nectar",function()
 local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end}) s:Point({},"same",2) s:Point({},"same",2) assert(p.WorkshopV5.Points==2 and p.Currencies.AncientNectar==0)
end)

print("TOTAL PASS "..passed)
