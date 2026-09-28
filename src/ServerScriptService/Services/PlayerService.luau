local RS=game:GetService("ReplicatedStorage") local Players=game:GetService("Players") local U=require(RS.Shared.BloomUtil) local C=require(RS.Config.BloomConfig) local T=require(RS.Config.TutorialConfig) local L=require(RS.Config.LocationsConfig) local DefaultSettings=require(game:GetService("ServerScriptService").Data.DefaultProfile).Settings
local X={Temp={},Revisions={},StateRevisions={},LastPushedStateRevision={},Connections={},ClientReadyConnections={},U=U}
local VALID_KEYBINDS={} for _,item in ipairs(Enum.KeyCode:GetEnumItems()) do VALID_KEYBINDS[item.Name]=true end
local STATE_NEUTRAL={Ready=true,Menu=true,Replay=true,SeasonCancel=true,SaveSettings=true}
function X:StateRevision(player) return self.StateRevisions[player] or 0 end
function X:MarkStateDirty(player)
 if not self.Temp[player] then return end
 self.StateRevisions[player]=(self.StateRevisions[player] or 0)+1
end
function X:ActionMutatesState(action) return STATE_NEUTRAL[action]~=true end
function X:Profile(player) return self.DataService:GetProfile(player) end
function X:Send(player,kind,payload) if player.Parent==Players then self.RemoteService.Event:FireClient(player,kind,payload) end end
function X:Broadcast(kind,payload) for _,p in ipairs(Players:GetPlayers()) do self:Send(p,kind,payload) end end
function X:Emit(player,event,n)
 local p=self:Profile(player) if not p then return end
 local amount=n or 1
 p.Tutorial.Events[event]=(p.Tutorial.Events[event] or 0)+amount
 self.Revisions[player]=(self.Revisions[player] or 0)+1
 self:MarkStateDirty(player)
 self.TutorialService:RecordEvent(player,event)

 -- Tutorial progression is core state and must commit before optional telemetry/trial hooks.
 local tutorialOK,tutorialErr=xpcall(function() self.TutorialService:Refresh(player) end,debug.traceback)
 if not tutorialOK then
  local activeTutorial=T.Steps[p.Tutorial.Step]~=nil
  warn("[Bloom][TUTORIAL_HOOK_ERROR] event="..tostring(event).." step="..tostring(p.Tutorial.Step).." player="..tostring(player.Name).."\n"..tostring(tutorialErr))
  if activeTutorial then error(tutorialErr) end
 end
 if event=="ActivityCompleted" then self:Send(player,"TokenCollected",true) end

 local analyticsOK,analyticsErr=xpcall(function() self.AnalyticsService:Event(player,event,amount) end,debug.traceback)
 if not analyticsOK then warn("[Bloom] Analytics hook error",event,analyticsErr) end

 if event~="Trial" then
  local trialOK,trialErr=xpcall(function() self.BuildTrialService:Event(player,event,amount) end,debug.traceback)
  if not trialOK then warn("[Bloom] Trial hook error",event,trialErr) end
 end
end
function X:EmitOnce(player,event) local p=self:Profile(player) if p and not p.Tutorial.Events[event] then self:Emit(player,event,1) end end
function X:Part(parent,name,pos,size,color,collide)
 local part=Instance.new("Part") part.Name=name part.Anchored=true part.Size=size part.Position=pos part.Color=color part.CanCollide=collide part.CanTouch=false part.Material=Enum.Material.SmoothPlastic part.Parent=parent return part
end
function X:Prompt(part,text,callback)
 local prompt=Instance.new("ProximityPrompt") prompt.ActionText=text prompt.ObjectText=part.Name prompt.RequiresLineOfSight=false prompt.MaxActivationDistance=12 prompt.Parent=part
 prompt.Triggered:Connect(function(player) if self:Profile(player) and U.Near(player,part.Position,C.InteractionDistance) and self.RemoteService:Accept(player) then local changed=callback(player) if changed~=false then self:MarkStateDirty(player) end self:Push(player) end end) return prompt
