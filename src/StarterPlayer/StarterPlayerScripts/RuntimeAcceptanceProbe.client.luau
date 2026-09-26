local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players=game:GetService("Players")
local Stats=game:GetService("Stats")
local UIS=game:GetService("UserInputService")

local player=Players.LocalPlayer
local SAMPLE_SECONDS=1
local REPORT_CHECKPOINTS={60,600,900,1800,3600}
local started=os.clock()
local accum=0
local frames=0
local maxFrameMs=0
local secondFrameMs={}
local checkpointIndex=1
local inputs={Keyboard=0,Mouse=0,Touch=0,Wheel=0}

local function totalMemoryMb()
 local ok,value=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
 return ok and value or -1
end

local function networkMetric(name)
 local ok,value=pcall(function() return Stats[name] end)
 if ok and type(value)=="number" then return value end
 return -1
end

local function percentile(samples,p)
 if #samples==0 then return 0 end
 local copy=table.clone(samples)
 table.sort(copy)
 local index=math.clamp(math.ceil(#copy*p),1,#copy)
 return copy[index]
end

local function uiCount()
 local gui=player:FindFirstChildOfClass("PlayerGui")
 return gui and #gui:GetDescendants() or 0
end

local function report(label)
 local avg=0
 for _,value in ipairs(secondFrameMs) do avg+=value end
 if #secondFrameMs>0 then avg/=#secondFrameMs end
 print(string.format(
  "[RuntimeProbe][Client] %s user=%d elapsed=%ds frame_avg=%.2fms frame_p95=%.2fms frame_max=%.2fms memory=%.1fMB ui_instances=%d recv=%.1fkbps send=%.1fkbps input=k%d/m%d/t%d/w%d",
  label,player.UserId,math.floor(os.clock()-started),avg,percentile(secondFrameMs,.95),maxFrameMs,totalMemoryMb(),uiCount(),
  networkMetric("DataReceiveKbps"),networkMetric("DataSendKbps"),
  inputs.Keyboard,inputs.Mouse,inputs.Touch,inputs.Wheel
 ))
end

UIS.InputBegan:Connect(function(input)
 local kind=input.UserInputType
 if kind==Enum.UserInputType.Keyboard then inputs.Keyboard+=1
 elseif kind==Enum.UserInputType.MouseButton1 or kind==Enum.UserInputType.MouseButton2 or kind==Enum.UserInputType.MouseButton3 then inputs.Mouse+=1
 elseif kind==Enum.UserInputType.Touch then inputs.Touch+=1 end
end)
UIS.InputChanged:Connect(function(input)
 if input.UserInputType==Enum.UserInputType.MouseWheel then inputs.Wheel+=1 end
end)

RunService.RenderStepped:Connect(function(dt)
 accum+=dt
 frames+=1
 maxFrameMs=math.max(maxFrameMs,dt*1000)
 if accum>=SAMPLE_SECONDS then
  local avgMs=frames>0 and (accum/frames)*1000 or 0
  table.insert(secondFrameMs,avgMs)
  if #secondFrameMs>3600 then table.remove(secondFrameMs,1) end
  accum=0
  frames=0
 end
 local checkpoint=REPORT_CHECKPOINTS[checkpointIndex]
 if checkpoint and os.clock()-started>=checkpoint then
  report(string.format("CHECKPOINT_%dm",math.floor(checkpoint/60)))
  checkpointIndex+=1
 end
end)

script.Destroying:Connect(function()
 report("CLIENT_DESTROY")
end)

print("[RuntimeProbe][Client] Studio-only read-only probe active. Frame/memory/UI/input checkpoints at 1/10/15/30/60 minutes.")
