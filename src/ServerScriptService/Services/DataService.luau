-- One persistence owner per user. A timed-out caller never starts a second writer.
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local Data = game:GetService("ServerScriptService"):WaitForChild("Data")
local Copy = require(RS.Shared.TableUtil).DeepCopy
local Config = require(Data.DataConfig)
local Schema = require(Data.ProfileSchema)
local Service = {}
local recordsByUserId = {}
local loaded = Instance.new("BindableEvent")
local store, started, shuttingDown, shutdownDeadline
local serverId = game.JobId ~= "" and game.JobId or "studio-" .. HttpService:GenerateGUID(false)

local function outcome(code, operation, pending)
 return {Code=code, Committed=code=="SUCCESS", Pending=pending==true,
  OperationId=operation and operation.Id, Attempts=operation and operation.Attempts or 0}
end
local function log(record, operation, code)
 warn(string.format("[DataService] operation=%s user=%s state=%s attempt=%d result=%s",
  operation and operation.Kind or "Lifecycle", tostring(record.Player.UserId), record.State,
  operation and operation.Attempts or 0, code))
end
local function setState(record, state)
 record.State=state
 record.Player:SetAttribute("BloomProfileState",state)
 record.Player:SetAttribute("BloomProfileLoaded",state=="Active" or state=="Saving")
end
local function kick(record, message)
 if record.Player.Parent==Players then record.Player:Kick(message) end
end
local function key(record) return Config.KeyPrefix..tostring(record.Player.UserId) end
local function session(record)
 return {ServerId=serverId,Token=record.Token,ExpiresAt=os.time()+Config.SessionLeaseSeconds}
end
local function normalize(value)
 if value==nil then return {Revision=0} end
 if type(value)~="table" then return nil end
 if value.Data~=nil then
  if type(value.Data)~="table" then return nil end
  return value
 end
 -- An envelope missing Data must never become a new default profile.
 if value.RecordVersion~=nil or value.Session~=nil then return nil end
 return {Revision=0,Data=value}
end
local function owns(record, stored)
 local s=stored.Session
 return type(s)=="table" and s.Token==record.Token and type(s.ExpiresAt)=="number" and s.ExpiresAt>os.time()
end
local function prepare(value)
 local ok, copy, valid, reason=pcall(function()
  local candidate=Copy(value)
  local yes, why=Schema.Prepare(candidate)
  return candidate,yes,why
 end)
 if not ok or not valid then return nil,reason or "INVALID_PROFILE" end
 return copy
end

-- UpdateAsync errors are conservatively UNKNOWN: an acknowledgement may be lost
-- after the write. Retries use the SAME id and immutable snapshot. The marker is
-- checked inside UpdateAsync, never with a cached GetAsync read.
local function attempt(record, operation)
 local observed, confirmed
 local ok, result=pcall(function()
  return store:UpdateAsync(key(record),function(value)
   observed=nil confirmed=nil -- callback may be replayed by UpdateAsync
   local current=normalize(value)
   if not current then observed="INVALID_PROFILE" return nil end
   if current.LastOperationId==operation.Id then
    if operation.Kind~="Release" and not owns(record,current) then
     observed="OWNERSHIP_LOST" return nil
    end
    observed="SUCCESS" confirmed=current
    return nil -- confirmation must not overwrite a newer owner's envelope
   end
   local snapshot=operation.Snapshot
   if operation.Kind=="Load" then
    local s=current.Session
    if type(s)=="table" and s.Token~=record.Token and type(s.ExpiresAt)=="number" and s.ExpiresAt>os.time() then
     observed="OWNERSHIP_LOST" return nil
    end
    snapshot=prepare(current.Data or Schema.CreateDefault())
    if not snapshot then observed="INVALID_PROFILE" return nil end
   elseif not owns(record,current) then
    observed="OWNERSHIP_LOST" return nil
   end
   local revision=current.Revision or 0
   if type(revision)~="number" or revision~=revision or math.abs(revision)==math.huge or revision<0 then
    observed="INVALID_PROFILE" return nil
   end
   return {RecordVersion=1,Revision=math.floor(revision)+1,UpdatedAt=os.time(),
    Session=operation.Kind~="Release" and session(record) or nil,
    LastOperationId=operation.Id,Data=snapshot}
  end)
 end)
 if not ok then return "UNKNOWN_OUTCOME" end
 if observed then return observed,confirmed end
 if type(result)=="table" and result.LastOperationId==operation.Id then return "SUCCESS",result end
 return "RETRYABLE_FAILURE"
