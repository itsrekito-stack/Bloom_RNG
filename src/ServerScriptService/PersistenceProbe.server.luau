local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end

local Players=game:GetService("Players")
local Data=require(script.Parent.Services.DataService)

local MOD=4294967296
local cache={}
local tracking={}

local function mix(hash,text)
 for i=1,#text do
  hash=(hash*33+string.byte(text,i))%MOD
 end
 return hash
end

local function feed(hash,value,seen)
 local kind=typeof(value)
 hash=mix(hash,kind)
 hash=mix(hash,":")
 if kind=="nil" then
  return mix(hash,";")
 elseif kind=="boolean" then
  return mix(hash,value and "1;" or "0;")
 elseif kind=="number" then
  return mix(hash,string.format("%.17g;",value))
 elseif kind=="string" then
  hash=mix(hash,tostring(#value))
  hash=mix(hash,":")
  hash=mix(hash,value)
  return mix(hash,";")
 elseif kind~="table" then
  return mix(hash,tostring(value)..";")
 end
 if seen[value] then return mix(hash,"<cycle>;") end
 seen[value]=true
 local keys={}
 for key in pairs(value) do table.insert(keys,key) end
 table.sort(keys,function(a,b)
  local ak=typeof(a)..":"..tostring(a)
  local bk=typeof(b)..":"..tostring(b)
  return ak<bk
 end)
 hash=mix(hash,"{")
 for _,key in ipairs(keys) do
  hash=feed(hash,key,seen)
  hash=feed(hash,value[key],seen)
 end
 hash=mix(hash,"};")
 seen[value]=nil
 return hash
end

local function digest(profile)
 return string.format("%08x",feed(5381,profile,{}))
end

local function capture(player)
 local profile=Data:GetProfile(player)
 if not profile then return nil end
 local value=digest(profile)
 cache[player.UserId]=value
 player:SetAttribute("BloomPersistenceDigest",value)
 return value
end

local function track(player)
 if tracking[player] then return end
 tracking[player]=true
 task.spawn(function()
  local joinedLogged=false
  while player.Parent==Players do
   local value=capture(player)
   if value and not joinedLogged then
    joinedLogged=true
    print(string.format("[PersistenceProbe] JOIN user=%d digest=%s",player.UserId,value))
   end
   task.wait(.25)
  end
  tracking[player]=nil
 end)
end

Players.PlayerAdded:Connect(track)
Players.PlayerRemoving:Connect(function(player)
 local value=capture(player) or cache[player.UserId]
 local status=Data:GetPersistenceStatus(player)
 print(string.format("[PersistenceProbe] LEAVE user=%d digest=%s state=%s",
  player.UserId,value or "UNAVAILABLE",tostring(status.State)))
 cache[player.UserId]=nil
 tracking[player]=nil
end)

for _,player in ipairs(Players:GetPlayers()) do track(player) end

print("[PersistenceProbe] Studio-only probe active. PASS requires previous LEAVE digest == next JOIN digest after rejoin.")