end
function X:Snapshot(player)
 local p=self:Profile(player) if not p then return nil end
 self.TutorialService:Refresh(player)
 local uiState=self.UIStateService:Snapshot(player)
 local public={Revision=self:StateRevision(player),Profile=U.Copy(p),Synergies=self.GardenSynergyService.Active[player] or {},BeeCapacity=self.StatsService:BeeCapacity(p),HivePosition=self.GardenPlotService:HivePosition(player),Trial=uiState and uiState.Trials and uiState.Trials.Active or nil,ServerBloom=self.SocialService.Progress,Pulse=self.SocialService.Pulse,Cards=self.SeasonService:Offers(p),Odds=self.RollService:Odds(player),UI=uiState}
 public.Profile.LegacyArchive=nil public.Profile.Telemetry=nil public.Profile.Migrations=nil
 return public
end
function X:Push(player,force)
 local revision=self:StateRevision(player)
 if not force and self.LastPushedStateRevision[player]==revision then return false end
 local public=self:Snapshot(player) if not public then return false end
 self.LastPushedStateRevision[player]=public.Revision
 self:Send(player,"State",public)
 local p=public.Profile
 local leader=player:FindFirstChild("leaderstats") if leader then leader.Coins.Value=math.floor(p.Currencies.Coins) leader.Hive.Value=p.Hive.Level end
 return true
end
function X:ResetStudioTutorial(player)
 local ok,reason=self.DataService:BeginStudioTransientProfile(player)
 if not ok then return false,reason end

 self.SeasonService:Remove(player)
 self.BuildTrialService:Remove(player)
 self.GardenActivityService:Remove(player)
 self.PollinatorService:Remove(player)
 self.RollService:Remove(player)
 self.GardenSynergyService:Remove(player)
 self.TutorialService:Remove(player)
 self.GardenPlotService:Remove(player)

 self.Temp[player]={}
 self.LastPushedStateRevision[player]=-1
 self.GardenPlotService:Build(player)
 self.GardenActivityService:Push(player)
 self:Send(player,"Bees",{})
 self:MarkStateDirty(player)

 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local hive=self.GardenPlotService:HivePosition(player)
 if root and hive then root.CFrame=CFrame.new(hive+Vector3.new(0,4,8)) end

 print("[Tutorial] Studio fresh-start profile activated player="..tostring(player.Name))
 self:Send(player,"Message","Studio tutorial test started • session progress will not be saved")
 return true
end

local function validKeybind(value)
 return type(value)=="string" and #value>0 and #value<=16 and value~="Unknown" and value~="Escape" and VALID_KEYBINDS[value]==true
