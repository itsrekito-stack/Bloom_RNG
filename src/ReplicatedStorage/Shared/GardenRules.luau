local C=require(script.Parent.Parent.Config.BloomConfig)
local E=require(script.Parent.WorkshopEffects)
local Rules={}
function Rules.FlowerCapacity(p)
 return math.min(C.MaxFlowerSlots,3+math.max(0,p.Hive.Level-1)+E.Value(p,"GARDEN_1","FlowerSlots",0)+E.Value(p,"GARDEN_4","FlowerSlots",0))
end
function Rules.BeeCapacity(p)
 return math.min(C.MaxBeeSlots,1+(p.Hive.Level>=2 and 1 or 0)+E.Value(p,"BEES_1","BeeSlots",0)+E.Value(p,"BEES_5","BeeSlots",0))
end
function Rules.HasState(slot)
 return type(slot)=="table" and next(slot)~=nil
end
function Rules.HasProgress(slot)
 if type(slot)~="table" then return slot~=nil end
 if (slot.Level or 1)>1 or (slot.XP or 0)>0 or (slot.TotalPollination or 0)>0 or (slot.Mutation or "")~="" then return true end
 for key in pairs(slot) do
  if key~="SpeciesId" and key~="Level" and key~="XP" and key~="TotalPollination" and key~="Mutation" then return true end
 end
 return false
end
function Rules.HasOverflow(slots,capacity)
 for key,slot in pairs(slots) do
  local index=tonumber(key)
  if (not index or index%1~=0 or index<1 or index>capacity) and Rules.HasState(slot) then return true end
 end
 return false
end
return Rules