end

local beginOperation, requestRelease
local function runOperation(record, operation)
 local code, stored="RETRYABLE_FAILURE",nil
 for i=1,Config.PersistenceAttempts do
  if shuttingDown and os.clock()>=shutdownDeadline then code="TIMEOUT" break end
  operation.Attempts=i
  code,stored=attempt(record,operation)
  if code=="SUCCESS" or code=="OWNERSHIP_LOST" or code=="INVALID_PROFILE" then break end
  if code=="UNKNOWN_OUTCOME" then operation.Uncertain=true end
  setState(record,"RetryPending")
  log(record,operation,code)
  if i<Config.PersistenceAttempts then
   local delay=math.min(Config.RetryBaseSeconds*2^(i-1),Config.RetryMaxSeconds)
   if shuttingDown then delay=math.min(delay,math.max(0,shutdownDeadline-os.clock())) end
   task.wait(delay)
  end
 end
 if code~="SUCCESS" and code~="OWNERSHIP_LOST" and operation.Uncertain then code="UNKNOWN_OUTCOME" end
 if code=="SUCCESS" then
  if operation.Kind=="Load" or operation.Kind=="Transaction" then record.Data=Copy(stored.Data) end
  record.LastSaveAt=os.time()
  record.LeaseExpires=stored.Session and stored.Session.ExpiresAt or 0
  if operation.Kind=="Release" then
   setState(record,"Released")
   -- The only removal of an acquired record is a confirmed final commit.
   if recordsByUserId[record.Player.UserId]==record then recordsByUserId[record.Player.UserId]=nil end
  else
   setState(record,record.CloseRequested and "Closing" or "Active")
  end
 else
  setState(record,code=="OWNERSHIP_LOST" and "Lost" or code=="UNKNOWN_OUTCOME" and "UnknownOutcome" or "RecoveryFailed")
  record.Player:SetAttribute("BloomProfileError",code)
  log(record,operation,code)
  kick(record,"Your data session could not be confirmed safely. Please rejoin shortly.")
 end
 operation.Result=outcome(code,operation)
 if code~="SUCCESS" then record.FailureResult=operation.Result end
 operation.Done=true
 record.Operation=nil
 record.LastOperation=operation -- retains the candidate on unknown/failure, never writes old memory
 if code=="SUCCESS" and operation.Kind~="Release" then
  if record.CloseRequested or shuttingDown or record.Player.Parent~=Players then
   requestRelease(record)
  elseif operation.Kind=="Load" then
   loaded:Fire(record.Player)
  end
 end
end
beginOperation=function(record, kind, snapshot, transactionId)
 local operation={Kind=kind,Id=HttpService:GenerateGUID(false),Snapshot=snapshot,Attempts=0}
 if transactionId then operation.Snapshot.LastTransactionId=transactionId end
 record.Operation=operation
 setState(record,kind=="Load" and "Loading" or kind=="Transaction" and "Transaction" or kind=="Release" and "Closing" or "Saving")
 task.spawn(function()
  local ok=pcall(runOperation,record,operation)
  if not ok then
   -- Internal failure after a possible write is just as unsafe as a lost response.
   setState(record,"UnknownOutcome")
   operation.Result=outcome("UNKNOWN_OUTCOME",operation)
   record.FailureResult=operation.Result
   operation.Done=true record.Operation=nil record.LastOperation=operation
   log(record,operation,"UNKNOWN_OUTCOME_INTERNAL")
   kick(record,"Your data session could not be confirmed safely. Please rejoin shortly.")
  end
 end)
 return operation
