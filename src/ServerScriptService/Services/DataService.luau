--!strict
local Players =
game:GetService("Players")
local DataStoreService =
game:GetService("DataStoreService")
local HttpService =
game:GetService("HttpService")
local ReplicatedStorage =
game:GetService("ReplicatedStorage")
local ServerScriptService =
game:GetService("ServerScriptService")
local SharedFolder =
ReplicatedStorage:WaitForChild(
"Shared"
)
local DataFolder =
ServerScriptService:WaitForChild(
"Data"
)
local TableUtil =
require(
SharedFolder:WaitForChild(
"TableUtil"
)
)
local DataConfig =
require(
DataFolder:WaitForChild(
"DataConfig"
)
)
local ProfileSchema =
require(
DataFolder:WaitForChild(
"ProfileSchema"
)
)
local DataService = {}
local profileStore = nil
local recordsByUserId: {
[number]: any
} = {}
local saveLocks: {
[number]: boolean
} = {}
local profileLoadedEvent =
Instance.new("BindableEvent")
local randomGenerator =
Random.new()
local started = false
local shuttingDown =
false
local serverSessionToken =
HttpService:GenerateGUID(
false
)
local serverId =
game.JobId
if serverId == "" then
serverId =
"studio-"
.. HttpService:GenerateGUID(
false
)
end
local function getKey(
userId: number
): string
return DataConfig.KeyPrefix
.. tostring(userId)
end
local function getRetryDelay(
attempt: number
): number
return DataConfig.RetryBaseSeconds
* (
2 ^ (attempt - 1)
)
end
local function makeSession(
now: number
)
return {
ServerId =
serverId,
Token =
serverSessionToken,
ExpiresAt =
now
+ DataConfig.SessionLeaseSeconds,
}
end
local function normalizeStoredRecord(
stored
)
if type(stored)
== "table"
and type(stored.Data)
== "table"
then
return stored
end
if type(stored)
== "table"
then
return {
RecordVersion = 1,
Revision = 0,
UpdatedAt = 0,
Session = nil,
Data =
TableUtil.DeepCopy(
stored
),
}
end
return {
RecordVersion = 1,
Revision = 0,
UpdatedAt = 0,
Session = nil,
Data = nil,
}
end
function DataService:Init()
local storeName =
DataConfig.GetStoreName()
profileStore =
DataStoreService:GetDataStore(
storeName
)
print(
"[DataService] Store:",
storeName
)
print(
"[DataService] Server session:",
serverId
)
print(
"[DataService] Init complete"
)
end
function DataService:Start()
if started then
return
end
started =
true
assert(
profileStore ~= nil,
"DataService was not initialized"
)
Players.PlayerAdded:Connect(
function(player)
task.spawn(
function()
self:LoadProfile(
player
)
end
)
end
)
Players.PlayerRemoving:Connect(
function(player)
self:ReleaseProfile(
player
)
end
)
for _, player in ipairs(
Players:GetPlayers()
) do
task.spawn(
function()
self:LoadProfile(
player
)
end
)
end
task.spawn(
function()
self:AutosaveLoop()
end
)
game:BindToClose(
function()
self:Shutdown()
end
)
print(
"[DataService] Started"
)
end
function DataService:LoadProfile(
player: Player
)
local userId =
player.UserId
if recordsByUserId[
userId
] then
return
end
player:SetAttribute("BloomProfileState","Loading")
player:SetAttribute("BloomProfileLoaded",false)
player:SetAttribute("BloomProfileError",nil)
print("[DataService] Loading profile:",player.Name,userId)
local record = {
Player =
player,
State =
"Loading",
Data =
nil,
Cancelled =
false,
LastSaveAt =
0,
}
recordsByUserId[
userId
] = record
task.delay(8,function()
 if recordsByUserId[userId]==record and record.State=="Loading" and player.Parent==Players then
  warn("[DataService] Profile load still pending after 8s:",player.Name,userId)
 end
end)
local key =
getKey(
userId
)
local finalError:
string? = nil
for attempt = 1,
DataConfig.MaxRetries
do
local callbackFailure:
string? = nil
local success,
resultOrError =
pcall(
function()
return profileStore:UpdateAsync(
key,
function(
currentValue
)
local now =
os.time()
local stored =
normalizeStoredRecord(
currentValue
)
local session =
stored.Session
if type(session)
== "table"
then
local token =
session.Token
local expiresAt =
session.ExpiresAt
if typeof(token)
== "string"
and token
~= serverSessionToken
and typeof(
expiresAt
) == "number"
and expiresAt
> now
then
callbackFailure =
"SESSION_LOCKED"
return nil
end
end
local profile
if type(stored.Data)
== "table"
then
profile =
TableUtil.DeepCopy(
stored.Data
)
else
profile =
ProfileSchema.CreateDefault()
end
local prepared,
prepareError =
ProfileSchema.Prepare(
profile
)
if not prepared then
callbackFailure =
"INVALID_PROFILE: "
.. tostring(
prepareError
)
return nil
end
local oldRevision =
stored.Revision
if typeof(oldRevision)
~= "number"
then
oldRevision =
0
end
return {
RecordVersion =
1,
Revision =
math.floor(
oldRevision
) + 1,
UpdatedAt =
now,
Session =
makeSession(
now
),
Data =
profile,
}
end
)
end
)
if success then
local storedRecord =
resultOrError
if type(storedRecord)
== "table"
and type(
storedRecord.Session
) == "table"
and storedRecord.Session.Token
== serverSessionToken
and type(
storedRecord.Data
) == "table"
then
record.Data =
storedRecord.Data
record.State =
"Active"
record.LastSaveAt =
os.time()
player:SetAttribute("BloomProfileState","Active")
player:SetAttribute("BloomProfileLoaded",true)
print(
"[DataService] Profile loaded:",
player.Name
)
if record.Cancelled
or player.Parent
~= Players
then
self:ReleaseProfile(
player
)
return
end
profileLoadedEvent:Fire(
player
)
return
end
finalError =
callbackFailure
or "LOAD_CANCELLED"
if finalError
== "SESSION_LOCKED"
then
break
end
if string.find(
finalError,
"INVALID_PROFILE",
1,
true
) then
break
end
else
finalError =
tostring(
resultOrError
)
end
if attempt
< DataConfig.MaxRetries
then
task.wait(
getRetryDelay(
attempt
)
)
end
end
recordsByUserId[
userId
] = nil
player:SetAttribute("BloomProfileState","Failed")
player:SetAttribute("BloomProfileLoaded",false)
player:SetAttribute("BloomProfileError",tostring(finalError or "UNKNOWN"))
warn(
"[DataService] Failed to load profile:",
player.Name,
finalError
)
if player.Parent
== Players
then
if finalError
== "SESSION_LOCKED"
then
player:Kick(
"Your profile is already active on another server. Please try again shortly."
)
else
player:Kick(
"Your data could not be loaded safely. Please rejoin."
)
end
end
end
function DataService:SaveProfile(
player: Player,
releaseSession: boolean
): boolean
local userId =
player.UserId
local record =
recordsByUserId[
userId
]
if not record then
return false
end
if record.State ~= "Active"
and record.State ~= "Closing"
then
return false
end
if saveLocks[
userId
] then
if not releaseSession then
return false
end
local deadline =
os.clock() + 10
while saveLocks[
userId
]
and os.clock()
< deadline
do
task.wait(
0.05
)
end
if saveLocks[
userId
] then
warn(
"[DataService] Save lock timeout:",
player.Name
)
return false
end
end
saveLocks[
userId
] = true
local snapshot =
TableUtil.DeepCopy(
record.Data
)
local valid,
validationError =
ProfileSchema.Prepare(
snapshot
)
if not valid then
saveLocks[
userId
] = nil
warn(
"[DataService] Refusing to save invalid profile:",
player.Name,
validationError
)
return false
end
local key =
getKey(
userId
)
local lostOwnership =
false
local finalError:
string? = nil
for attempt = 1,
DataConfig.MaxRetries
do
local success,
resultOrError =
pcall(
function()
return profileStore:UpdateAsync(
key,
function(
currentValue
)
local stored =
normalizeStoredRecord(
currentValue
)
local session =
stored.Session
if type(session)
~= "table"
or session.Token
~= serverSessionToken
then
lostOwnership =
true
return nil
end
local now =
os.time()
local revision =
stored.Revision
if typeof(revision)
~= "number"
then
revision =
0
end
return {
RecordVersion =
1,
Revision =
math.floor(
revision
) + 1,
UpdatedAt =
now,
Session =
if releaseSession
then nil
else makeSession(
now
),
Data =
snapshot,
}
end
)
end
)
if success then
if lostOwnership then
finalError =
"SESSION_OWNERSHIP_LOST"
break
end
if type(
resultOrError
) == "table"
then
record.LastSaveAt =
os.time()
saveLocks[
userId
] = nil
print(
"[DataService] Saved:",
player.Name,
releaseSession
and "(released)"
or ""
)
return true
end
finalError =
"SAVE_CANCELLED"
else
finalError =
tostring(
resultOrError
)
end
if attempt
< DataConfig.MaxRetries
and not lostOwnership
then
task.wait(
getRetryDelay(
attempt
)
)
end
end
saveLocks[
userId
] = nil
if lostOwnership then
record.State =
"Lost"
warn(
"[DataService] Session ownership lost:",
player.Name
)
if player.Parent
== Players
then
player:Kick(
"Your data session changed unexpectedly. Please rejoin."
)
end
else
warn(
"[DataService] Save failed:",
player.Name,
finalError
)
end
return false
end
function DataService:ReleaseProfile(
player: Player
)
local userId =
player.UserId
local record =
recordsByUserId[
userId
]
if not record then
return
end
if record.State=="Transaction" then
 local deadline=os.clock()+20
 while record.State=="Transaction" and os.clock()<deadline do task.wait(.05) end
 if record.State=="Transaction" then return end
 self:ReleaseProfile(player) return
