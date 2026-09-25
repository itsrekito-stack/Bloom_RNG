local RS=game:GetService("ReplicatedStorage") local A=require(RS.Config.ActivityConfig) local S={Blessed={},Progress=0,Contributions={},Round=0,NextEvent=0,Pulse=nil}
function S:Init(x) self.X=x self.NextEvent=os.clock()+A.EventInterval end
function S:Bless(visitor,owner)
 if visitor==owner or self.Blessed[visitor] then return false end local p=self.X:Profile(visitor) local target=self.X:Profile(owner) if not p or not target then return false end
 local pos=self.X.GardenPlotService:HivePosition(owner) if not pos or not self.X.U.Near(visitor,pos,14) then return false end
 self.Blessed[visitor]=true self.X.Temp[owner].BlessingUntil=os.clock()+60 self.X:Send(visitor,"Message","Blessing left") return true
end
function S:Contribute(player,amount)
 local flower=self.X.World:FindFirstChild("ServerBloom") local text=flower and flower:FindFirstChild("LevelText",true) if text then text.Text="SERVER BLOOM • "..math.floor(self.Progress).."/"..A.ServerBloomTarget end
 self.Progress=self.Progress+amount self.Contributions[player]=(self.Contributions[player] or 0)+amount
 if self.Progress>=A.ServerBloomTarget then self.Round=self.Round+1 for who,n in pairs(self.Contributions) do local p=self.X:Profile(who) if p and n>0 then p.Currencies.PetalDust=p.Currencies.PetalDust+2+math.min(8,math.floor(n/10)) self.X.RollService:Charge(who,15) p.World.EventStats.ServerBloom=(p.World.EventStats.ServerBloom or 0)+1 self.X:MarkStateDirty(who) self.X:Send(who,"Ceremony",{Kind="ServerBloom",Text="Server Bloom"}) end end self.Progress=0 self.Contributions={} end
end
function S:Tick()
 local now=os.clock() local changed=false
 if self.Pulse and now>=self.Pulse.Ends then self.Pulse=nil changed=true end
 if now>=self.NextEvent then local sectors={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"} self.Round=self.Round+1 self.Pulse={Sector=sectors[self.Round%3+1],Ends=now+A.PulseDuration} self.NextEvent=now+A.EventInterval changed=true end
 return changed
end
function S:IsEclipse(player) local temp=player and self.X.Temp[player] return self.Pulse and self.Pulse.Sector=="TwilightGrove" or temp and (temp.PersonalEclipseUntil or 0)>os.clock() end
function S:Remove(player) self.Blessed[player]=nil self.Contributions[player]=nil end
return S