end
requestRelease=function(record)
 record.CloseRequested=true
 if record.Operation then return end -- its completion owns the final-save handoff
 if record.State=="Released" or record.State=="Lost" or record.State=="UnknownOutcome" or record.State=="RecoveryFailed" then return end
 setState(record,"Closing")
 local releaseData=record.StudioTransient and record.StudioOriginalData or record.Data
 local snapshot=prepare(releaseData)
 if not snapshot then
  setState(record,"RecoveryFailed")
  record.LastOperation={Kind="Release",Attempts=0,Result=outcome("INVALID_PROFILE")}
  record.FailureResult=record.LastOperation.Result
  log(record,record.LastOperation,"INVALID_PROFILE")
  return
 end
 beginOperation(record,"Release",snapshot)
end
local function awaitOperation(record, operation)
 local deadline=os.clock()+Config.OperationWaitSeconds
 while not operation.Done and os.clock()<deadline and (not shuttingDown or os.clock()<shutdownDeadline) do task.wait(.05) end
 if operation.Done then return operation.Result end
 log(record,operation,"TIMEOUT_IN_FLIGHT")
 return outcome("TIMEOUT",operation,true)
end
function Service:Init()
 store=DataStoreService:GetDataStore(Config.GetStoreName())
 print("[DataService] Store:",Config.GetStoreName())
end
function Service:LoadProfile(player)
 local existing=recordsByUserId[player.UserId]
 if existing then
  if existing.Player~=player then player:Kick("Your previous session is still closing. Please try another server shortly.") end
  return outcome("RETRYABLE_FAILURE",existing.Operation,existing.Operation~=nil)
 end
 if shuttingDown then return outcome("TIMEOUT") end
 local record={Player=player,State="Loading",Token=HttpService:GenerateGUID(false),LastSaveAt=0}
 recordsByUserId[player.UserId]=record
 player:SetAttribute("BloomProfileError",nil)
 local result=awaitOperation(record,beginOperation(record,"Load"))
 if result.Pending then
  record.CloseRequested=true
  kick(record,"Profile load is still pending. Please rejoin shortly.")
 end
 return result
end
function Service:GetProfile(player)
 local record=recordsByUserId[player.UserId]
 if not record or record.Player~=player or record.CloseRequested then return nil end
 if record.State~="Active" and record.State~="Saving" then return nil end
 if os.time()>=(record.LeaseExpires or 0) then
  record.CloseRequested=true
  if not record.Operation then setState(record,"Lost");record.FailureResult=outcome("OWNERSHIP_LOST") end
  log(record,record.Operation,"LEASE_EXPIRED")
  kick(record,"Your data session lease expired. Please rejoin shortly.")
  return nil
 end
 return record.Data
end
function Service:IsLoaded(player) return self:GetProfile(player)~=nil end
function Service:GetProfileLoadedSignal() return loaded.Event end
function Service:GetPersistenceStatus(player)
 local r=recordsByUserId[player.UserId]
 if not r or r.Player~=player then return {State="Released"} end
 return {State=r.State,Closing=r.CloseRequested==true,Operation=r.Operation and r.Operation.Kind,
  StudioTransient=r.StudioTransient==true,
  Result=r.FailureResult and r.FailureResult.Code or (r.LastOperation and r.LastOperation.Result and r.LastOperation.Result.Code)}
end
function Service:SaveProfile(player, releaseSession)
 if releaseSession then return self:ReleaseProfile(player) end
 local record=recordsByUserId[player.UserId]
 if not record or record.Player~=player or record.CloseRequested or record.State~="Active" or record.Operation then return outcome("RETRYABLE_FAILURE") end
 if record.StudioTransient then return {Code="SUCCESS",Committed=true,Pending=false,StudioTransient=true} end
 local snapshot=prepare(record.Data)
 if not snapshot then
  record.CloseRequested=true setState(record,"RecoveryFailed")
  record.FailureResult=outcome("INVALID_PROFILE")
  log(record,nil,"INVALID_PROFILE") kick(record,"Your profile needs recovery. Please rejoin safely.")
  return outcome("INVALID_PROFILE")
 end
 return awaitOperation(record,beginOperation(record,"Save",snapshot))
