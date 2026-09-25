local C=require(script.Parent.Parent.Config.BloomConfig)
local Rules={}
function Rules.FlowerCapacity(p)
 return math.min(C.MaxFlowerSlots,3+math.max(0,p.Hive.Level-1)+(p.WorkshopV5.Nodes.GARDEN_1 and 1 or 0)+(p.WorkshopV5.Nodes.GARDEN_4 and 3 or 0))
end
function Rules.BeeCapacity(p)
 return math.min(C.MaxBeeSlots,1+(p.Hive.Level>=2 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_1 and 1 or 0)+(p.WorkshopV5.Nodes.BEES_5 and 2 or 0))
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
