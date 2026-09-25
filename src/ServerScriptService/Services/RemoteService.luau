local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local S={Buckets={},StateRequests={}}
local NO_ARGS={Ready=true,Respec=true,Skip=true,Replay=true,StudioTutorialReset=true,SeasonCancel=true,DistillNectar=true}
local ACTIVITY_PHASE={Reach=true}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)~=math.huge end
local function integer(v,min,max) return finite(v) and v%1==0 and v>=min and v<=max end
local function short(v,max,allowEmpty) return type(v)=="string" and #v<=max and (allowEmpty or #v>0) end
local function scalar(v) local t=type(v) return v==nil or t=="string" or t=="number" or t=="boolean" end
local function errorId(player)
 S.ErrorSerial=(S.ErrorSerial or 0)+1
 return tostring(player and player.UserId or 0).."-"..tostring(S.ErrorSerial)
end
local function argText(v)
 return type(v)..":"..tostring(v)
end
function S:Validate(action,a,b,c)
 if NO_ARGS[action] then return a==nil and b==nil and c==nil,a==nil and b==nil and c==nil and nil or"INVALID_VALUE" end
 if not scalar(a) or not scalar(b) or not scalar(c) then return false,"INVALID_VALUE" end
 if action=="Roll" then
  if a~=nil and type(a)~="boolean" then return false,"INVALID_VALUE" end
  if b~=nil and not integer(b,1,2147483647) then return false,"INVALID_VALUE" end
  if c~=nil then return false,"INVALID_VALUE" end
  return true
 elseif action=="Plant" then
  return integer(a,1,C.MaxFlowerSlots) and short(b,64,true) and c==nil,(integer(a,1,C.MaxFlowerSlots) and short(b,64,true) and c==nil) and nil or"INVALID_VALUE"
 elseif action=="EquipBee" then
  local idOK=a==nil or short(a,64,true)
  return idOK and integer(b,1,C.MaxBeeSlots) and c==nil,(idOK and integer(b,1,C.MaxBeeSlots) and c==nil) and nil or"INVALID_VALUE"
 elseif action=="Dissolve" or action=="DissolveBee" then
  return short(a,64,false) and integer(b,1,10000) and c==nil,(short(a,64,false) and integer(b,1,10000) and c==nil) and nil or"INVALID_VALUE"
 elseif action=="FlowerUpgrade" or action=="WorkshopBuy" or action=="Trial" or action=="SeasonConfirm" or action=="Card" or action=="DissolveFilter" then
  return short(a,64,false) and b==nil and c==nil,(short(a,64,false) and b==nil and c==nil) and nil or"INVALID_VALUE"
 elseif action=="Flag" then
  return short(a,64,false) and short(b,32,false) and c==nil,(short(a,64,false) and short(b,32,false) and c==nil) and nil or"INVALID_VALUE"
 elseif action=="Activity" then
  return short(a,64,false) and integer(b,1,32) and type(c)=="string" and ACTIVITY_PHASE[c]==true,(short(a,64,false) and integer(b,1,32) and type(c)=="string" and ACTIVITY_PHASE[c]==true) and nil or"INVALID_VALUE"
 elseif action=="Keepsake" then
  return short(a,16,false) and short(b,64,false) and c==nil,(short(a,16,false) and short(b,64,false) and c==nil) and nil or"INVALID_VALUE"
 elseif action=="Menu" then
  local menuOK=a==false or short(a,32,false)
  return menuOK and b==nil and c==nil,(menuOK and b==nil and c==nil) and nil or"INVALID_VALUE"
 elseif action=="Setting" then
  local valueOK=type(b)=="boolean" or finite(b)
  return short(a,32,false) and valueOK and c==nil,(short(a,32,false) and valueOK and c==nil) and nil or"INVALID_VALUE"
 end
 return false,"INVALID_ACTION"
