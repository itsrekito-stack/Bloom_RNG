local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BloomConfig) local S={Buckets={}}
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
 self.StateRequest.OnServerInvoke=function(player)
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
  if not self:Accept(player) or type(action)~="string" or #action>32 then return end
  if type(a)=="string" and #a>100 or type(b)=="string" and #b>100 or type(c)=="string" and #c>100 then return end
  if not self.X:Profile(player) then
   if action=="Ready" then self.X:Send(player,"Ack",{Action="Ready",OK=false,Reason="PROFILE_LOADING"}) end
   return
  end
  local ok,result,reason=pcall(function() return self.X:Request(player,action,a,b,c) end)
  if not ok then warn("[Bloom] Request error",action,result) end
  self.X:Send(player,"Ack",{Action=action,OK=ok and result~=false,Reason=ok and reason or "SERVER_ERROR"})
  self.X:Push(player)
 end)
end
function S:Remove(player) self.Buckets[player]=nil end
return S
