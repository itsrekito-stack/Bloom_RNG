local RS=game:GetService("ReplicatedStorage")
local C=require(RS.Config.BuildTrialConfig)
local B=require(RS.Config.BeesConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={Active={}}

function S:Init(x)
 self.X=x
end

function S:AdvancedUnlocked(profile)
 return E.Feature(profile,"LEGACY_4","AdvancedTrials")
end

function S:StartTrial(player,id)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end

 local cfg=type(id)=="string" and C[id] or nil
 if not cfg then return false,"INVALID_ITEM" end
 if not p.Tutorial.FeatureUnlocks.Trials then return false,"TRIAL_LOCKED" end
 if self.Active[player] then return false,"TRIAL_RUNNING" end
 if cfg.Advanced and not self:AdvancedUnlocked(p) then return false,"ADVANCED_TRIAL_LOCKED" end
 local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
 local pos=root and root.Position or self.X.GardenPlotService:HivePosition(player)
 if not pos then return false,"PROFILE_LOADING" end

 self.Active[player]={
  Advanced=cfg.Advanced==true,
  Id=id,
  Start=os.clock(),
  Counts={},
  Revision=p.Garden.Revision,
 }

 if id=="SwiftRoute" or id=="CrystalTriangle" then
  local kind=id=="SwiftRoute" and "PollenTrail" or "CrystalResonance"
  local offered=self.X.GardenActivityService:Offer(player,kind,pos,nil,nil,true)
  if not offered then
   self.Active[player]=nil
   return false,"ACTIVITY_UNAVAILABLE"
  end
 end

 self.X:Send(player,"Message",cfg.Name.." started")
 return true
end

function S:Tick(player)
 local a=self.Active[player]
 if not a then return false end
 local cfg=C[a.Id]
 if not cfg or os.clock()-a.Start>cfg.Seconds then
  self.Active[player]=nil
  self.X:Send(player,"Message",cfg and (cfg.Name.." expired") or "Trial expired")
  return true
 end
 return false
end

function S:Event(player,event,n)
 local a=self.Active[player]
 local p=self.X:Profile(player)
 if not a or not p then return end

 local cfg=C[a.Id]
 if not cfg or os.clock()-a.Start>cfg.Seconds then
  self.Active[player]=nil
  return
 end

 a.Counts[event]=(a.Counts[event] or 0)+n
 local synergies=self.X.GardenSynergyService.Active[player] or {}
 local yes=(a.Counts[cfg.Event] or 0)>=cfg.Target

 if a.Id=="MeadowCircuit" then
  local pairCount=0
  for _,v in pairs(synergies) do
   if v.Kind=="Pair" then pairCount+=1 end
  end
  local traits=B.GetTraitCounts(p.Pollinators.EquippedBeeSlots)
  yes=yes and pairCount>=2 and (traits.Meadow or 0)>=2
 elseif a.Id=="SwiftRoute" then
  yes=yes and os.clock()-a.Start<=60
 elseif a.Id=="CrystalTriangle" then
  yes=yes and synergies.CrystalTriangle~=nil
 elseif a.Id=="NoCelestial" then
  for _,beeId in pairs(p.Pollinators.EquippedBeeSlots) do
   local bee=B.Get(beeId)
   if bee and bee.Rarity=="Celestial" then a.Invalid=true end
  end
  yes=yes and not a.Invalid
 elseif a.Id=="SignatureBloom" then
  yes=synergies.AstralGarden~=nil
 elseif a.Id=="TwilightPulse" then
  yes=yes
 elseif a.Id=="MinimalGarden" then
  local count=0
  for _,slot in ipairs(p.Garden.Slots) do
   if slot.SpeciesId then count+=1 end
  end
  if count>3 then a.Invalid=true end
  yes=yes and not a.Invalid
 end

 if not yes then return end
 self.Active[player]=nil

 local first=not p.Quests.Trials[a.Id]
 if first then
  p.Quests.Trials[a.Id]=true
  self.X.WorkshopService:Point(player,"Trial_"..a.Id,2)
  p.Season.CompletedGoals[a.Id]=true
 else
  p.Currencies.Coins+=5
 end

 if a.Advanced then
  self.X.WorkshopService:Point(player,"AdvancedTrial_"..a.Id,1)
 end

 self.X:Emit(player,"Trial",1)
 self.X:Send(player,"Ceremony",{Kind="Trial",Text=cfg.Name.." complete"})
end

function S:Remove(player)
 self.Active[player]=nil
end

return S
