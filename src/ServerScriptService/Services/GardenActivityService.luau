local RS=game:GetService("ReplicatedStorage") local A=require(RS.Config.ActivityConfig) local C=require(RS.Config.BloomConfig) local G=require(RS.Config.GardenSynergyConfig) local E=require(RS.Shared.WorkshopEffects) local Http=game:GetService("HttpService") local S={Offers={}}
function S:Init(x) self.X=x end
function S:Offer(player,kind,position,sector,bee,priority,tutorial)
 local p=self.X:Profile(player) local cfg=A.Types[kind] if not p or not cfg then return false end
 local offers=self.Offers[player] or {} self.Offers[player]=offers local count=0 for _ in pairs(offers) do count=count+1 end if count>=A.MaxVisible and not priority then return false end
 if kind=="Overcharge" and not bee then return false end
 local id=Http:GenerateGUID(false) local nodes={} local origin=self.X.GardenPlotService:HivePosition(player)
 if kind=="NectarBud" then
  local nearest=nil local distance=math.huge for i,s in ipairs(p.Garden.Slots) do if s.SpeciesId then local pos=self.X.GardenPlotService:Position(player,i) local d=(pos-position).Magnitude if d<distance then distance=d nearest=pos end end end
  if not nearest then return false end nodes[1]=nearest+Vector3.new(0,3,0)
 elseif kind=="CrossPollination" then for i=1,3 do if not p.Garden.Slots[i].SpeciesId then return false end nodes[i]=self.X.GardenPlotService:Position(player,i)+Vector3.new(0,3,0) end
 elseif kind=="SolarBloom" then
  local routeRadius=13
  for i=1,cfg.Steps do
   local angle=(i-1)*math.pi*2/cfg.Steps
   nodes[i]=position+Vector3.new(math.cos(angle)*routeRadius,3,math.sin(angle)*routeRadius)
  end
 else for i=1,cfg.Steps do local t=(i-1)/math.max(1,cfg.Steps-1) if kind=="PollenTrail" then nodes[i]=position:Lerp(origin,t)+Vector3.new(0,2+math.sin(t*math.pi)*2,0) else nodes[i]=position+Vector3.new(math.sin(i*1.8)*7,3,math.cos(i*1.8)*7) end end end
 offers[id]={Id=id,Kind=kind,Nodes=nodes,Index=1,Expires=workspace:GetServerTimeNow()+cfg.Life,Sector=sector,Bee=bee,Revision=p.Garden.Revision,Tutorial=tutorial==true}
 if kind=="BloomSurge" then self.X.Temp[player].Hotspot=position self.X.Temp[player].HotspotUntil=os.clock()+cfg.Life end
 self.X:Emit(player,"ActivityOffered",1) self:Push(player) return true,id
end
function S:HasTutorialOffer(player,kind)
 for _,o in pairs(self.Offers[player] or {}) do
  if o.Tutorial and (not kind or o.Kind==kind) and o.Expires>=workspace:GetServerTimeNow() then return true end
 end
 return false
end
function S:EnsureTutorialSpark(player)
 local p=self.X:Profile(player)
 if not p or self:HasTutorialOffer(player,"PollenSpark") then return false end
 local pos=self.X.GardenPlotService:Position(player,2) or self.X.GardenPlotService:HivePosition(player)
 if not pos then return false end
 return self:Offer(player,"PollenSpark",pos+Vector3.new(0,3,0),nil,nil,true,true)
end
function S:HasSectorOffer(player,sector)
 for _,o in pairs(self.Offers[player] or {}) do
  if o.Sector==sector and o.Expires>=workspace:GetServerTimeNow() then return true end
 end
 return false
end
function S:Push(player)
 local list={}
 for _,o in pairs(self.Offers[player] or {}) do
  local cfg=A.Types[o.Kind]
  table.insert(list,{
   Id=o.Id,
   Kind=o.Kind,
   Position=o.Nodes[o.Index],
   Index=o.Index,
   Count=#o.Nodes,
   Expires=o.Expires,
   CheckpointRadius=(cfg and cfg.CheckpointRadius) or A.CheckpointRadius,
   VerticalTolerance=A.CheckpointVerticalTolerance,
   Sector=o.Sector,
   Tutorial=o.Tutorial==true,
  })
 end
 self.X:Send(player,"Activities",list)
