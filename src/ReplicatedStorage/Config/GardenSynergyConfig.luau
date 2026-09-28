local Bloom=require(script.Parent.BloomConfig)

local C={
 Recipes={
  {Id="MeadowPair",Name="Meadow Pair",Strength=10,Tier=1,Species={"Daisy","Tulip"},Levels={Daisy=1,Tulip=1},Effect={FlowerGrowthMultiplier=1.08}},
  {Id="GoldenPair",Name="Golden Pair",Strength=12,Tier=1,Species={"Sunflower","Clover"},Levels={Sunflower=1,Clover=1},Effect={CoinMultiplier=1.08}},
  {Id="SunlitPatch",Name="Sunlit Patch",Strength=14,Tier=1,Species={"Daisy","Sunflower","Clover"},Levels={Daisy=1,Sunflower=1,Clover=1},Effect={FlowerGrowthMultiplier=1.08,CoinMultiplier=1.05}},
  {Id="CrystalDew",Name="Crystal Dew",Strength=16,Tier=1,Species={"CrystalRose","MoonOrchid"},Levels={CrystalRose=2,MoonOrchid=2},Effect={LuckMultiplier=1.05,FlowerGrowthMultiplier=1.07}},
  {Id="MeadowFamily",Name="Meadow Family",Strength=20,Tier=2,Species={"Daisy","Tulip","Sunflower"},Levels={Daisy=2,Tulip=2,Sunflower=2},Effect={FlowerGrowthMultiplier=1.16}},
  {Id="MeadowLine",Name="Meadow Line",Strength=26,Tier=2,Species={"Daisy","Tulip","Sunflower","Clover"},Levels={Daisy=2,Tulip=2,Sunflower=2,Clover=2},Effect={FlowerGrowthMultiplier=1.18,CoinMultiplier=1.08}},
  {Id="PrismFrost",Name="Prism Frost",Strength=28,Tier=2,Species={"FrostLily","PrismBloom"},Levels={FrostLily=3,PrismBloom=3},Effect={PollinatorYieldMultiplier=1.08,FlowerGrowthMultiplier=1.10}},
  {Id="MoonlitThorn",Name="Moonlit Thorn",Strength=30,Tier=2,Species={"MoonOrchid","Nightshade"},Levels={MoonOrchid=3,Nightshade=3},Effect={LuckMultiplier=1.08,PollinatorPowerMultiplier=1.07}},
  {Id="CrystalTriangle",Name="Crystal Triangle",Strength=34,Tier=3,Species={"CrystalRose","FrostLily","PrismBloom"},Levels={CrystalRose=3,FrostLily=3,PrismBloom=2},Effect={LuckMultiplier=1.10,FlowerGrowthMultiplier=1.12}},
  {Id="PrismaticMoon",Name="Prismatic Moon",Strength=38,Tier=3,Species={"CrystalRose","PrismBloom","MoonOrchid"},Levels={CrystalRose=3,PrismBloom=3,MoonOrchid=3},Effect={LuckMultiplier=1.11,PollinatorYieldMultiplier=1.09}},
  {Id="TwilightOpposite",Name="Twilight Pair",Strength=42,Tier=4,Species={"Nightshade","VoidLotus"},Levels={Nightshade=4,VoidLotus=4},Effect={PollinatorPowerMultiplier=1.14,CoinMultiplier=1.12}},
  {Id="VoidEmber",Name="Void Ember",Strength=44,Tier=4,Species={"VoidLotus","EmberDahlia"},Levels={VoidLotus=4,EmberDahlia=4},Effect={PollinatorPowerMultiplier=1.13,HiveHoneyMultiplier=1.10}},
  {Id="MeadowRing",Name="Sevenfold Garden",Strength=50,Tier=5,Species={"Daisy","Tulip","Sunflower","Clover","CrystalRose","FrostLily","PrismBloom"},Levels={Daisy=3,Tulip=3,Sunflower=3,Clover=3,CrystalRose=3,FrostLily=3,PrismBloom=3},Effect={FlowerGrowthMultiplier=1.25,PollinatorYieldMultiplier=1.12}},
  {Id="EclipseGarden",Name="Eclipse Garden",Strength=54,Tier=5,Species={"MoonOrchid","Nightshade","VoidLotus","StarBloom"},Levels={MoonOrchid=4,Nightshade=4,VoidLotus=4,StarBloom=5},Effect={LuckMultiplier=1.14,PollinatorPowerMultiplier=1.13}},
  {Id="StellarFlame",Name="Stellar Flame",Strength=57,Tier=5,Species={"StarBloom","EmberDahlia"},Levels={StarBloom=5,EmberDahlia=5},Effect={CoinMultiplier=1.15,PollinatorPowerMultiplier=1.14,HiveHoneyMultiplier=1.10}},
  {Id="CelestialCrown",Name="Celestial Crown",Strength=59,Tier=5,Species={"CrystalRose","PrismBloom","StarBloom","EmberDahlia"},Levels={CrystalRose=4,PrismBloom=4,StarBloom=5,EmberDahlia=5},Effect={LuckMultiplier=1.16,PollinatorYieldMultiplier=1.14,HiveHoneyMultiplier=1.12}},
  {Id="AstralGarden",Name="Astral Garden",Strength=60,Tier=6,Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"},Levels={StarBloom=5,MoonOrchid=5,VoidLotus=5,EmberDahlia=5},Effect={LuckMultiplier=1.18,PollinatorYieldMultiplier=1.18,PollinatorPowerMultiplier=1.15}},
  {Id="BlueMint",Name="Blue Mint",Strength=13,Tier=1,Species={"Bluebell","MintDaisy"},Levels={Bluebell=1,MintDaisy=1},Effect={FlowerGrowthMultiplier=1.07,PollinatorTravelSpeedMultiplier=1.05}},
  {Id="HoneyAmber",Name="Honey Amber",Strength=15,Tier=1,Species={"HoneyPoppy","AmberCrocus"},Levels={HoneyPoppy=1,AmberCrocus=1},Effect={HiveHoneyMultiplier=1.08,CoinMultiplier=1.06}},
  {Id="RainVelvet",Name="Rain Velvet",Strength=19,Tier=2,Species={"RainIris","VelvetPeony"},Levels={RainIris=2,VelvetPeony=2},Effect={PollinatorYieldMultiplier=1.08,LuckMultiplier=1.05}},
  {Id="GildedWeather",Name="Gilded Weather",Strength=22,Tier=2,Species={"Bluebell","HoneyPoppy","RainIris"},Levels={Bluebell=2,HoneyPoppy=2,RainIris=2},Effect={FlowerGrowthMultiplier=1.10,HiveHoneyMultiplier=1.08}},
  {Id="GlassAurora",Name="Glass Aurora",Strength=24,Tier=2,Species={"GlassTulip","AuroraLily"},Levels={GlassTulip=2,AuroraLily=2},Effect={PollinatorPowerMultiplier=1.08,LuckMultiplier=1.06}},
  {Id="SapphireDream",Name="Sapphire Dream",Strength=29,Tier=2,Species={"SapphireMoss","DreamOrchid"},Levels={SapphireMoss=3,DreamOrchid=3},Effect={AbilityCooldownMultiplier=.93,FlowerGrowthMultiplier=1.11}},
  {Id="AuroraDream",Name="Aurora Dream",Strength=31,Tier=3,Species={"AuroraLily","DreamOrchid"},Levels={AuroraLily=3,DreamOrchid=3},Effect={LuckMultiplier=1.09,FlowerGrowthMultiplier=1.10}},
  {Id="EchoSolar",Name="Echo Solar",Strength=33,Tier=3,Species={"EchoFern","SolarLotus"},Levels={EchoFern=3,SolarLotus=3},Effect={HiveHoneyMultiplier=1.11,PollinatorYieldMultiplier=1.10}},
  {Id="CrystalNewSet",Name="Aurora Glasshouse",Strength=36,Tier=3,Species={"GlassTulip","AuroraLily","SapphireMoss"},Levels={GlassTulip=3,AuroraLily=3,SapphireMoss=3},Effect={PollinatorPowerMultiplier=1.11,AbilityCooldownMultiplier=.91,LuckMultiplier=1.07}},
  {Id="CometNebula",Name="Comet Nebula",Strength=40,Tier=4,Species={"CometRose","NebulaDahlia"},Levels={CometRose=4,NebulaDahlia=4},Effect={LuckMultiplier=1.11,CoinMultiplier=1.12}},
  {Id="DreamEchoSolar",Name="Dream Echo Solar",Strength=43,Tier=4,Species={"DreamOrchid","EchoFern","SolarLotus"},Levels={DreamOrchid=4,EchoFern=4,SolarLotus=4},Effect={FlowerGrowthMultiplier=1.13,HiveHoneyMultiplier=1.12,PollinatorYieldMultiplier=1.11}},
  {Id="CrownedComet",Name="Crowned Comet",Strength=47,Tier=4,Species={"CrownBloom","CometRose"},Levels={CrownBloom=5,CometRose=4},Effect={LuckMultiplier=1.15,PollinatorPowerMultiplier=1.12}},
  {Id="NewBloomRing",Name="Prismatic Nursery",Strength=52,Tier=5,Species={"Bluebell","HoneyPoppy","MintDaisy","AmberCrocus","RainIris","GlassTulip","AuroraLily"},Levels={Bluebell=3,HoneyPoppy=3,MintDaisy=3,AmberCrocus=3,RainIris=3,GlassTulip=3,AuroraLily=3},Effect={FlowerGrowthMultiplier=1.20,HiveHoneyMultiplier=1.12,CoinMultiplier=1.10}},
  {Id="CosmicPetals",Name="Cosmic Petals",Strength=58,Tier=5,Species={"CometRose","NebulaDahlia","CrownBloom"},Levels={CometRose=5,NebulaDahlia=5,CrownBloom=5},Effect={LuckMultiplier=1.17,CoinMultiplier=1.15,PollinatorPowerMultiplier=1.13}},
  {Id="GrandNewGarden",Name="Aurora Crown Garden",Strength=66,Tier=6,Species={"GlassTulip","AuroraLily","SapphireMoss","DreamOrchid","EchoFern","CometRose","CrownBloom"},Levels={GlassTulip=5,AuroraLily=5,SapphireMoss=5,DreamOrchid=5,EchoFern=5,CometRose=5,CrownBloom=6},Effect={LuckMultiplier=1.20,FlowerGrowthMultiplier=1.18,PollinatorYieldMultiplier=1.16,HiveHoneyMultiplier=1.14}},
 },
 Layout={
  Radius=8.1,
  SlotY=.10,
  HiveOffset=Vector3.new(13.9,2.07,0),
 }
}

C.ById={}
for _,recipe in ipairs(C.Recipes) do C.ById[recipe.Id]=recipe end

function C.Get(id)
 return C.ById[id]
end

function C.Position(i)
 if type(i)~="number" or i%1~=0 or i<1 or i>Bloom.MaxFlowerSlots then return Vector3.zero end
 local angle=-math.pi/2+((i-1)/Bloom.MaxFlowerSlots)*math.pi*2
 return Vector3.new(math.cos(angle)*C.Layout.Radius,C.Layout.SlotY,math.sin(angle)*C.Layout.Radius)
end

function C.LogicalPosition(i)
 local p=C.Position(i)
 return Vector3.new(p.X,0,p.Z)
end

function C.Adjacent(a,b,range)
 local x,y=C.LogicalPosition(a),C.LogicalPosition(b)
 return a~=b and (x-y).Magnitude<=7.1*(range or 1)
end

return C
