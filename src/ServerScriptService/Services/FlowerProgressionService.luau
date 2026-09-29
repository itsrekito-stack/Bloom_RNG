local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BloomConfig)
local S={}

function S:Init(x)
 self.X=x
end

function S:State(profile,id)
 local collection=profile and profile.FlowerCollection
 if not collection then return {Level=1,XP=0} end
 local state=collection.FlowerMastery[id]
 if type(state)~="table" then
  state={Level=1,XP=0}
  collection.FlowerMastery[id]=state
 end
 state.Level=math.max(1,math.floor(tonumber(state.Level) or 1))
 state.XP=math.max(0,tonumber(state.XP) or 0)
 return state
end

function S:Add(player,id,xp)
 local p=self.X:Profile(player)
 if not p or type(id)~="string" or type(xp)~="number" or xp<=0 then return false end
 local m=self:State(p,id)
 local beforeLevel=m.Level
 m.XP+=xp
 while m.Level<C.MasteryCap and m.XP>=m.Level*C.MasteryXP do
  m.XP-=m.Level*C.MasteryXP
  m.Level+=1
 end
 if m.Level~=beforeLevel and self.X.GardenPlotService then
  self.X.GardenPlotService:RefreshFlowerSpecies(player,id)
 end
 return true
end

function S:AddDuplicate(player,id,count)
 count=math.max(1,math.floor(tonumber(count) or 1))
 return self:Add(player,id,count*C.FlowerDuplicateXP)
end

function S:Upgrade()
 return false,"ACTION_UNAVAILABLE"
end

return S
