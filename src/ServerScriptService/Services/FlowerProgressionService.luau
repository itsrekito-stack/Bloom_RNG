local C=require(game:GetService("ReplicatedStorage").Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:Add(player,id,xp) local p=self.X:Profile(player) if not p then return end local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0} p.FlowerCollection.FlowerMastery[id]=m m.XP=m.XP+xp while m.Level<C.MasteryCap and m.XP>=m.Level*C.MasteryXP do m.XP=m.XP-m.Level*C.MasteryXP m.Level=m.Level+1 end end
function S:Upgrade(player,id) local p=self.X:Profile(player) if not p or not p.FlowerCollection.DiscoveredFlowers[id] then return false end local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0} local cost=math.ceil(m.Level*5*(p.WorkshopV5.Nodes.ECONOMY_5 and .8 or 1)) if m.Level>=C.MasteryCap or p.Currencies.PetalDust<cost then return false end p.Currencies.PetalDust=p.Currencies.PetalDust-cost self:Add(player,id,m.Level*C.MasteryXP) return true end
return S
