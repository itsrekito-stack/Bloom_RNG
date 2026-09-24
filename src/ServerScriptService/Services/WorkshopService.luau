local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.WorkshopConfig) local S={}
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
