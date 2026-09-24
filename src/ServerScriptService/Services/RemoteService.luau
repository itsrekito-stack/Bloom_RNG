local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local S={Buckets={},StateRequests={}}
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
 print("[RemoteService] State sync ready: state-sync-v4-ui-backend-2026-09-25")
 self.StateRequest.OnServerInvoke=function(player)
  local now=os.clock() local last=self.StateRequests[player] or -100
  if now-last<.4 then return nil,"RATE_LIMITED" end
  self.StateRequests[player]=now
  if not self.X:Profile(player) then return nil,"PROFILE_LOADING" end
  local ok,state=pcall(function() return self.X:Snapshot(player) end)
  if not ok then
   warn("[Bloom] StateRequest error",player.Name,state)
   return nil,"SERVER_ERROR"
  end
  if not state then return nil,"PROFILE_LOADING" end
  return state,nil
 end
 self.Request.OnServerEvent:Connect(function(player,action,a,b,c)
  if type(action)~="string" or #action>32 then return end
  if not self:Accept(player) then
   self.X:Send(player,"Ack",{Action=action,OK=false,Reason="RATE_LIMITED",Message=self.X.UIStateService:ReasonText("RATE_LIMITED")})
   return
  end
  if type(a)=="string" and #a>100 or type(b)=="string" and #b>100 or type(c)=="string" and #c>100 then
   self.X:Send(player,"Ack",{Action=action,OK=false,Reason="INVALID_VALUE",Message=self.X.UIStateService:ReasonText("INVALID_VALUE")})
   return
  end
  if not self.X:Profile(player) then
   if action=="Ready" then self.X:Send(player,"Ack",{Action="Ready",OK=false,Reason="PROFILE_LOADING"}) end
   return
  end
  local ok,result,reason=pcall(function() return self.X:Request(player,action,a,b,c) end)
  if not ok then warn("[Bloom] Request error",action,result) end
  local finalReason=ok and reason or "SERVER_ERROR"
  self.X:Send(player,"Ack",{Action=action,OK=ok and result~=false,Reason=finalReason,Message=(ok and result~=false) and nil or self.X.UIStateService:ReasonText(finalReason)})
  self.X:Push(player)
 end)
end
function S:Remove(player) self.Buckets[player]=nil self.StateRequests[player]=nil end
return S
