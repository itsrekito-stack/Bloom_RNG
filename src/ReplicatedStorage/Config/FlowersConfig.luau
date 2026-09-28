--!strict
local Bloom=require(script.Parent.BloomConfig)
local C={Species={}}

local DROP_WEIGHTS={
 Daisy=280000,
 Tulip=220000,
 Sunflower=170000,
 Clover=130000,
 CrystalRose=40000,
 FrostLily=13330,
 PrismBloom=6670,
 MoonOrchid=3330,
 Nightshade=670,
 VoidLotus=200,
 StarBloom=40,
 EmberDahlia=20,
}

local POLLINATION_EFFECTS={
 Daisy="NeighbourBoost",
 Sunflower="SwiftWindow",
 Clover="CoinPod",
 MoonOrchid="LuckDew",
 StarBloom="Astral",
 EmberDahlia="Pulse",
}

local LEVEL_BUFFS={
 Daisy={Stat="FlowerGrowthMultiplier",Label="Flower Growth",Base=.012,PerLevel=.0018,Cap=.20},
 Tulip={Stat="PollinatorYieldMultiplier",Label="Pollination Yield",Base=.012,PerLevel=.0018,Cap=.20},
 Sunflower={Stat="PollinatorTravelSpeedMultiplier",Label="Bee Speed",Base=.012,PerLevel=.0016,Cap=.18},
 Clover={Stat="LuckMultiplier",Label="Luck",Base=.015,PerLevel=.0018,Cap=.22},
 CrystalRose={Stat="HiveHoneyMultiplier",Label="Hive Honey",Base=.018,PerLevel=.0022,Cap=.25},
 FrostLily={Stat="AbilityCooldownMultiplier",Label="Ability Cooldown",Base=.010,PerLevel=.0015,Cap=.18,Inverse=true},
 PrismBloom={Stat="LuckMultiplier",Label="Luck",Base=.025,PerLevel=.0022,Cap=.28},
 MoonOrchid={Stat="LuckMultiplier",Label="Luck",Base=.035,PerLevel=.0026,Cap=.34},
 Nightshade={Stat="PollinatorPowerMultiplier",Label="Bee Power",Base=.030,PerLevel=.0026,Cap=.32},
 VoidLotus={Stat="PollinatorYieldMultiplier",Label="Pollination Yield",Base=.032,PerLevel=.0028,Cap=.34},
 StarBloom={Stat="LuckMultiplier",Label="Luck",Base=.050,PerLevel=.0030,Cap=.40},
 EmberDahlia={Stat="CoinMultiplier",Label="Coins",Base=.050,PerLevel=.0030,Cap=.40},
}

local function species(id:string,name:string,rarity:string,shape:string,color:Color3,yield:number,sectors:{string},accent:Color3?)
 local allowedSectors={}
 for _,sector in ipairs(sectors) do
  allowedSectors[sector]=true
 end
 C.Species[id]={
  Id=id,
  DisplayName=name,
  Rarity=rarity,
  ShapeKey=shape,
  Color=color,
  AccentColor=accent or color:Lerp(Color3.new(1,1,1),.35),
  BaseYield=yield,
  AllowedSectors=allowedSectors,
 }
end

