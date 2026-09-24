local Services=script.Parent.Services
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
