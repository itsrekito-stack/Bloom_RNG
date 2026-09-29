local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.WorkshopConfig)
local Bloom=require(RS.Config.BloomConfig)
local T=require(RS.Config.TutorialConfig)
local E=require(RS.Shared.WorkshopEffects)
local S={}

function S:Init(x)
 self.X=x
end

function S:Point(player,key,amount)
 local p=self.X:Profile(player)
 if not p or type(key)~="string" or type(amount)~="number" or amount<=0 then return false end
 local w=p.WorkshopV5
 if w.ClaimedSources[key] then return false,"OWNED" end
 w.ClaimedSources[key]=true
 w.Points=w.Points+amount
 if w.Nodes.ECONOMY_4 then p.Currencies.Coins=p.Currencies.Coins+E.Value(p,"ECONOMY_4","MilestoneCoins",0) end
 if self.X.MarkStateDirty then self.X:MarkStateDirty(player) end
 return true
end

local function hivePointKeys(profile,level)
 local season=math.max(0,math.floor(tonumber(profile.Season and profile.Season.Count) or 0))
 return "HiveSeason_"..tostring(season).."_Level_"..tostring(level),"Hive_"..tostring(season).."_"..tostring(level),season
end

local function hasHivePointSource(profile,level)
 local key,legacy,season=hivePointKeys(profile,level)
 local claimed=profile.WorkshopV5.ClaimedSources
 if claimed[key] then return true,key end
 if claimed[legacy] then return true,legacy end
 if season==0 then
  local old="HiveLevel_"..tostring(level)
  if claimed[old] then return true,old end
 end
 return false,nil
end

function S:AwardHiveLevel(player,level)
 local p=self.X:Profile(player)
 if not p then return 0,"PROFILE_LOADING" end
 level=math.max(2,math.floor(tonumber(level) or 2))
 local points=Bloom.WorkshopPointsForHiveLevel(level)
 if points<=0 then return 0 end
 local key=hivePointKeys(p,level)
 local claimed=hasHivePointSource(p,level)
 if claimed then
  p.WorkshopV5.ClaimedSources[key]=true
  return 0,"OWNED"
 end
 local ok,reason=self:Point(player,key,points)
 return ok and points or 0,reason
end

function S:ReconcileHivePoints(player)
 local p=self.X:Profile(player)
 if not p then return 0 end
 local restored=0
 for level=2,math.max(1,math.floor(tonumber(p.Hive.Level) or 1)) do
  local points=Bloom.WorkshopPointsForHiveLevel(level)
  if points>0 then
   local key=hivePointKeys(p,level)
   local claimed=hasHivePointSource(p,level)
   if claimed then
    p.WorkshopV5.ClaimedSources[key]=true
   else
    local ok=self:Point(player,key,points)
    if ok then restored+=points end
   end
  end
 end
 if restored>0 then
  warn("[Workshop] restored missing Hive Workshop Points player="..tostring(player.Name).." +"..tostring(restored))
  self.X:Send(player,"Message","Restored +"..tostring(restored).." missing Workshop Point"..(restored==1 and "" or "s").." from Hive progression")
 end
 return restored
end

function S:Buy(player,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local n=type(id)=="string" and C.Nodes[id] or nil
 if not n or id=="CORE" then return false,"INVALID_NODE" end
 local tutorialStep=T.Steps[p.Tutorial.Step]
 if tutorialStep and tutorialStep.Id=="WorkshopPurchase" and id~=(tutorialStep.NodeId or "ROLL_1") then return false,"TUTORIAL_TARGET" end
 if not p.Tutorial.FeatureUnlocks.Workshop then return false,"FEATURE_LOCKED" end

 local w=p.WorkshopV5
 if w.Nodes[id] then return false,"OWNED" end
 if n.Parent and n.Parent~="CORE" and not w.Nodes[n.Parent] then return false,"PARENT_REQUIRED" end
 if p.Hive.Level<(n.Hive or 0) then return false,"HIVE_REQUIRED" end
 if n.Branch=="LEGACY" and p.Season.Count==0 then return false,"SEASON_REQUIRED" end
 if w.Points<(n.Cost or 0) then return false,"POINTS_REQUIRED" end
 if p.Currencies.Coins<(n.Coins or 0) then return false,"COINS_REQUIRED" end
 if p.Currencies.PetalDust<(n.Dust or 0) then return false,"DUST_REQUIRED" end
 if p.Currencies.AncientNectar<(n.Nectar or 0) then return false,"NECTAR_REQUIRED" end

 w.Points-=(n.Cost or 0)
 p.Currencies.Coins-=(n.Coins or 0)
 p.Currencies.PetalDust-=(n.Dust or 0)
 p.Currencies.AncientNectar-=(n.Nectar or 0)
 w.Nodes[id]=true
 if n.Permanent then w.LegacyNodes[id]=true end

 self.X.GardenPlotService:RefreshCapacity(player)
 self.X.TutorialService:Refresh(player)
 self.X:Emit(player,"WorkshopPurchase",1)
 return true
end

function S:Respec(player)
 if not self.X:Profile(player) then return false,"PROFILE_LOADING" end
 -- Normal respec is intentionally disabled. RESET & REFUND belongs to the
 -- future Biome transition flow so players cannot freely rewrite builds mid-biome.
 return false,"ACTION_UNAVAILABLE"
end

return S