end
function S:Init(x)
 self.X=x
 local old=RS:FindFirstChild("BloomRemotes") if old then old:Destroy() end
 local folder=Instance.new("Folder") folder.Name="BloomRemotes" folder.Parent=RS
 local request=Instance.new("RemoteEvent") request.Name="Request" request.Parent=folder
 local event=Instance.new("RemoteEvent") event.Name="Event" event.Parent=folder
 local stateRequest=Instance.new("RemoteFunction") stateRequest.Name="StateRequest" stateRequest.Parent=folder
 self.Request=request self.Event=event self.StateRequest=stateRequest
end
function S:Accept(player)
 local now=os.clock() local b=self.Buckets[player] or {Time=now,Tokens=C.RemoteBurst} self.Buckets[player]=b b.Tokens=math.min(C.RemoteBurst,b.Tokens+(now-b.Time)*C.RemoteRate) b.Time=now if b.Tokens<1 then return false end b.Tokens=b.Tokens-1 return true
end
function S:Start()
 print("[RemoteService] State sync ready: state-sync-v5-revision-coalesced-2026-09-25")
 self.StateRequest.OnServerInvoke=function(player,knownRevision)
  if knownRevision~=nil and not integer(knownRevision,0,2147483647) then return nil,"INVALID_VALUE" end
  local now=os.clock() local last=self.StateRequests[player] or -100
  if now-last<.4 then return nil,"RATE_LIMITED" end
  self.StateRequests[player]=now
  if not self.X:Profile(player) then return nil,"PROFILE_LOADING" end
  if type(knownRevision)=="number" and knownRevision==self.X:StateRevision(player) then return nil,"NOT_MODIFIED",knownRevision end
  local ok,state=xpcall(function() return self.X:Snapshot(player) end,debug.traceback)
  if not ok then
   local id=errorId(player)
   warn("[Bloom][SERVER_ERROR]["..id.."] StateRequest player="..tostring(player.Name).."\n"..tostring(state))
   return nil,"SERVER_ERROR["..id.."]"
  end
  if not state then return nil,"PROFILE_LOADING" end
  return state,nil
 end
 self.Request.OnServerEvent:Connect(function(player,action,a,b,c)
  if type(action)~="string" or #action>32 then return end
  local rollRequestId=nil
  if action=="Roll" and type(b)=="number" and b%1==0 and b>=1 and b<=2147483647 then rollRequestId=b end
  if not self:Accept(player) then
   self.X:Send(player,"Ack",{Action=action,RequestId=rollRequestId,OK=false,Reason="RATE_LIMITED",Message=self.X.UIStateService:ReasonText("RATE_LIMITED")})
   return
  end
  local valid,validationReason=self:Validate(action,a,b,c)
  if not valid then
   self.X:Send(player,"Ack",{Action=action,RequestId=rollRequestId,OK=false,Reason=validationReason,Message=self.X.UIStateService:ReasonText(validationReason)})
   return
  end
  if not self.X:Profile(player) then
   if action=="Ready" then self.X:Send(player,"Ack",{Action="Ready",OK=false,Reason="PROFILE_LOADING"}) end
   return
  end
  local ok,result,reason=xpcall(function() return self.X:Request(player,action,a,b,c) end,debug.traceback)
  local requestErrorId=nil
  if not ok then
   requestErrorId=errorId(player)
   warn("[Bloom][SERVER_ERROR]["..requestErrorId.."] player="..tostring(player.Name).." userId="..tostring(player.UserId).." action="..tostring(action).." a="..argText(a).." b="..argText(b).." c="..argText(c).."\n"..tostring(result))
  end
  local success=ok and result~=false
  local finalReason=ok and reason or "SERVER_ERROR"
  if success and self.X:ActionMutatesState(action) then self.X:MarkStateDirty(player) end
  local message
  if success then
   message=nil
  elseif requestErrorId then
   message="Server error ["..requestErrorId.."] — see Output"
  else
   message=self.X.UIStateService:ReasonText(finalReason)
  end
  self.X:Send(player,"Ack",{Action=action,RequestId=rollRequestId,OK=success,Reason=finalReason,Message=message})
  if success then self.X:Push(player) end
 end)
end
function S:Remove(player) self.Buckets[player]=nil self.StateRequests[player]=nil end
return S
