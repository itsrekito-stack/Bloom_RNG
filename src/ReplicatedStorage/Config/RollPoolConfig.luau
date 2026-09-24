local F=require(script.Parent.FlowersConfig) local B=require(script.Parent.BeesConfig) local R=require(script.Parent.RarityConfig) local C=require(script.Parent.BloomConfig)
local S={}
function S.Build(p,luck,temp)
 local pool={} local function add(kind,items) for id,v in pairs(items) do
  local unlocked=kind=="Bee" if kind=="FlowerSeed" then for sector in pairs(v.AllowedBiomes) do if p.World.UnlockedSectors[sector] or sector=="SunnyOrchard" then unlocked=true end end end
  if unlocked then local discovered=kind=="Bee" and p.Pollinators.DiscoveredBees[id] or kind=="FlowerSeed" and p.FlowerCollection.DiscoveredFlowers[id]
   local rank=R.Rank[v.Rarity] local w=v.DropWeight*(1+(luck-1)*(rank-1)*.25)
   if p.RollState.SpecialRollReady then if rank>=3 then w=w*C.SpecialRareMultiplier end if not discovered then w=w*C.SpecialNewMultiplier*(p.WorkshopV5.Nodes.BLOOM_3 and 1.2 or 1)*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1) end if temp.Eclipse then w=w*(rank>=5 and (p.WorkshopV5.Nodes.EXPLORATION_5 and 1.95 or 1.5) or 1) end if p.WorkshopV5.Nodes.BLOOM_6 and temp.Signature and rank>=5 then w=w*1.5 end end
   table.insert(pool,{Kind=kind,Id=id,DisplayName=v.DisplayName,Rarity=v.Rarity,Weight=w,Undiscovered=not discovered})
  end end end
 add("FlowerSeed",F.Species) add("Bee",B.Bees) table.sort(pool,function(a,b) return a.Kind..a.Id<b.Kind..b.Id end)
 if p.RollState.DiscoveryPity+1>=C.DiscoveryThreshold then local new={} for _,v in ipairs(pool) do if v.Undiscovered then table.insert(new,v) end end if #new>0 then pool=new end end
 local total=0 for _,v in ipairs(pool) do total=total+v.Weight end for _,v in ipairs(pool) do v.Chance=v.Weight/total v.Odds=total/v.Weight end return pool,total
end
return S