end
function Service:CommitProfile(player, candidate, transactionId)
 local record=recordsByUserId[player.UserId]
 if not record or record.Player~=player or record.CloseRequested or record.State~="Active" or record.Operation then return outcome("RETRYABLE_FAILURE") end
 if type(transactionId)~="string" or transactionId=="" then return outcome("INVALID_PROFILE") end
 local snapshot=prepare(candidate)
 if not snapshot then return outcome("INVALID_PROFILE") end
 if record.StudioTransient then
  record.Data=Copy(snapshot)
  return {Code="SUCCESS",Committed=true,Pending=false,StudioTransient=true}
 end
 local operation=beginOperation(record,"Transaction",snapshot,transactionId)
 local result=awaitOperation(record,operation)
 if result.Pending then
  -- Caller cannot safely resume gameplay even if the worker commits later.
  record.CloseRequested=true
  kick(record,"Season save is still pending. Please rejoin shortly.")
 end
 return result
end
function Service:BeginStudioTransientProfile(player)
 if not RunService:IsStudio() then return false,"NOT_STUDIO" end
 local record=recordsByUserId[player.UserId]
 if not record or record.Player~=player or record.CloseRequested or record.State~="Active" or record.Operation then return false,"PROFILE_LOADING" end
 if not record.StudioOriginalData then record.StudioOriginalData=Copy(record.Data) end
 local fresh=prepare(Schema.CreateDefault())
 if not fresh then return false,"INVALID_PROFILE" end
 record.Data=fresh
 record.StudioTransient=true
 player:SetAttribute("BloomStudioTransientProfile",true)
 print("[DataService] Studio transient fresh profile active for",player.Name,"— persistent profile will be restored on release")
 return true
end

function Service:ReleaseProfile(player)
 local record=recordsByUserId[player.UserId]
 if not record or record.Player~=player then return outcome("NO_PROFILE") end
 requestRelease(record)
 local deadline=os.clock()+Config.OperationWaitSeconds
 while record.Operation and os.clock()<deadline and (not shuttingDown or os.clock()<shutdownDeadline) do task.wait(.05) end
 if record.State=="Released" then return outcome("SUCCESS",record.LastOperation) end
 if record.Operation then return outcome("TIMEOUT",record.Operation,true) end
 return record.FailureResult or outcome("OWNERSHIP_LOST")
end
function Service:AutosaveLoop()
 while not shuttingDown do
  task.wait(Random.new():NextNumber(Config.AutosaveMinSeconds,Config.AutosaveMaxSeconds))
  if shuttingDown then break end
  for _,record in pairs(recordsByUserId) do
   if record.State=="Active" and not record.CloseRequested and not record.StudioTransient then task.spawn(function() self:SaveProfile(record.Player,false) end) end
  end
 end
end
function Service:Shutdown()
 if shuttingDown then return end
 shuttingDown=true shutdownDeadline=os.clock()+Config.ShutdownBudgetSeconds
 for _,record in pairs(recordsByUserId) do requestRelease(record) end
 while os.clock()<shutdownDeadline do
  local pending=false
  for _,record in pairs(recordsByUserId) do if record.Operation then pending=true break end end
  if not pending then break end
  task.wait(.05)
 end
 for _,record in pairs(recordsByUserId) do
  log(record,record.Operation or record.LastOperation,record.Operation and "SHUTDOWN_TIMEOUT_IN_FLIGHT" or "SHUTDOWN_UNRESOLVED")
 end
end
function Service:Start()
 if started then return end
 assert(store,"DataService was not initialized") started=true
 Players.PlayerAdded:Connect(function(player) task.spawn(function() self:LoadProfile(player) end) end)
 Players.PlayerRemoving:Connect(function(player) self:ReleaseProfile(player) end)
 for _,player in ipairs(Players:GetPlayers()) do task.spawn(function() self:LoadProfile(player) end) end
 task.spawn(function() self:AutosaveLoop() end)
 game:BindToClose(function() self:Shutdown() end)
end
return Service
