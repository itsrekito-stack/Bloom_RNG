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

return C
