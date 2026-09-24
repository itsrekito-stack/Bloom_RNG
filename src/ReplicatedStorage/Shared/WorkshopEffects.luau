local Config=require(game:GetService("ReplicatedStorage").Config.WorkshopEffectsConfig)
local S={}
function S.Get(p,key,default)
 local result=default or 0
 for id,owned in pairs(p.WorkshopV5.Nodes) do if owned and Config[id] and Config[id][key]~=nil then local v=Config[id][key] if type(v)=="number" then if string.find(key,"Scale") or string.find(key,"Yield") or string.find(key,"Charge") or string.find(key,"Weight") or string.find(key,"Interval") or string.find(key,"Cooldown") then result=result==0 and v or math.min(result,v) else result=result+v end end end end
 return result
end return S
