local C=require(script.Parent.Parent.Config.BloomConfig)
local Rules={}

local function milestoneCount(level,milestones)
 local count=0
 for _,required in ipairs(milestones or {}) do
  if level>=required then count+=1 end
 end
 return count
end

function Rules.FlowerCapacity(p)
 local tutorial=p.Tutorial or {}
 local events=tutorial.Events or {}
 local first=(events.FirstGardenSlot or 0)>0 or tutorial.Skipped==true
 local base=first and 1 or 0
 return math.min(C.MaxFlowerSlots,base+milestoneCount(p.Hive.Level,C.GardenSlotHiveMilestones))
end

function Rules.BeeCapacity(p)
 local owned=false
 for _,value in pairs((p.Pollinators and p.Pollinators.BeeInventory) or {}) do
  if (tonumber(value) or 0)>0 then owned=true break end
 end
 if not owned then return 0 end
 return math.min(C.MaxBeeSlots,1+milestoneCount(p.Hive.Level,C.BeeSlotHiveMilestones))
end

function Rules.HasState(slot)
 return type(slot)=="table" and next(slot)~=nil
end

function Rules.HasProgress(slot)
 if type(slot)~="table" then return slot~=nil end
 if (slot.TotalPollination or 0)>0 or (slot.Mutation or "")~="" then return true end
 for key in pairs(slot) do
  if key~="SpeciesId" and key~="TotalPollination" and key~="Mutation" and key~="Level" and key~="XP" then return true end
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
