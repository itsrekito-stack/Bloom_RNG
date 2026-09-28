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
 return true
end

function S:AwardHiveLevel(player,level)
 local p=self.X:Profile(player)
 if not p then return 0,"PROFILE_LOADING" end
 level=math.max(2,math.floor(tonumber(level) or 2))
 local points=Bloom.WorkshopPointsForHiveLevel(level)
 if points<=0 then return 0 end
 local ok,reason=self:Point(player,"HiveLevel_"..tostring(level),points)
 return ok and points or 0,reason
end

function S:ReconcileHivePoints(player)
 local p=self.X:Profile(player)
 if not p then return 0 end
 local expected=0
 for level=2,math.max(1,math.floor(tonumber(p.Hive.Level) or 1)) do
  expected+=Bloom.WorkshopPointsForHiveLevel(level)
 end
 local spent=0
 for id in pairs(p.WorkshopV5.Nodes or {}) do
  local node=C.Nodes[id]
  if node then spent+=math.max(0,tonumber(node.Cost) or 0) end
 end
 local observed=math.max(0,tonumber(p.WorkshopV5.Points) or 0)+spent
 local deficit=math.max(0,expected-observed)
 if deficit>0 then
  p.WorkshopV5.Points+=deficit
  warn("[Workshop] restored missing Hive Workshop Points player="..tostring(player.Name).." +"..tostring(deficit))
 end
 for level=2,math.max(1,math.floor(tonumber(p.Hive.Level) or 1)) do
  if Bloom.WorkshopPointsForHiveLevel(level)>0 then p.WorkshopV5.ClaimedSources["HiveLevel_"..tostring(level)]=true end
 end
 return deficit
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

