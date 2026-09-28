local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.GardenSynergyConfig)
local S={Active={}}

function S:Init(x)
 self.X=x
end

local function levelOf(profile,id)
 local mastery=profile.FlowerCollection.FlowerMastery[id]
 return math.max(1,math.floor(tonumber(mastery and mastery.Level) or 1))
end

local function evaluate(profile,recipe)
 local slotsBySpecies={}
 for index,slot in ipairs(profile.Garden.Slots) do
  if slot.SpeciesId then slotsBySpecies[slot.SpeciesId]=index end
 end
 local matches={}
 for _,id in ipairs(recipe.Species or {}) do
  local slot=slotsBySpecies[id]
  if not slot then return nil end
  if levelOf(profile,id)<(tonumber(recipe.Levels and recipe.Levels[id]) or 1) then return nil end
  matches[#matches+1]=slot
 end
 return matches
end

function S:Recalculate(player)
 local p=self.X:Profile(player)
 if not p then return {} end
 local best,bestSlots=nil,nil
 for _,recipe in ipairs(C.Recipes) do
  local matches=evaluate(p,recipe)
  if matches and (not best or (recipe.Strength or 0)>(best.Strength or 0)) then
   best,bestSlots=recipe,matches
  end
 end

 local active={}
 if best then
  active[best.Id]={Kind="Flower",Slots=bestSlots,Strength=best.Strength,Tier=best.Tier}
  if not p.GardenSynergies.Discovered[best.Id] then
   p.GardenSynergies.Discovered[best.Id]=true
   self.X:Emit(player,"Synergy",1)
  end
  p.Garden.ActiveSynergy=best.Id
 else
  p.Garden.ActiveSynergy=""
 end
 self.Active[player]=active
 if self.X.Temp and self.X.Temp[player] then self.X.Temp[player].Signature=best and best.Id=="AstralGarden" or false end
 return active
end

function S:Hint(profile)
 local owned=profile.FlowerCollection.OwnedSeedCopies or {}
 local planted={}
 for _,slot in ipairs(profile.Garden.Slots or {}) do if slot.SpeciesId then planted[slot.SpeciesId]=true end end
 local candidates={}
 for _,recipe in ipairs(C.Recipes) do
  if not profile.GardenSynergies.Discovered[recipe.Id] then
   local missing=nil
   local valid=true
   for _,id in ipairs(recipe.Species or {}) do
    if not planted[id] then
     if missing then valid=false break end
     missing=id
    elseif levelOf(profile,id)<(tonumber(recipe.Levels and recipe.Levels[id]) or 1) then
     valid=false break
    end
   end
   if valid and missing and (owned[missing] or 0)>0 and levelOf(profile,missing)>=(tonumber(recipe.Levels and recipe.Levels[missing]) or 1) then
    candidates[#candidates+1]={FlowerId=missing,Strength=recipe.Strength or 0}
   end
  end
 end
 table.sort(candidates,function(a,b)return a.Strength>b.Strength end)
 return candidates[1] and {FlowerId=candidates[1].FlowerId} or nil
end

function S:Remove(player)
 self.Active[player]=nil
end

return S