species("Daisy","Daisy","Common","Daisy",Color3.fromRGB(245,245,245),.20,{"StarterOrchard"},Color3.fromRGB(245,210,80))
species("Tulip","Tulip","Common","Tulip",Color3.fromRGB(235,80,100),.25,{"StarterOrchard"},Color3.fromRGB(255,176,84))
species("Sunflower","Sunflower","Uncommon","Sunflower",Color3.fromRGB(245,190,45),.35,{"StarterOrchard"},Color3.fromRGB(95,64,24))
species("Clover","Clover","Uncommon","Clover",Color3.fromRGB(80,210,100),.30,{"StarterOrchard"},Color3.fromRGB(140,255,165))
species("CrystalRose","Crystal Rose","Rare","CrystalRose",Color3.fromRGB(120,220,255),.48,{"CrystalGreenhouse"},Color3.fromRGB(210,247,255))
species("FrostLily","Frost Lily","Rare","FrostLily",Color3.fromRGB(190,235,255),.52,{"CrystalGreenhouse"},Color3.fromRGB(255,255,255))
species("PrismBloom","Prism Bloom","Epic","PrismBloom",Color3.fromRGB(185,120,255),.60,{"CrystalGreenhouse"},Color3.fromRGB(255,153,218))
species("MoonOrchid","Moon Orchid","Epic","MoonOrchid",Color3.fromRGB(110,145,255),.66,{"CrystalGreenhouse"},Color3.fromRGB(213,230,255))
species("Nightshade","Nightshade","Legendary","Nightshade",Color3.fromRGB(105,55,145),.82,{"TwilightGrove"},Color3.fromRGB(160,110,255))
species("VoidLotus","Void Lotus","Legendary","VoidLotus",Color3.fromRGB(80,40,115),.90,{"TwilightGrove"},Color3.fromRGB(220,120,255))
species("StarBloom","Star Bloom","Mythic","StarBloom",Color3.fromRGB(255,210,105),1.05,{"TwilightGrove"},Color3.fromRGB(255,248,195))
species("EmberDahlia","Ember Dahlia","Mythic","EmberDahlia",Color3.fromRGB(255,95,65),1.15,{"TwilightGrove"},Color3.fromRGB(255,190,105))

local function initializeDerived()
 for id,flower in pairs(C.Species) do
  flower.DropWeight=DROP_WEIGHTS[id]

  local allowedBiomes={}
  for sector in pairs(flower.AllowedSectors) do
   allowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true
  end
  flower.AllowedBiomes=allowedBiomes

  flower.GrowthProfile={XPPerLevel=Bloom.FlowerLevelXP,MaxLevel=Bloom.MasteryCap,ScalePerLevel=.025}
  flower.Tags={
   allowedBiomes.CrystalGreenhouse and "Crystal"
    or allowedBiomes.TwilightGrove and "Twilight"
    or "Meadow"
  }
  flower.PollinationEffect=POLLINATION_EFFECTS[id] or "Nectar"
  flower.AdjacencyRules={Range=1}
  flower.MutationPool={"Dewkissed","Radiant","Astral"}
  flower.Model=flower.ShapeKey
  flower.Colors={Primary=flower.Color,Accent=flower.AccentColor}
  flower.VFX={Color=flower.AccentColor}
 end
end

initializeDerived()

function C.GetSpecies(id:string)
 return C.Species[id]
end

function C.Exists(id:string):boolean
 return C.Species[id]~=nil
end

function C.GetLevelBuff(id:string,level:number?):any
 local cfg=LEVEL_BUFFS[id]
 if not cfg then return nil end
 local lv=math.clamp(math.floor(tonumber(level) or 1),1,Bloom.MasteryCap)
 local bonus=math.min(tonumber(cfg.Cap) or 1,(tonumber(cfg.Base) or 0)+(lv-1)*(tonumber(cfg.PerLevel) or 0))
 local inverse=cfg.Inverse==true
 local multiplier=inverse and math.max(.05,1-bonus) or 1+bonus
 return {Stat=cfg.Stat,Label=cfg.Label,Level=lv,Bonus=bonus,Multiplier=multiplier,Inverse=inverse}
end

function C.FormatLevelBuff(id:string,level:number?):string
 local buff=C.GetLevelBuff(id,level)
 if not buff then return "No passive bonus" end
 local pct=math.floor((tonumber(buff.Bonus) or 0)*1000+.5)/10
 local value=(pct%1==0) and tostring(math.floor(pct)) or string.format("%.1f",pct)
 return (buff.Inverse and "-" or "+")..value.."% "..tostring(buff.Label)
end

return C
