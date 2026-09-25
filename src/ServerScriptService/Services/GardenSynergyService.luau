local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.GardenSynergyConfig) local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local E=require(RS.Shared.WorkshopEffects) local S={Active={}}
function S:Init(x) self.X=x end
function S:Recalculate(player)
 local p=self.X:Profile(player) if not p then return end local slots=p.Garden.Slots local range=1+E.Value(p,"GARDEN_2","Adjacency",0)+(p.Season.ActiveCard=="SpringResonance" and 1 or 0) local traits=B.GetTraitCounts(p.Pollinators.EquippedBeeSlots) local active={}
 local function tag(i,t) local f=slots[i] and F.Species[slots[i].SpeciesId] return f and table.find(f.Tags,t)~=nil end
 for _,r in ipairs(C.Recipes) do local matches={} local yes=false
  if r.Kind=="Pair" then for i,a in ipairs(slots) do for j,b in ipairs(slots) do if a.SpeciesId==r.Species[1] and b.SpeciesId==r.Species[2] and C.Adjacent(i,j,range) then yes=true matches={i,j} end end end
  elseif r.Kind=="Family" then
   for start in ipairs(slots) do if tag(start,r.Tag) then local queue={start} local seen={[start]=true} local k=1 while queue[k] do local i=queue[k] k=k+1 for j in ipairs(slots) do if not seen[j] and tag(j,r.Tag) and C.Adjacent(i,j,range) then seen[j]=true table.insert(queue,j) end end end if #queue>=r.Count then yes=true matches=queue break end end end
  elseif r.Kind=="Pattern" then yes=true for _,i in ipairs(r.Slots) do if not tag(i,r.Tag) then yes=false end end matches=r.Slots
  elseif r.Kind=="Bee" or r.Kind=="Biome" then for i in ipairs(slots) do if tag(i,r.Tag) then table.insert(matches,i) end end yes=#matches>0 and (r.Kind=="Bee" and (traits[r.Trait] or 0)>=r.Count or r.Kind=="Biome" and self.X.MapService:Sector(player)==r.Biome)
  elseif r.Kind=="Signature" then yes=true for _,id in ipairs(r.Species) do local found=false for i,s in ipairs(slots) do if s.SpeciesId==id then found=true table.insert(matches,i) break end end if not found then yes=false end end end
  if yes then active[r.Id]={Kind=r.Kind,Slots=matches} if not p.GardenSynergies.Discovered[r.Id] then p.GardenSynergies.Discovered[r.Id]=true self.X:Emit(player,"Synergy",1) end end
 end self.Active[player]=active if self.X.Temp and self.X.Temp[player] then self.X.Temp[player].Signature=active.AstralGarden~=nil end return active
end
function S:Remove(player) self.Active[player]=nil end
return S
