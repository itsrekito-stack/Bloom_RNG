local F=require(script.Parent.FlowersConfig) local B=require(script.Parent.BeesConfig) local R=require(script.Parent.RarityConfig) local C=require(script.Parent.BloomConfig) local E=require(script.Parent.Parent.Shared.WorkshopEffects)
local S={}
function S.Build(p,luck,temp)
 temp=temp or {}
 local pool={} local function add(kind,items) for id,v in pairs(items) do
  local unlocked=kind=="Bee" if kind=="FlowerSeed" then for sector in pairs(v.AllowedBiomes) do if p.World.UnlockedSectors[sector] or sector=="SunnyOrchard" then unlocked=true end end end
  if unlocked then local discovered=kind=="Bee" and p.Pollinators.DiscoveredBees[id] or kind=="FlowerSeed" and p.FlowerCollection.DiscoveredFlowers[id]
   local rank=R.Rank[v.Rarity] local w=v.DropWeight*(1+(luck-1)*(rank-1)*.25)
   if p.RollState.SpecialRollReady then if rank>=3 then w=w*C.SpecialRareMultiplier end if not discovered then w=w*C.SpecialNewMultiplier*E.Value(p,"BLOOM_3","NewWeight",1)*(p.Season.ActiveCard=="AutumnFortune" and 1.5 or 1) end if temp.Eclipse then w=w*(rank>=5 and (1.5*E.Value(p,"EXPLORATION_5","EclipseWeight",1)) or 1) end if p.WorkshopV5.Nodes.BLOOM_6 and temp.Signature and rank>=5 then w=w*E.Value(p,"BLOOM_6","SignatureWeight",1) end end
   table.insert(pool,{Kind=kind,Id=id,DisplayName=v.DisplayName,Rarity=v.Rarity,Weight=w,Undiscovered=not discovered})
  end end end
 add("FlowerSeed",F.Species) add("Bee",B.Bees) table.sort(pool,function(a,b) return a.Kind..a.Id<b.Kind..b.Id end)
 if p.RollState.DiscoveryPity+1>=C.DiscoveryThreshold then local cap=R.Rank[C.DiscoveryPityMaxRarity] or R.Rank.Epic local new={} for _,v in ipairs(pool) do if v.Undiscovered and (R.Rank[v.Rarity] or math.huge)<=cap then table.insert(new,v) end end if #new>0 then pool=new end end
 local total=0 for _,v in ipairs(pool) do total=total+v.Weight end if total<=0 then return {},0 end for _,v in ipairs(pool) do v.Chance=v.Weight/total v.Odds=total/v.Weight end return pool,total
end
local function compact(n)
 local a=math.abs(n)local v=n local suffix=""
 if a>=1e12 then v=n/1e12;suffix="T"elseif a>=1e9 then v=n/1e9;suffix="B"elseif a>=1e6 then v=n/1e6;suffix="M"elseif a>=1e3 then v=n/1e3;suffix="K"end
 local digits=math.abs(v)>=100 and 0 or math.abs(v)>=10 and 1 or 2
 local text=digits==0 and tostring(math.floor(v+.5)) or string.format("%."..digits.."f",v):gsub("(%..-)0+$","%1"):gsub("%.$","")
 return text..suffix
end
local BASE_TOTAL=0
for _,v in pairs(F.Species)do BASE_TOTAL+=math.max(0,tonumber(v.DropWeight)or 0)end
for _,v in pairs(B.Bees)do BASE_TOTAL+=math.max(0,tonumber(v.DropWeight)or 0)end
function S.BaseOdds(kind,id)
 local source=kind=="Bee" and B.Bees[id] or kind=="FlowerSeed" and F.Species[id] or nil
 local weight=source and math.max(0,tonumber(source.DropWeight)or 0)or 0
 return weight>0 and BASE_TOTAL/weight or math.huge
end
function S.FormatBaseOdds(kind,id)
 local odds=S.BaseOdds(kind,id)
 return odds==math.huge and "1/∞" or "1/"..compact(odds)
end
return S