end
function S:Collect(player,id,index,phase)
 local offers=self.Offers[player] local o=offers and offers[id] local p=self.X:Profile(player) local cfg=o and A.Types[o.Kind]
 if not o or not p or not cfg or phase~="Reach" or o.Expires<workspace:GetServerTimeNow() or index~=o.Index then return false end
 if o.Sector and not p.World.UnlockedSectors[o.Sector] then return false end
 local checkpointRadius=cfg.CheckpointRadius or A.CheckpointRadius
 if not self.X.U.WithinCheckpoint(player,o.Nodes[o.Index],checkpointRadius,A.CheckpointVerticalTolerance) then return false end
 if not o.Engaged then o.Engaged=true self.X:Emit(player,"ActivityEngaged",1) end
 if o.Kind=="CrossPollination" and o.Revision~=p.Garden.Revision then offers[id]=nil self:Push(player) return false end
 o.Index=o.Index+1 if o.Kind=="FireflyRoute" then self.X:Emit(player,"Firefly",1) end
 if o.Index>#o.Nodes then offers[id]=nil local temp=self.X.Temp[player] local kind=o.Kind
  if not temp then warn("[Activity] missing runtime temp during completion kind="..tostring(kind).." player="..tostring(player.Name)) return false,"PROFILE_LOADING" end
  if kind=="DewDrop" then temp.Dew=math.min(A.DewMax,(temp.Dew or 0)+1)
  elseif kind=="NectarBud" then p.Currencies.Coins=p.Currencies.Coins+5
   local Flowers=require(RS.Config.FlowersConfig)
   for i,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId and (self.X.GardenPlotService:Position(player,i)-o.Nodes[1]).Magnitude<15 then local effect=Flowers.Species[slot.SpeciesId].PollinationEffect
    if effect=="NeighbourBoost" then temp.NeighbourUntil=os.clock()+20 elseif effect=="SwiftWindow" then temp.SwiftUntil=os.clock()+15 elseif effect=="LuckDew" then temp.Dew=math.min(A.DewMax,(temp.Dew or 0)+1) elseif effect=="CoinPod" then p.Currencies.Coins=p.Currencies.Coins+3 elseif effect=="Astral" then temp.Eclipse=true elseif effect=="Pulse" then self.X.GardenPlotService:AddFlowerXP(player,i,3) end
   end end if Random.new():NextNumber()<A.MutationChance then for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then slot.Mutation="Dewkissed" self.X:Emit(player,"Mutation",1) break end end end
  elseif kind=="CrossPollination" then temp.NeighbourUntil=os.clock()+20
  elseif kind=="Overcharge" then temp.OverchargeBee=o.Bee
  elseif kind=="CrystalResonance" then temp.Crystal=true temp.NeighbourUntil=os.clock()+30+E.Value(p,"EXPLORATION_3","CrystalSeconds",0) if p.Season.ActiveCard=="CrystalSeason" then temp.TemporaryMutationUntil=os.clock()+60 end
  elseif kind=="FireflyRoute" or kind=="ShadowBloom" then temp.Eclipse=true end
  self.X.RollService:Charge(player,A.Types[kind].Charge*E.Value(p,"BLOOM_2","ManualCharge",1)*(o.Sector and E.Value(p,"EXPLORATION_2","RouteCharge",1) or 1)*(p.Season.ActiveCard=="SummerSwarm" and 1.25 or 1))
  self.X.BoostService:ApplyActivity(player,kind)
  self.X:Emit(player,kind,1) self.X:Emit(player,"ActivityCompleted",1)
  local completedSector=o.Sector or self.X.MapService:Sector(player)
  if completedSector and completedSector~="Center" then self.X:Emit(player,"WorldActivity",1) end

  local socialOK,socialErr=xpcall(function() self.X.SocialService:Contribute(player,2) end,debug.traceback)
  if not socialOK then warn("[Bloom] Activity social reward error",kind,socialErr) end
  for _,bee in pairs(p.Pollinators.EquippedBeeSlots) do
   local masteryOK,masteryErr=xpcall(function() self.X.PollinatorService:AddMastery(player,bee,1,1) end,debug.traceback)
   if not masteryOK then warn("[Bloom] Activity mastery reward error",kind,bee,masteryErr) end
  end
 end
 local pushOK,pushErr=xpcall(function() self:Push(player) end,debug.traceback)
 if not pushOK then warn("[Bloom] Activity list push error",pushErr) end
 return true
end
function S:Tick(player)
 local changed=false local offers=self.Offers[player] or {}
 for id,o in pairs(offers) do if o.Expires<workspace:GetServerTimeNow() or not player.Character or not player.Character:FindFirstChildOfClass("Humanoid") or player.Character:FindFirstChildOfClass("Humanoid").Health<=0 then offers[id]=nil changed=true end end
 if changed then self:Push(player) end
end
function S:CancelGarden(player) self.Offers[player]={} self:Push(player) end
function S:Remove(player) self.Offers[player]=nil end
return S