end
function X:Request(player,action,a,b,c)
 local p=self:Profile(player) if not p then return false,"PROFILE_LOADING" end
 if action=="SeasonCancel" then self.SeasonService.Pending[player]=nil return true end
 if self.SeasonService.Pending[player] and action~="SeasonConfirm" and action~="Menu" and action~="Ready" then return false,"SEASON_PREVIEW_OPEN" end
 if action=="Ready" then self.GardenActivityService:Push(player) return true
 elseif action=="Roll" then return self.RollService:Roll(player,a==true,b)
 elseif action=="Plant" then return self.GardenPlotService:Plant(player,a,b)
 elseif action=="EquipBee" then return self.InventoryService:EquipBee(player,a,b)
 elseif action=="Dissolve" then
  if not p.Tutorial.FeatureUnlocks.SeedSatchel then return false,"LOCKED" end
  return self.InventoryService:Dissolve(player,a,b)
 elseif action=="DissolveBee" then
  if not p.Tutorial.FeatureUnlocks.SeedSatchel then return false,"LOCKED" end
  return self.InventoryService:DissolveBee(player,a,b)
 elseif action=="FlowerUpgrade" then
  if not p.Tutorial.FeatureUnlocks.SeedSatchel then return false,"LOCKED" end
  return self.FlowerProgressionService:Upgrade(player,a)
 elseif action=="Flag" then
  if not p.Tutorial.FeatureUnlocks.SeedSatchel then return false,"LOCKED" end
  if not p.FlowerCollection.DiscoveredFlowers[a] then return false,"NOT_DISCOVERED" end
  if b~="LockedFlowers" and b~="FavoriteFlowers" then return false,"INVALID_ACTION" end
  p.FlowerCollection[b][a]=not p.FlowerCollection[b][a]
  return true
 elseif action=="Activity" then return self.GardenActivityService:Collect(player,a,b,c)
 elseif action=="WorkshopBuy" then return self.WorkshopService:Buy(player,a)
 elseif action=="Trial" then return self.BuildTrialService:StartTrial(player,a)
 elseif action=="SeasonConfirm" then return self.SeasonService:Confirm(player,a)
 elseif action=="Card" then return self.SeasonService:Card(player,a)
 elseif action=="Keepsake" then return self.SeasonService:Keepsake(player,a,b)
 elseif action=="DistillNectar" then return self.SeasonService:DistillNectar(player)
 elseif action=="Skip" then self.TutorialService:Skip(player) return true
 elseif action=="Replay" then self.TutorialService:Replay(player) return true
 elseif action=="StudioTutorialReset" then return self:ResetStudioTutorial(player)
 elseif action=="IndexViewed" then return self.UIStateService:MarkIndexRead(p,a,b)
 elseif action=="SaveSettings" then
  local result=self.DataService:SaveProfile(player,false)
  if result and result.Committed then
   self:Send(player,"Message","Settings saved")
   return true
  end
  if result and result.Code=="RETRYABLE_FAILURE" then return false,"PERSISTENCE_BUSY" end
  return false,"PERSISTENCE_UNCONFIRMED"
 elseif action=="ResetSettings" then
  p.Settings=U.Copy(DefaultSettings)
  return true
 elseif action=="Menu" then
  if a==false then
   local closing=self.Temp[player].MenuName
   self.Temp[player].MenuOpen=false
   self.Temp[player].MenuName=nil
   local tutorialStep=T.Steps[p.Tutorial.Step]
   if closing=="SeedSatchel" and tutorialStep and tutorialStep.Id=="InventoryExplain" then self:Emit(player,"InventoryReviewed",1) end
   return true
  end
  if type(a)~="string" then return false,"INVALID_ACTION" end
  if a~="Settings" and not p.Tutorial.FeatureUnlocks[a] then return false,"LOCKED" end
  self.Temp[player].MenuOpen=true
  self.Temp[player].MenuName=a
  if a=="SeedSatchel" then self:Emit(player,"SatchelOpen",1) end
  return true
 elseif action=="Setting" then
  local numericLimits={
   TokenSoundVolume={0,1},
   MusicVolume={0,1},
   SFXVolume={0,1},
   UIScale={.8,1.15},
   EffectiveLuck={0,1000000},
  }
  local limits=numericLimits[a]
  if limits then
   if type(b)~="number" or b~=b or math.abs(b)==math.huge then return false,"INVALID_VALUE" end
   if a=="EffectiveLuck" and b~=0 and b<1 then return false,"INVALID_VALUE" end
   p.Settings[a]=math.clamp(b,limits[1],limits[2])
   if a=="SFXVolume" then p.Settings.TokenSoundVolume=p.Settings[a] end
   if a=="TokenSoundVolume" then p.Settings.SFXVolume=p.Settings[a] end
   return true
  end
  if a=="Language" then
   if b~="English" then return false,"INVALID_VALUE" end
   p.Settings.Language=b
   return true
  end
  if a=="OpenMenuKey" or a=="RollKey" then
   if not validKeybind(b) then return false,"INVALID_VALUE" end
   p.Settings[a]=b
   return true
  end
  local booleanSettings={
   TutorialsEnabled=true,RewardPopups=true,QuickRoll=true,ShowRarityColors=true,CompactHUD=true,
   BloomEnabled=true,MuteAll=true,ReducedEffects=true,ShowOtherPollinators=true,
   HideOtherPlayersTokens=true,RareFeed=true,AutoDissolve=true,
  }
  if not booleanSettings[a] or type(b)~="boolean" then return false,"INVALID_SETTING" end
  if a=="AutoDissolve" and not p.WorkshopV5.Nodes.ECONOMY_1 then return false,"AUTO_DISSOLVE_LOCKED" end
  p.Settings[a]=b
  return true
 elseif action=="DissolveFilter" then
  local R=require(RS.Config.RarityConfig)
  if not p.WorkshopV5.Nodes.ECONOMY_2 then return false,"FILTER_LOCKED" end
  if type(a)~="string" or not R.Rank[a] then return false,"INVALID_VALUE" end
  p.Settings.DissolveRarities[a]=not p.Settings.DissolveRarities[a]
  return true
 end
 return false,"INVALID_ACTION"
