--!strict
local C={}
C.RarityOrder={"Common","Uncommon","Rare","Epic","Legendary","Mythic","Celestial"}
C.RarityRank={Common=1,Uncommon=2,Rare=3,Epic=4,Legendary=5,Mythic=6,Celestial=7}
C.RarityColors={
 Common=Color3.fromRGB(220,220,220),Uncommon=Color3.fromRGB(96,230,132),Rare=Color3.fromRGB(91,173,255),Epic=Color3.fromRGB(194,115,255),
 Legendary=Color3.fromRGB(255,187,82),Mythic=Color3.fromRGB(255,108,131),Celestial=Color3.fromRGB(91,230,255),
}
C.BeeMastery={
 Cap=10,
 XPPerLevel={20,30,40,50,65,80,100,125,150},
 Rewards={
  [2]={WorkSpeed=.02},
  [3]={Yield=.02},
  [4]={WorkSpeed=.02},
  [5]={AbilityCooldown=.05},
  [6]={Yield=.03},
  [7]={WorkSpeed=.03},
  [8]={Yield=.03},
  [9]={AbilityCooldown=.05},
  [10]={WorkSpeed=.05,Yield=.05},
 },
}
C.Traits={
 Meadow={Id="Meadow",Name="MEADOW",Short="M",Color=Color3.fromRGB(92,202,112),Description="Garden synergy. Matching bees can splash their work and occasionally cross-pollinate a second flower at the same time.",Breakpoints={{Count=2,Bonus={FlowerGrowthMultiplier=1.10,SplashChance=.12,SplashPercent=.20,DualPollinationChance=.08,DualPollinationPercent=.35}},{Count=4,Bonus={FlowerGrowthMultiplier=1.25,SplashChance=.22,SplashPercent=.35,DualPollinationChance=.18,DualPollinationPercent=.65}}}},
 Swift={Id="Swift",Name="SWIFT",Short="S",Color=Color3.fromRGB(70,190,242),Description="Mobility synergy. Faster travel and shorter active-ability cooldowns.",Breakpoints={{Count=2,Bonus={PollinatorTravelSpeedMultiplier=1.15,AbilityCooldownMultiplier=.90}},{Count=3,Bonus={PollinatorTravelSpeedMultiplier=1.35,AbilityCooldownMultiplier=.78}}}},
 Bloom={Id="Bloom",Name="BLOOM",Short="B",Color=Color3.fromRGB(238,112,175),Description="Harvest synergy. More pollination yield and more Honey delivered to your personal Hive.",Breakpoints={{Count=2,Bonus={PollinatorYieldMultiplier=1.15,HiveHoneyMultiplier=1.12}},{Count=3,Bonus={PollinatorYieldMultiplier=1.35,HiveHoneyMultiplier=1.30}}}},
 Arcane={Id="Arcane",Name="ARCANE",Short="A",Color=Color3.fromRGB(145,104,235),Description="Knowledge synergy. Better roll luck and much faster Bee Mastery growth.",Breakpoints={{Count=2,Bonus={LuckMultiplier=1.10,BeeMasteryXPMultiplier=1.25}},{Count=3,Bonus={LuckMultiplier=1.28,BeeMasteryXPMultiplier=1.65}}}},
 Royal={Id="Royal",Name="ROYAL",Short="R",Color=Color3.fromRGB(235,180,61),Description="Economy synergy. More coins and a chance for critical pollination bursts.",Breakpoints={{Count=1,Bonus={CoinMultiplier=1.12,CriticalChance=.08,CriticalMultiplier=1.75}},{Count=2,Bonus={CoinMultiplier=1.30,CriticalChance=.16,CriticalMultiplier=2.00}}}},
 Mirror={Id="Mirror",Name="MIRROR",Short="M",Color=Color3.fromRGB(222,96,236),Description="Ability synergy. Clone effects become stronger and active abilities last longer.",Breakpoints={{Count=1,Bonus={ClonePowerMultiplier=1.15,AbilityDurationMultiplier=1.10}},{Count=2,Bonus={ClonePowerMultiplier=1.45,AbilityDurationMultiplier=1.30}}}},
 Twilight={Id="Twilight",Name="TWILIGHT",Short="T",Color=Color3.fromRGB(113,88,211),Description="Late-game synergy. Stronger bees, better yield and substantially faster abilities.",Breakpoints={{Count=1,Bonus={PollinatorPowerMultiplier=1.10,PollinatorYieldMultiplier=1.07,AbilityCooldownMultiplier=.94}},{Count=2,Bonus={PollinatorPowerMultiplier=1.30,PollinatorYieldMultiplier=1.22,AbilityCooldownMultiplier=.80}}}},
}
C.Bees={
 WorkerBee={Id="WorkerBee",DisplayName="Worker Bee",SortOrder=1,DropWeight=220000,Rarity="Common",Color=Color3.fromRGB(255,193,48),Traits={"Meadow","Bloom"},Passive={PollinatorPowerMultiplier=1.03},Ability={Id="PollenBurst",Name="Pollen Burst",Duration=8,Cooldown=48,WorkMultiplier=1.35,RewardMultiplier=1.12,Visual="Glow",Description="Every 48s, works 35% harder and earns 12% more for 8s."}},
 SprinterBee={Id="SprinterBee",DisplayName="Sprinter Bee",SortOrder=2,DropWeight=160000,Rarity="Common",Color=Color3.fromRGB(255,229,110),Traits={"Swift","Meadow"},Passive={PollinatorTravelSpeedMultiplier=1.08},Ability={Id="Afterburner",Name="Afterburner",Duration=9,Cooldown=46,WorkMultiplier=1.45,RewardMultiplier=1.05,Visual="Speed",Description="Every 46s, enters overdrive for 9s and works 45% harder."}},
 NectarBee={Id="NectarBee",DisplayName="Nectar Bee",SortOrder=3,DropWeight=120000,Rarity="Uncommon",Color=Color3.fromRGB(255,145,75),Traits={"Bloom","Meadow"},Passive={PollinatorYieldMultiplier=1.08},Ability={Id="HoneyFlood",Name="Honey Flood",Duration=12,Cooldown=62,WorkMultiplier=1.16,RewardMultiplier=1.65,HiveHoneyMultiplier=1.45,Visual="Honey",Description="Every 62s, floods its flower with nectar for 12s, boosting rewards and Hive Honey."}},
 ScholarBee={Id="ScholarBee",DisplayName="Scholar Bee",SortOrder=4,DropWeight=80000,Rarity="Uncommon",Color=Color3.fromRGB(110,180,255),Traits={"Arcane","Swift"},Passive={LuckMultiplier=1.05},Ability={Id="FieldStudy",Name="Field Study",Duration=14,Cooldown=66,WorkMultiplier=1.25,RewardMultiplier=1.10,BeeMasteryXPMultiplier=2.0,Visual="Arcane",Description="Every 66s, studies a flower for 14s, works harder, earns more, and doubles Bee Mastery XP."}},
 TwinBee={Id="TwinBee",DisplayName="Twin Bee",SortOrder=5,DropWeight=32000,Rarity="Rare",Color=Color3.fromRGB(165,120,255),Traits={"Mirror","Swift"},Passive={PollinatorPowerMultiplier=1.05},Ability={Id="CloneBurst",Name="Clone Burst",Duration=30,Cooldown=100,WorkMultiplier=2.00,RewardMultiplier=1.85,Visual="Clone",Description="Every 100s, creates a clone for 30s. The pair works at roughly x2 power."}},
 RoyalBee={Id="RoyalBee",DisplayName="Royal Bee",SortOrder=6,DropWeight=9000,Rarity="Epic",Color=Color3.fromRGB(255,205,82),Traits={"Royal","Meadow"},Passive={CoinMultiplier=1.10,PollinatorYieldMultiplier=1.06},Ability={Id="RoyalDecree",Name="Royal Decree",Duration=14,Cooldown=82,WorkMultiplier=1.50,RewardMultiplier=1.90,CriticalChanceBonus=.12,Visual="Royal",Description="Every 82s, issues a decree for 14s: stronger work, better rewards and extra crit chance."}},
 PrismBee={Id="PrismBee",DisplayName="Prism Bee",SortOrder=7,DropWeight=1600,Rarity="Legendary",Color=Color3.fromRGB(100,255,255),Traits={"Arcane","Bloom","Royal","Twilight"},Passive={LuckMultiplier=1.08,PollinatorYieldMultiplier=1.10,FlowerGrowthMultiplier=1.05},Ability={Id="PrismOverload",Name="Prism Overload",Duration=16,Cooldown=92,WorkMultiplier=2.10,RewardMultiplier=1.55,BeeMasteryXPMultiplier=1.40,Visual="Prism",Description="Every 92s, overloads for 16s: huge work, rewards and Bee Mastery XP boost."}},
 TwilightBee={Id="TwilightBee",DisplayName="Twilight Bee",SortOrder=8,DropWeight=220,Rarity="Mythic",Color=Color3.fromRGB(210,95,255),Traits={"Twilight","Mirror","Arcane"},Passive={PollinatorPowerMultiplier=1.12,PollinatorTravelSpeedMultiplier=1.06,PollinatorYieldMultiplier=1.08},Ability={Id="Eclipse",Name="Eclipse",Duration=12,Cooldown=80,WorkMultiplier=2.70,RewardMultiplier=2.05,HiveHoneyMultiplier=1.35,Visual="Eclipse",Description="Every 80s, triggers Eclipse for 12s: massive work, rewards and Hive Honey."}},

 BloomQueenBee={Id="BloomQueenBee",DisplayName="Bloom Queen Bee",SortOrder=9,DropWeight=120,Rarity="Mythic",Color=Color3.fromRGB(255,118,190),Traits={"Bloom","Meadow","Royal"},Passive={PollinatorYieldMultiplier=1.14,FlowerGrowthMultiplier=1.08,CoinMultiplier=1.05},Ability={Id="RoyalBloom",Name="Royal Bloom",Duration=14,Cooldown=95,WorkMultiplier=1.55,RewardMultiplier=1.30,HiveHoneyMultiplier=1.65,ExtraTargetCount=1,ExtraTargetPercent=.55,Visual="Bloom",Description="Every 95s, rules the garden for 14s: +55% work, +65% Hive Honey, and every pollination also blooms a second flower for 55% power."}},
 CrystalBee={Id="CrystalBee",DisplayName="Crystal Bee",SortOrder=10,DropWeight=60,Rarity="Mythic",Color=Color3.fromRGB(116,220,255),Traits={"Arcane","Mirror","Twilight"},Passive={LuckMultiplier=1.10,PollinatorPowerMultiplier=1.10},Ability={Id="CrystalResonance",Name="Crystal Resonance",Duration=7,Cooldown=100,WorkMultiplier=1.35,RewardMultiplier=1.20,TickCount=4,TickInterval=1.25,TickWorkSeconds=.70,TickRewardMultiplier=1.35,TickHiveMultiplier=1.20,Visual="Crystal",Description="Every 100s, crystallizes its flower and releases 4 resonance pulses. Each pulse adds extra pollination, coins and Honey while the bee keeps working."}},
 MagmaBee={Id="MagmaBee",DisplayName="Magma Bee",SortOrder=11,DropWeight=30,Rarity="Mythic",Color=Color3.fromRGB(255,93,35),Traits={"Royal","Bloom","Twilight"},Passive={PollinatorPowerMultiplier=1.15,PollinatorYieldMultiplier=1.08},Ability={Id="MagmaSpill",Name="Magma Spill",Duration=6,Cooldown=90,WorkMultiplier=1.25,RewardMultiplier=1.20,TickCount=5,TickInterval=1.10,TickWorkSeconds=.85,TickRewardMultiplier=1.40,TickHiveMultiplier=1.15,Visual="Magma",Description="Every 90s, spills magma on its flower. The magma pollinates it 5 extra times over 5.5s and each tick produces boosted coin value and Honey."}},
 ShadowBee={Id="ShadowBee",DisplayName="Shadow Bee",SortOrder=12,DropWeight=12,Rarity="Celestial",Color=Color3.fromRGB(122,55,226),Traits={"Twilight","Mirror","Swift"},Passive={PollinatorTravelSpeedMultiplier=1.14,LuckMultiplier=1.12,PollinatorPowerMultiplier=1.12},Ability={Id="ShadowEcho",Name="Shadow Echo",Duration=12,Cooldown=84,WorkMultiplier=1.65,RewardMultiplier=1.45,ExtraTargetCount=1,ExtraTargetPercent=.85,Visual="Shadow",Description="Every 84s, creates a shadow echo for 12s. The echo copies 85% of its work onto a second flower while the original bee gains stronger work and rewards."}},
 StormBee={Id="StormBee",DisplayName="Storm Bee",SortOrder=13,DropWeight=4,Rarity="Celestial",Color=Color3.fromRGB(55,185,255),Traits={"Swift","Royal","Arcane","Twilight"},Passive={PollinatorPowerMultiplier=1.18,PollinatorTravelSpeedMultiplier=1.15,PollinatorYieldMultiplier=1.12},Ability={Id="ChainTempest",Name="Chain Tempest",Duration=7,Cooldown=110,WorkMultiplier=1.85,RewardMultiplier=1.55,BurstTargets=4,BurstWorkSeconds=2.20,BurstRewardMultiplier=1.45,BurstHiveMultiplier=1.20,Visual="Storm",Description="Every 110s, calls a chain tempest that instantly strikes up to 4 flowers, then supercharges the bee for 7s."}},
}
local Rarity=require(script.Parent.RarityConfig)
C.RarityOrder=Rarity.Order C.RarityRank=Rarity.Rank C.RarityColors=Rarity.Colors
local totalWeight=0
for _,b in pairs(C.Bees)do totalWeight+=math.max(0,tonumber(b.DropWeight)or 0)end
local function compact(n:number):string local a=math.abs(n)local v=n local s=""if a>=1e12 then v=n/1e12;s="T"elseif a>=1e9 then v=n/1e9;s="B"elseif a>=1e6 then v=n/1e6;s="M"elseif a>=1e3 then v=n/1e3;s="K"end local d=v>=100 and 0 or v>=10 and 1 or 2 local t=d==0 and tostring(math.floor(v+.5))or string.format("%."..d.."f",v):gsub("(%..-)0+$","%1"):gsub("%.$","")return t..s end
function C.Get(id:string)return C.Bees[id]end
function C.Exists(id:string):boolean return C.Bees[id]~=nil end
function C.GetAll()return C.Bees end
function C.GetTrait(id:string)return C.Traits[id]end
function C.GetChancePercent(id:string):number local b=C.Bees[id]local w=b and tonumber(b.DropWeight)or 0 return totalWeight>0 and math.max(0,w)/totalWeight*100 or 0 end
function C.GetOdds(id:string):number local p=C.GetChancePercent(id)/100 return p>0 and 1/p or math.huge end
function C.FormatOdds(id:string):string local x=C.GetOdds(id)return x==math.huge and"1/∞"or"1/"..compact(x)end
function C.GetTraitBees(traitId:string):{string} local out={}for id,b in pairs(C.Bees)do for _,t in ipairs(b.Traits or{})do if t==traitId then out[#out+1]=id break end end end table.sort(out,function(a,b)local x,y=C.Get(a),C.Get(b)return(x and x.SortOrder or 999)<(y and y.SortOrder or 999)end)return out end
local MULT_DEFAULT={PollinatorPowerMultiplier=1,PollinatorTravelSpeedMultiplier=1,PollinatorYieldMultiplier=1,FlowerGrowthMultiplier=1,LuckMultiplier=1,CoinMultiplier=1,ClonePowerMultiplier=1,AbilityCooldownMultiplier=1,AbilityDurationMultiplier=1,HiveHoneyMultiplier=1,BeeMasteryXPMultiplier=1,CriticalMultiplier=1}
local ADD_DEFAULT={SplashChance=0,SplashPercent=0,CriticalChance=0,DualPollinationChance=0,DualPollinationPercent=0}
local function isAdd(k:string):boolean return ADD_DEFAULT[k]~=nil end
function C.GetTraitCounts(equipped:{string}?):{[string]:number}local counts:any={_total=0}if type(equipped)=="table"then for _,beeId in pairs(equipped)do if type(beeId)=="string"then local bee=C.Get(beeId)if bee then counts._total+=1 for _,traitId in ipairs(bee.Traits or{})do counts[traitId]=(counts[traitId]or 0)+1 end end end end end return counts end
function C.GetTraitBonuses(equipped:{string}?):({[string]:number},{any})
 local counts=C.GetTraitCounts(equipped)local bonus={}for k,v in pairs(MULT_DEFAULT)do bonus[k]=v end for k,v in pairs(ADD_DEFAULT)do bonus[k]=v end local active={}
 for traitId,data in pairs(C.Traits)do local count=counts[traitId]or 0 local best:any=nil local nextThreshold:number?=nil for _,bp in ipairs(data.Breakpoints)do if count>=bp.Count then best=bp elseif not nextThreshold then nextThreshold=bp.Count end end if best then active[#active+1]={Id=traitId,Name=data.Name,Short=data.Short,Color=data.Color,Description=data.Description,Count=count,Threshold=best.Count,NextThreshold=nextThreshold,Bonus=best.Bonus}for stat,val in pairs(best.Bonus)do if isAdd(stat)then bonus[stat]=(bonus[stat]or 0)+(tonumber(val)or 0)else bonus[stat]=(bonus[stat]or 1)*(tonumber(val)or 1)end end end end
 table.sort(active,function(a,b)if a.Threshold==b.Threshold then return a.Name<b.Name end return a.Threshold>b.Threshold end)return bonus,active
end
function C.GetTraitState(equipped:{string}?):{any}local counts=C.GetTraitCounts(equipped)local out={}for traitId,data in pairs(C.Traits)do local count=counts[traitId]or 0 local tier=0 local nextThreshold:number?=nil for i,bp in ipairs(data.Breakpoints)do if count>=bp.Count then tier=i elseif not nextThreshold then nextThreshold=bp.Count end end out[#out+1]={Id=traitId,Name=data.Name,Short=data.Short,Color=data.Color,Description=data.Description,Count=count,Tier=tier,NextThreshold=nextThreshold,Breakpoints=data.Breakpoints,BeeIds=C.GetTraitBees(traitId)}end table.sort(out,function(a,b)if a.Tier==b.Tier then return a.Name<b.Name end return a.Tier>b.Tier end)return out end
function C.GetPassiveBonuses(equipped:{string}?):{[string]:number}local out={}for k,v in pairs(MULT_DEFAULT)do out[k]=v end if type(equipped)=="table"then for _,beeId in pairs(equipped)do local bee=type(beeId)=="string"and C.Get(beeId)or nil if bee and type(bee.Passive)=="table"then for stat,m in pairs(bee.Passive)do out[stat]=(out[stat]or 1)*(tonumber(m)or 1)end end end end return out end
function C.GetAbilityDescription(id:string):string local bee=C.Get(id)if not bee or type(bee.Ability)~="table"then return"No active ability"end return tostring(bee.Ability.Description or bee.Ability.Name or"Ability")end
function C.GetPassiveDescription(id:string):string local b=C.Get(id)if not b or type(b.Passive)~="table"then return"No passive bonus"end local a={}for k,v in pairs(b.Passive)do local pct=(tonumber(v)or 1)-1;a[#a+1]=(pct>=0 and"+"or"")..string.format("%.0f%%",pct*100).." "..k:gsub("Multiplier$",""):gsub("(%l)(%u)","%1 %2")end table.sort(a)return #a>0 and table.concat(a," • ")or"No passive bonus"end
local function masteryRewardText(reward:any?):string
 if type(reward)~="table" then return"No new bonus"end
 local out={}
 if reward.WorkSpeed then out[#out+1]="+"..tostring(math.floor(reward.WorkSpeed*100+.5)).."% work speed"end
 if reward.Yield then out[#out+1]="+"..tostring(math.floor(reward.Yield*100+.5)).."% yield"end
 if reward.AbilityCooldown then out[#out+1]="-"..tostring(math.floor(reward.AbilityCooldown*100+.5)).."% ability cooldown"end
 return #out>0 and table.concat(out," • ")or"No new bonus"
end
function C.GetMasteryState(totalXP:number?):any
 local cfg=C.BeeMastery local maxXP=0 for _,need in ipairs(cfg.XPPerLevel)do maxXP+=need end
 local xp=math.clamp(tonumber(totalXP)or 0,0,maxXP) local level=1 local spent=0
 while level<cfg.Cap do local need=cfg.XPPerLevel[level]or 0 if xp-spent<need then break end spent+=need level+=1 end
 local work,yield,cooldown=1,1,1
 for target=2,level do local reward=cfg.Rewards[target]if reward then work+=reward.WorkSpeed or 0 yield+=reward.Yield or 0 cooldown-=reward.AbilityCooldown or 0 end end
 local isMax=level>=cfg.Cap local nextXP=isMax and 0 or(cfg.XPPerLevel[level]or 1)local currentXP=isMax and 0 or math.max(0,xp-spent)local nextReward=not isMax and cfg.Rewards[level+1]or nil
 local bonus={}
 if work>1 then bonus[#bonus+1]="+"..tostring(math.floor((work-1)*100+.5)).."% work"end
 if yield>1 then bonus[#bonus+1]="+"..tostring(math.floor((yield-1)*100+.5)).."% yield"end
 if cooldown<1 then bonus[#bonus+1]="-"..tostring(math.floor((1-cooldown)*100+.5)).."% cooldown"end
 return{Level=level,Cap=cfg.Cap,TotalXP=xp,MaxXP=maxXP,XP=currentXP,NextXP=nextXP,Progress=isMax and 1 or math.clamp(currentXP/math.max(1,nextXP),0,1),IsMax=isMax,WorkSpeedMultiplier=work,YieldMultiplier=yield,AbilityCooldownMultiplier=math.max(.75,cooldown),BonusText=#bonus>0 and table.concat(bonus," • ")or"No mastery bonus yet",LevelRewardText=masteryRewardText(cfg.Rewards[level]),NextRewardText=isMax and"MAX"or masteryRewardText(nextReward)}
end
return table.freeze(C)
