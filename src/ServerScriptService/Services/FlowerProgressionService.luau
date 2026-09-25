local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BloomConfig)
local E=require(RS.Shared.WorkshopEffects)
local S={}

function S:Init(x)
 self.X=x
end

function S:Add(player,id,xp)
 local p=self.X:Profile(player)
 if not p or type(id)~="string" or type(xp)~="number" or xp<=0 then return false end
 local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
 p.FlowerCollection.FlowerMastery[id]=m
 m.XP+=xp
 while m.Level<C.MasteryCap and m.XP>=m.Level*C.MasteryXP do
  m.XP-=m.Level*C.MasteryXP
  m.Level+=1
 end
 return true
end

function S:Upgrade(player,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if type(id)~="string" or not p.FlowerCollection.DiscoveredFlowers[id] then return false,"NOT_DISCOVERED" end
 local m=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
 if m.Level>=C.MasteryCap then return false,"MASTERY_MAX" end
 local cost=math.ceil(m.Level*5*(1-E.Value(p,"ECONOMY_5","StudyDiscount",0)))
 if p.Currencies.PetalDust<cost then return false,"DUST_REQUIRED" end
 p.Currencies.PetalDust-=cost
 self:Add(player,id,m.Level*C.MasteryXP)
 return true
end

return S