end
function X:Loaded(player)
 if self.Temp[player] then return end local p=self:Profile(player) if not p then return end player:SetAttribute("BloomGameplayReady",false) self.Temp[player]={} self.Revisions[player]=0 self.StateRevisions[player]=0 self.LastPushedStateRevision[player]=-1
 local leader=Instance.new("Folder") leader.Name="leaderstats" leader.Parent=player for _,name in ipairs({"Coins","Hive"}) do local v=Instance.new("IntValue") v.Name=name v.Parent=leader end
 self.GardenPlotService:Build(player)
 self.GardenPlotService:RefreshHivePrompt(player)
 local function spawn() task.delay(.3,function() if not self:Profile(player) then return end local char=player.Character local root=char and char:FindFirstChild("HumanoidRootPart") if root then root.CFrame=CFrame.new(self.GardenPlotService:HivePosition(player)+Vector3.new(0,4,8)) end end) end
 self.Connections[player]=player.CharacterAdded:Connect(spawn)
 if self.ClientReadyConnections[player] then self.ClientReadyConnections[player]:Disconnect() end
 self.ClientReadyConnections[player]=player:GetAttributeChangedSignal("BloomClientReady"):Connect(function()
  if player:GetAttribute("BloomClientReady")==true and self:Profile(player) then
   print("[Bloom] Client UI ready, pushing authoritative state:",player.Name)
   task.defer(function() self:Push(player,true) end)
  end
 end)
 spawn() self:EmitOnce(player,"Wake") player:SetAttribute("BloomGameplayReady",true) self:Push(player,true)
 if p.Migrations.BloomSummary and not p.Migrations.BloomSummaryLogged then print("[Bloom] migrated",player.UserId,p.Migrations.BloomSummary.PetalDust) p.Migrations.BloomSummaryLogged=true end
end
function X:Remove(player)
 self.AnalyticsService:Flush(player)
 for _,name in ipairs(self.ServiceNames) do local s=self[name] if s.Remove then s:Remove(player) end end
 if self.Connections[player] then self.Connections[player]:Disconnect() self.Connections[player]=nil end if self.ClientReadyConnections[player] then self.ClientReadyConnections[player]:Disconnect() self.ClientReadyConnections[player]=nil end self.Temp[player]=nil self.Revisions[player]=nil self.StateRevisions[player]=nil self.LastPushedStateRevision[player]=nil
