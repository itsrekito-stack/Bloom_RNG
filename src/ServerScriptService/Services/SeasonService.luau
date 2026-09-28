local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.SeasonConfig) local Bloom=require(RS.Config.BloomConfig) local Plan=require(RS.Shared.SeasonPlan) local E=require(RS.Shared.WorkshopEffects) local Http=game:GetService("HttpService") local S={Pending={}}
function S:Init(x) self.X=x end
function S:LegacyComplete(p)
 if not p or not p.WorkshopV5 then return false end
 for i=1,6 do if not p.WorkshopV5.Nodes["LEGACY_"..i] then return false end end
 return true
end
function S:DistillNectar(player)
 local p=self.X:Profile(player)
 if not p then return false,"PROFILE_LOADING" end
 if not self:LegacyComplete(p) then return false,"LEGACY_REQUIRED" end
 local cost=Bloom.NectarDistillCost
 if p.Currencies.AncientNectar<cost then return false,"NECTAR_REQUIRED" end
 p.Currencies.AncientNectar-=cost
 p.Currencies.PetalDust+=Bloom.NectarDistillDust*E.Value(p,"ECONOMY_3","DustYield",1)
 return true
end
function S:Eligible(p) local completed=0 for _,id in ipairs(C.TrialIds) do if p.Quests.Trials[id] then completed+=1 end end return p.Hive.Level>=C.Hive and completed>=C.Trials and self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=C.Flowers and self.X.U.Count(p.Pollinators.DiscoveredBees)>=C.Bees end
function S:Preview(player)
 local p=self.X:Profile(player) if not p then return end if not self:Eligible(p) then self.X:Send(player,"Message",string.format("Season: Hive %d, %d key trials, %d flowers, %d bees",C.Hive,C.Trials,C.Flowers,C.Bees)) return end
 local plan=Plan.BuildSeasonTurnPlan(p) local token=Http:GenerateGUID(false) self.Pending[player]={Token=token,Revision=self.X.Revisions[player],Expires=os.clock()+30,Confirm=0,Before=self.X.U.Copy(p)}
 self.X:Send(player,"SeasonPreview",{Token=token,Diff=plan.Diff,Keep=C.Keep,Reset=C.Reset})
end
function S:Confirm(player,token)
 local p=self.X:Profile(player) if not p then return false,"PROFILE_LOADING" end
 local q=self.Pending[player] if not q or q.Token~=token or os.clock()>q.Expires then return false,"INVALID_VALUE" end
 if not self:Eligible(p) then return false,"LOCKED" end
 if q.Revision~=self.X.Revisions[player] or not self.X.U.Equal(q.Before,p) then self.Pending[player]=nil self:Preview(player) return false,"INVALID_VALUE" end
 if q.Confirm==0 then q.Confirm=1 self.X:Send(player,"SeasonConfirm",token) return true end
 local plan=Plan.BuildSeasonTurnPlan(p)
 local result=self.X.DataService:CommitProfile(player,plan.After,token)
 -- DataService owns the transaction gate, including a late/unknown completion.
 -- Definite preflight refusal leaves the preview available for a safe retry.
 if result.Code~="SUCCESS" then
  if result.Code~="RETRYABLE_FAILURE" and result.Code~="INVALID_PROFILE" then self.Pending[player]=nil end
  return false,result.Code=="RETRYABLE_FAILURE" and "PERSISTENCE_BUSY" or "PERSISTENCE_UNCONFIRMED"
 end
 self.Pending[player]=nil
 if self.X.DataService:GetProfile(player) and player.Parent==game:GetService("Players") then
  self.X.Temp[player]={}
  self.X.GardenActivityService:CancelGarden(player)
  self.X.BuildTrialService:Remove(player)
  self.X.PollinatorService:Remove(player)
  self.X.GardenPlotService:Build(player)
  self.X:Send(player,"Ceremony",{Kind="Season",Text="New Season"})
  if plan.After.Season.ActiveCard=="" then
   self.X:Send(player,"Cards",self:Offers(plan.After))
  else
   self.X:Send(player,"Message","Season card retained: "..plan.After.Season.ActiveCard)
  end
 end
 return true
end
function S:Offers(p) local out={} for i=1,3 do out[i]=C.Cards[(p.Season.Count+i-2)%#C.Cards+1] end return out end
function S:Card(player,id) local p=self.X:Profile(player) if not p then return false,"PROFILE_LOADING" end if p.Season.Count<1 or p.Season.ActiveCard~="" or not table.find(self:Offers(p),id) then return false,"INVALID_ITEM" end p.Season.ActiveCard=id self.X.GardenSynergyService:Recalculate(player) return true end
function S:Keepsake(player,kind,id) local p=self.X:Profile(player) if not p then return false,"PROFILE_LOADING" end if kind=="Flower2" then if not p.WorkshopV5.Nodes.LEGACY_5 then return false,"LOCKED" end if not p.FlowerCollection.DiscoveredFlowers[id] then return false,"NOT_DISCOVERED" end p.Season.Keepsakes.Flower2=id return true end if kind=="Flower" and p.FlowerCollection.DiscoveredFlowers[id] or kind=="Bee" and p.Pollinators.DiscoveredBees[id] then p.Season.Keepsakes[kind]=id return true end return false,"NOT_DISCOVERED" end
function S:Remove(player) self.Pending[player]=nil end
return S

