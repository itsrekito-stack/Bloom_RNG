local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.WorkshopConfig)
local Rules=require(RS.Shared.GardenRules)
local E=require(RS.Shared.WorkshopEffects)
local Copy=require(RS.Shared.BloomUtil).Copy
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

function S:Buy(player,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 local n=type(id)=="string" and C.Nodes[id] or nil
 if not n or id=="CORE" then return false,"INVALID_NODE" end
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
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if not p.Tutorial.FeatureUnlocks.Workshop then return false,"FEATURE_LOCKED" end

 -- Validate the future profile before touching balances, nodes, slots or equips.
 local future=Copy(p)
 for id in pairs(future.WorkshopV5.Nodes) do
  local node=C.Nodes[id]
  if node and not node.Permanent then future.WorkshopV5.Nodes[id]=nil end
 end
 local gardenCapacity=Rules.FlowerCapacity(future)
 local beeCapacity=Rules.BeeCapacity(future)
 if Rules.HasOverflow(p.Garden.Slots,gardenCapacity) then return false,"RESPEC_GARDEN_OCCUPIED" end
 local changed=false
 for id in pairs(p.WorkshopV5.Nodes) do
  local n=C.Nodes[id]
  if n and not n.Permanent then
   changed=true
   p.WorkshopV5.Points+=(n.Cost or 0)
   p.Currencies.Coins+=(n.Coins or 0)
   p.Currencies.PetalDust+=(n.Dust or 0)
   p.WorkshopV5.Nodes[id]=nil
  end
 end
 if not changed then return false,"NO_CHANGES" end

 -- Empty overflow slots need no deletion. Ownership is separate from equipment.
 for slot in pairs(p.Pollinators.EquippedBeeSlots) do
  if tonumber(slot) and tonumber(slot)>beeCapacity then p.Pollinators.EquippedBeeSlots[slot]=nil end
 end

 self.X.GardenPlotService:RefreshCapacity(player)
 self.X.GardenSynergyService:Recalculate(player)
 self.X.TutorialService:Refresh(player)
 return true
end

return S