end
function X:Start(data,services,names)
 self.DataService=data self.ServiceNames=names for _,name in ipairs(names) do self[name]=services[name] end
 for _,name in ipairs({"ReferenceScenery","BrickCenter"}) do local stale=workspace:FindFirstChild(name) if stale then stale:Destroy() end end
 local garden=workspace:FindFirstChild("Garden")
 if garden then for _,name in ipairs({"LocationDecorTemplates","LocationTemplates"}) do local stale=garden:FindFirstChild(name) if stale then stale:Destroy() end end end
 local center=garden local marker=center and center:FindFirstChild("GardenCenter") self.Origin=(marker and marker.Position or Vector3.zero)+Vector3.new(0,5,0)
 local world=Instance.new("Folder") world.Name="BloomWorld" world.Parent=workspace self.World=world
 local authoredHub=workspace:FindFirstChild("FruitOrchardHub")
 if not authoredHub then warn("[Bloom][WORLD] Authored FruitOrchardHub is missing; run AI SYNC before Play") end
 for _,name in ipairs(names) do local s=self[name] if s.Init then s:Init(self) end end
 self.MapService:Build() self.RemoteService:Start()
 data:GetProfileLoadedSignal():Connect(function(player) self:Loaded(player) end)
 Players.PlayerRemoving:Connect(function(player) self:Remove(player) end)
 for _,player in ipairs(Players:GetPlayers()) do if data:IsLoaded(player) then self:Loaded(player) end end
 task.spawn(function() local sync=0 while true do task.wait(C.TickSeconds) sync=sync+C.TickSeconds local socialChanged=self.SocialService:Tick()
  for _,player in ipairs(Players:GetPlayers()) do if self:Profile(player) and self.Temp[player] then local ok,err=xpcall(function()
   if socialChanged then self:MarkStateDirty(player) end
   if self.SeasonService.Pending[player] and os.clock()>self.SeasonService.Pending[player].Expires then self.SeasonService.Pending[player]=nil end
   if not self.SeasonService.Pending[player] then
    self.TutorialService:Tick(player)
    if self.MapService:Tick(player) then self:MarkStateDirty(player) end
    self.PollinatorService:Tick(player,C.TickSeconds)
    self.GardenActivityService:Tick(player)
    if self.BoostService:Tick(player) then self:MarkStateDirty(player) end
    if self.MetaProgressionService:Tick(player) then self:MarkStateDirty(player) end
    self.AnalyticsService:Tick(player,C.TickSeconds)
   end
   local trialChanged=self.BuildTrialService:Tick(player)
   if trialChanged or (self.BuildTrialService.Active[player] and sync>=C.SyncSeconds) then self:MarkStateDirty(player) end
   if sync>=C.SyncSeconds then self:Push(player) end
  end,debug.traceback) if not ok then warn("[Bloom] Tick",err) end end end if sync>=C.SyncSeconds then sync=0 end
 end end)
 task.spawn(function()
  local interval=C.PublicSyncSeconds or 1
  local radius=C.PublicReplicationRadius or 180
  while true do
   task.wait(interval)
   local beeGroups={}
   for owner,states in pairs(self.PollinatorService.States) do
    if self:Profile(owner) then
     local frames={}
     local hive=self.GardenPlotService:HivePosition(owner)
     for slot,s in pairs(states) do
      local target=self.GardenPlotService:Position(owner,s.Slot)
      if hive and target then
       table.insert(frames,{Owner=owner.UserId,Index=slot,Id=s.Id,From=hive,To=target,Phase=s.Elapsed/C.DeliverySeconds})
      end
     end
     if #frames>0 then table.insert(beeGroups,{Owner=owner,Anchor=hive,Frames=frames}) end
    end
   end

   local publicTokens={}
   for owner,offers in pairs(self.GardenActivityService.Offers) do
    if self:Profile(owner) then
     for id,o in pairs(offers) do
      local position=o.Nodes and o.Nodes[o.Index]
      if position then table.insert(publicTokens,{Id=id,Owner=owner,OwnerId=owner.UserId,Position=position,Kind=o.Kind}) end
     end
    end
   end

   for _,recipient in ipairs(Players:GetPlayers()) do
    local profile=self:Profile(recipient)
    if profile then
     local character=recipient.Character
     local root=character and character:FindFirstChild("HumanoidRootPart")
     local position=root and root.Position

     local beeFrames={}
     for _,group in ipairs(beeGroups) do
      local own=group.Owner==recipient
      local visible=own
      if not visible and profile.Settings.ShowOtherPollinators and position and group.Anchor then
       visible=(position-group.Anchor).Magnitude<=radius
      end
      if visible then
       for _,frame in ipairs(group.Frames) do table.insert(beeFrames,frame) end
      end
     end
     self:Send(recipient,"Bees",beeFrames)

     local tokenFrames={}
     if not profile.Settings.HideOtherPlayersTokens and position then
      for _,token in ipairs(publicTokens) do
       if token.Owner~=recipient and (position-token.Position).Magnitude<=radius then
        table.insert(tokenFrames,{Id=token.Id,Owner=token.OwnerId,Position=token.Position,Kind=token.Kind})
       end
      end
     end
     self:Send(recipient,"OtherTokens",tokenFrames)
    end
   end
  end
 end)
end
return X

