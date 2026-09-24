local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.BuildTrialConfig) local B=require(RS.Config.BeesConfig) local S={Active={}}
function S:Init(x) self.X=x end
function S:StartTrial(player,id)
 local p=self.X:Profile(player) local cfg=C[id] if not p or not cfg or not p.Tutorial.FeatureUnlocks.Trials or self.X.MapService:Sector(player)~=cfg.Sector or not p.World.UnlockedSectors[cfg.Sector] then return false end
 local location=require(RS.Config.LocationsConfig).Sectors[cfg.Sector] local pos=self.X.Origin+location.Center+Vector3.new(0,2,30)
 if not self.X.U.Near(player,pos,14) then return false end
 self.Active[player]={Advanced=p.WorkshopV5.Nodes.LEGACY_4==true,Id=id,Start=os.clock(),Counts={},Revision=p.Garden.Revision} self.X:Send(player,"Message",cfg.Name.." started") return true
end
function S:Event(player,event,n)
 local a=self.Active[player] local p=self.X:Profile(player) if not a or not p then return end local cfg=C[a.Id] if os.clock()-a.Start>cfg.Seconds then self.Active[player]=nil return end
 a.Counts[event]=(a.Counts[event] or 0)+n local synergies=self.X.GardenSynergyService.Active[player] or {} local yes=(a.Counts[cfg.Event] or 0)>=cfg.Target*(a.Advanced and 2 or 1)
 if a.Id=="MeadowCircuit" then local pairCount=0 for _,v in pairs(synergies) do if v.Kind=="Pair" then pairCount=pairCount+1 end end local traits=B.GetTraitCounts(p.Pollinators.EquippedBeeSlots) yes=yes and pairCount>=2 and (traits.Meadow or 0)>=2
 elseif a.Id=="SwiftRoute" then yes=yes and os.clock()-a.Start<=60
 elseif a.Id=="CrystalTriangle" then yes=yes and synergies.CrystalTriangle~=nil
 elseif a.Id=="NoCelestial" then for _,id in pairs(p.Pollinators.EquippedBeeSlots) do if B.Get(id).Rarity=="Celestial" then a.Invalid=true end end yes=yes and not a.Invalid
 elseif a.Id=="SignatureBloom" then yes=synergies.AstralGarden~=nil
 elseif a.Id=="TwilightPulse" then yes=yes and (a.Counts.Firefly or 0)>=5 and self.X.SocialService:IsEclipse(player)
 elseif a.Id=="MinimalGarden" then local count=0 for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then count=count+1 end end if count>3 then a.Invalid=true end yes=yes and not a.Invalid
 end
 if not yes then return end self.Active[player]=nil
 local first=not p.Quests.Trials[a.Id] if first then p.Quests.Trials[a.Id]=true self.X.WorkshopService:Point(player,"Trial_"..a.Id,2) p.Season.CompletedGoals[a.Id]=true else p.Currencies.Coins=p.Currencies.Coins+5 end
 if a.Advanced then self.X.WorkshopService:Point(player,"AdvancedTrial_"..a.Id,1) end self.X:Emit(player,"Trial",1) self.X:Send(player,"Ceremony",{Kind="Trial",Text=cfg.Name.." complete"})
end
function S:Remove(player) self.Active[player]=nil end
return S