end
if record.State
== "Closing"
then
local deadline =
os.clock() + 12
while recordsByUserId[
userId
] == record
and os.clock()
< deadline
do
task.wait(
0.05
)
end
return
end
if record.State
== "Loading"
then
record.Cancelled =
true
local deadline =
os.clock() + 12
while recordsByUserId[
userId
] == record
and record.State
== "Loading"
and os.clock()
< deadline
do
task.wait(
0.05
)
end
local updatedRecord =
recordsByUserId[
userId
]
if updatedRecord
and updatedRecord.State
== "Active"
then
self:ReleaseProfile(
player
)
end
return
end
if record.State
== "Lost"
then
recordsByUserId[
userId
] = nil
return
end
record.State =
"Closing"
local saved =
self:SaveProfile(
player,
true
)
if not saved then
warn(
"[DataService] Final save failed:",
player.Name
)
end
recordsByUserId[
userId
] = nil
saveLocks[
userId
] = nil
print(
"[DataService] Profile released:",
player.Name
)
end
function DataService:AutosaveLoop()
while started
and not shuttingDown
do
local waitTime =
randomGenerator:NextNumber(
DataConfig.AutosaveMinSeconds,
DataConfig.AutosaveMaxSeconds
)
task.wait(
waitTime
)
if shuttingDown then
break
end
for _, record in pairs(
recordsByUserId
) do
if record.State
~= "Active"
then
continue
end
local player =
record.Player
if not player then
continue
end
task.spawn(
function()
self:SaveProfile(
player,
false
)
end
)
end
end
end
function DataService:Shutdown()
if shuttingDown then
return
end
shuttingDown =
true
print(
"[DataService] Server shutting down..."
)
local remaining =
0
for _, record in pairs(
recordsByUserId
) do
local player =
record.Player
if player then
remaining += 1
task.spawn(
function()
self:ReleaseProfile(
player
)
remaining -= 1
end
)
end
end
local deadline =
os.clock() + 25
while remaining > 0
and os.clock()
< deadline
do
task.wait(
0.1
)
end
print(
"[DataService] Shutdown finished"
)
end
function DataService:GetProfile(
player: Player
)
local record =
recordsByUserId[
player.UserId
]
if not record then
return nil
end
if record.State
~= "Active"
then
return nil
end
return record.Data
end
function DataService:IsLoaded(
player: Player
): boolean
local record =
recordsByUserId[
player.UserId
]
return record ~= nil
and record.State
== "Active"
end
function DataService:GetProfileLoadedSignal():
RBXScriptSignal
return profileLoadedEvent.Event
end
function DataService:CommitProfile(player, candidate, transactionId)
 local userId=player.UserId local record=recordsByUserId[userId]
 if not record or record.State~="Active" or saveLocks[userId] then return false end
 local snapshot=TableUtil.DeepCopy(candidate) local valid=ProfileSchema.Prepare(snapshot) if not valid then return false end
 snapshot.LastTransactionId=transactionId saveLocks[userId]=true record.State="Transaction"
 for attempt=1,DataConfig.MaxRetries do
  local ok,result=pcall(function() return profileStore:UpdateAsync(getKey(userId),function(value)
   local stored=normalizeStoredRecord(value)
   if type(stored.Session)~="table" or stored.Session.Token~=serverSessionToken then return nil end
   if stored.Data and stored.Data.LastTransactionId==transactionId then return stored end
   return {RecordVersion=1,Revision=(stored.Revision or 0)+1,UpdatedAt=os.time(),Session=makeSession(os.time()),Data=snapshot}
  end) end)
  if ok and type(result)=="table" and result.Data and result.Data.LastTransactionId==transactionId then
   record.Data=TableUtil.DeepCopy(result.Data) record.State="Active" record.LastSaveAt=os.time() saveLocks[userId]=nil return true
  end
  if attempt<DataConfig.MaxRetries then task.wait(getRetryDelay(attempt)) end
 end
 -- Unknown durable outcome: never overwrite the store with the pre-turn snapshot.
 record.State="Lost" saveLocks[userId]=nil player:Kick("Season save could not be confirmed. Please rejoin safely.") return false
end
return DataService
