local Services=script.Parent.Services
-- Remove incompatible LocalScripts / GUI left behind when this Rojo place was merged with an older Fruit RNG place.
local Players=game:GetService("Players")
local StarterPlayer=game:GetService("StarterPlayer")
local StarterGui=game:GetService("StarterGui")
local LEGACY_CLIENTS={ProgressionHub=true,CurrencyHUD=true,HiveHUD=true,TutorialGuide=true,FlowerBillboardController=true,QuestTracker=true,BeeTraitsHUD=true}
local LEGACY_ROLL_NAMES={
 Roulette=true,RouletteGui=true,RouletteGUI=true,RouletteFrame=true,RoulettePanel=true,RouletteContainer=true,
 Reel=true,ReelFrame=true,SpinFrame=true,SpinGui=true,OldRoulette=true,OldRollUI=true,
 TutorialRollButton=true,AutoRollButton=true,RollGui=true,RollGUI=true,RollUI=true,RollFrame=true,RollPanel=true,RollContainer=true,
}
local function looksLegacyRoll(item:Instance)
 if LEGACY_ROLL_NAMES[item.Name] then return true end
 local lower=string.lower(item.Name)
 return string.find(lower,"roulette",1,true)~=nil or string.find(lower,"reel",1,true)~=nil or string.find(lower,"oldroll",1,true)~=nil
end
local function removeLegacy(folder:Instance?)
 if not folder then return end
 for _,item in ipairs(folder:GetDescendants()) do
  if item:IsA("LocalScript") and LEGACY_CLIENTS[item.Name] then
   warn("[Bloom RNG] Removed retired client script:",item:GetFullName())
   item:Destroy()
  end
 end
end
local function removeLegacyRollGui(folder:Instance?)
 if not folder then return end
 for _,child in ipairs(folder:GetChildren()) do
  if child:IsA("ScreenGui") and child.Name~="BloomUI" then
   local legacy=looksLegacyRoll(child)
   if not legacy then
    for _,item in ipairs(child:GetDescendants()) do
     if looksLegacyRoll(item) then legacy=true break end
    end
   end
   if legacy then
    warn("[Bloom RNG] Removed retired roulette GUI:",child:GetFullName())
    child:Destroy()
   end
  end
 end
end
local starterScripts=StarterPlayer:FindFirstChild("StarterPlayerScripts")
removeLegacy(starterScripts)
removeLegacyRollGui(StarterGui)
Players.PlayerAdded:Connect(function(player)
 local scripts=player:WaitForChild("PlayerScripts",10)
 removeLegacy(scripts)
 local playerGui=player:WaitForChild("PlayerGui",10)
 removeLegacyRollGui(playerGui)
end)
for _,player in ipairs(Players:GetPlayers()) do
 task.spawn(function()
  removeLegacy(player:FindFirstChild("PlayerScripts"))
  removeLegacyRollGui(player:FindFirstChild("PlayerGui"))
 end)
end

local Data=require(Services.DataService)
local Player=require(Services.PlayerService)
local names={"RemoteService","FlowerService","InventoryService","StatsService","BoostService","FlowerProgressionService","GardenSynergyService","GardenPlotService","HiveService","RollService","GardenActivityService","PollinatorService","MapService","WorkshopService","TutorialService","MetaProgressionService","BuildTrialService","SeasonService","SocialService","AnalyticsService","UIStateService"}
local loaded={} for _,name in ipairs(names) do loaded[name]=require(Services[name]) end
local ok,err=xpcall(function()
 require(script.Parent.Tests.ConfigValidation).Run()
 Data:Init() Player:Start(Data,loaded,names) Data:Start() print("[BLOOM RNG] server ready")
end,debug.traceback)
if not ok then error("[BLOOM RNG] boot failed: "..tostring(err)) end
