local Players=game:GetService("Players")
local player=Players.LocalPlayer

print("[BLOOM RNG] client bootstrap readiness-gate-v1-2026-09-26")
player:SetAttribute("BloomClientBootState","Starting")
player:SetAttribute("BloomClientBootError",nil)

local ok,err=xpcall(function()
 require(script.Parent.Controllers.BloomUI):Start()
end,debug.traceback)

if ok then
 player:SetAttribute("BloomClientBootState","Started")
else
 player:SetAttribute("BloomClientBootState","Failed")
 player:SetAttribute("BloomClientBootError",tostring(err))
 warn("[BLOOM RNG] client bootstrap failed:\n"..tostring(err))
 error(err)
end
