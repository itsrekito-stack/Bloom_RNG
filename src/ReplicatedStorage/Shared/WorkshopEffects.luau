local Config=require(game:GetService("ReplicatedStorage").Config.WorkshopEffectsConfig)
local S={Config=Config}
function S.Owned(p,id)
 return p~=nil and p.WorkshopV5~=nil and p.WorkshopV5.Nodes~=nil and p.WorkshopV5.Nodes[id]==true
end
function S.Value(p,id,key,default)
 if not S.Owned(p,id) then return default end
 local node=Config[id]
 if not node or node[key]==nil then return default end
 return node[key]
end
function S.Feature(p,id,feature)
 if not S.Owned(p,id) then return false end
 local node=Config[id]
 return node~=nil and node.Feature==feature
end
-- Backward-compatible aggregate helper. Prefer Value() because different
-- effect families have different aggregation semantics.
function S.Get(p,key,default)
 local result=default or 0
 for id,owned in pairs(p.WorkshopV5.Nodes) do
  if owned and Config[id] and Config[id][key]~=nil then
   local v=Config[id][key]
   if type(v)=="number" then
    if string.find(key,"Scale") or string.find(key,"Yield") or string.find(key,"Charge") or string.find(key,"Weight") or string.find(key,"Interval") or string.find(key,"Cooldown") then
     result=result==0 and v or math.min(result,v)
    else
     result=result+v
    end
   end
  end
 end
 return result
end
return S
