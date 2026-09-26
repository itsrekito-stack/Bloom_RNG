local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players=game:GetService("Players")
local Stats=game:GetService("Stats")
local Data=require(script.Parent.Services.DataService)

local SAMPLE_SECONDS=1
local REPORT_CHECKPOINTS={60,600,900,1800,3600}
local sessions={}

local function countKeys(t)
 local n=0
 for _ in pairs(t or {}) do n+=1 end
 return n
end

local function occupiedGarden(profile)
 local n=0
 for _,slot in ipairs(profile.Garden and profile.Garden.Slots or {}) do
  if type(slot)=="table" and type(slot.SpeciesId)=="string" and slot.SpeciesId~="" then n+=1 end
 end
 return n
end

local function ownedBees(profile)
 local total=0
 for _,count in pairs(profile.Pollinators and profile.Pollinators.BeeInventory or {}) do
  if type(count)=="number" and count>0 then total+=count end
 end
 return total
end

local function ownedWorkshopNodes(profile)
 return countKeys(profile.WorkshopV5 and profile.WorkshopV5.Nodes or {})
end

local function coreState(profile)
 return {
  Profile=true,
  Roll=(profile.RollState and profile.RollState.TotalRolls or 0)>0,
  FlowerReward=countKeys(profile.FlowerCollection and profile.FlowerCollection.DiscoveredFlowers or {})>1
   or countKeys(profile.FlowerCollection and profile.FlowerCollection.OwnedSeedCopies or {})>1,
  Garden=occupiedGarden(profile)>=2,
  Bee=ownedBees(profile)>0,
  Hive=(profile.Hive and profile.Hive.Level or 1)>=2,
  Workshop=ownedWorkshopNodes(profile)>0,
 }
end

local MILESTONE_ORDER={"Profile","Roll","FlowerReward","Garden","Bee","Hive","Workshop"}

local function totalMemoryMb()
 local ok,value=pcall(function() return Stats:GetTotalMemoryUsageMb() end)
 return ok and value or -1
end

local function percentile(samples,p)
 if #samples==0 then return 0 end
 local copy=table.clone(samples)
 table.sort(copy)
 local index=math.clamp(math.ceil(#copy*p),1,#copy)
 return copy[index]
end

local function report(player,session,label)
 local status=Data:GetPersistenceStatus(player)
 local samples=session.SecondFrameMs
 local avg=0
 for _,value in ipairs(samples) do avg+=value end
 if #samples>0 then avg/=#samples end
 print(string.format(
  "[RuntimeProbe][Server] %s user=%d elapsed=%ds frame_avg=%.2fms frame_p95=%.2fms frame_max=%.2fms memory=%.1fMB persistence=%s milestones=%d/%d",
  label,player.UserId,math.floor(os.clock()-session.Started),avg,percentile(samples,.95),session.MaxFrameMs,totalMemoryMb(),
  tostring(status.State),session.MilestoneCount,#MILESTONE_ORDER
 ))
 print(string.format(
  "[RuntimeProbe][Server] EVIDENCE_SUMMARY user=%d character=%s tutorial=%s multiplayer=%s players=%d",
  player.UserId,tostring(session.Evidence.Character),tostring(session.Evidence.TutorialProgress),tostring(session.Evidence.Multiplayer),#Players:GetPlayers()
 ))
end

local function start(player)
 if sessions[player] then return end
 local session={
  Started=os.clock(),
  Accum=0,
  Frames=0,
  MaxFrameMs=0,
  SecondFrameMs={},
  Milestones={},
  MilestoneCount=0,
  Evidence={Character=false,TutorialProgress=false,Multiplayer=false},
  CheckpointIndex=1,
 }
 sessions[player]=session

 task.spawn(function()
  while player.Parent==Players do
   if not session.Evidence.Character and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
    session.Evidence.Character=true
    print(string.format("[RuntimeProbe][Server] EVIDENCE user=%d name=CharacterSpawned elapsed=%.1fs",player.UserId,os.clock()-session.Started))
   end
   if not session.Evidence.Multiplayer and #Players:GetPlayers()>=2 then
    session.Evidence.Multiplayer=true
    print(string.format("[RuntimeProbe][Server] EVIDENCE user=%d name=Multiplayer2Plus elapsed=%.1fs players=%d",player.UserId,os.clock()-session.Started,#Players:GetPlayers()))
   end
   local profile=Data:GetProfile(player)
   if profile then
    if not session.Evidence.TutorialProgress and profile.Tutorial and (profile.Tutorial.Step or 1)>1 then
     session.Evidence.TutorialProgress=true
     print(string.format("[RuntimeProbe][Server] EVIDENCE user=%d name=TutorialProgress elapsed=%.1fs step=%d",player.UserId,os.clock()-session.Started,profile.Tutorial.Step))
    end
    local state=coreState(profile)
    for _,name in ipairs(MILESTONE_ORDER) do
     if state[name] and not session.Milestones[name] then
      session.Milestones[name]=true
      session.MilestoneCount+=1
      print(string.format("[RuntimeProbe][Server] MILESTONE user=%d name=%s elapsed=%.1fs",player.UserId,name,os.clock()-session.Started))
     end
    end
   end
   local checkpoint=REPORT_CHECKPOINTS[session.CheckpointIndex]
   if checkpoint and os.clock()-session.Started>=checkpoint then
    report(player,session,string.format("CHECKPOINT_%dm",math.floor(checkpoint/60)))
    session.CheckpointIndex+=1
   end
   task.wait(.5)
  end
 end)
end

RunService.Heartbeat:Connect(function(dt)
 local ms=dt*1000
 for player,session in pairs(sessions) do
  if player.Parent~=Players then continue end
  session.Accum+=dt
  session.Frames+=1
  session.MaxFrameMs=math.max(session.MaxFrameMs,ms)
  if session.Accum>=SAMPLE_SECONDS then
   local avgMs=session.Frames>0 and (session.Accum/session.Frames)*1000 or 0
   table.insert(session.SecondFrameMs,avgMs)
   if #session.SecondFrameMs>3600 then table.remove(session.SecondFrameMs,1) end
   session.Accum=0
   session.Frames=0
  end
 end
end)

Players.PlayerAdded:Connect(start)
Players.PlayerRemoving:Connect(function(player)
 local session=sessions[player]
 if not session then return end
 report(player,session,"LEAVE")
 sessions[player]=nil
end)

for _,player in ipairs(Players:GetPlayers()) do start(player) end

print("[RuntimeProbe][Server] Studio-only read-only probe active. Core milestones + server frame/memory checkpoints at 1/10/15/30/60 minutes.")
