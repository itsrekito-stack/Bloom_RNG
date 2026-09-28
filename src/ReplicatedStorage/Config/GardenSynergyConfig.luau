local Bloom=require(script.Parent.BloomConfig)

local C={
 Recipes={
  {Id="MeadowPair",Name="Meadow Pair",Strength=10,Tier=1,Species={"Daisy","Tulip"},Levels={Daisy=1,Tulip=1},Effect={FlowerGrowthMultiplier=1.08}},
  {Id="GoldenPair",Name="Golden Pair",Strength=12,Tier=1,Species={"Sunflower","Clover"},Levels={Sunflower=1,Clover=1},Effect={CoinMultiplier=1.08}},
  {Id="MeadowFamily",Name="Meadow Family",Strength=20,Tier=2,Species={"Daisy","Tulip","Sunflower"},Levels={Daisy=2,Tulip=2,Sunflower=2},Effect={FlowerGrowthMultiplier=1.16}},
  {Id="MeadowLine",Name="Meadow Line",Strength=26,Tier=2,Species={"Daisy","Tulip","Sunflower","Clover"},Levels={Daisy=2,Tulip=2,Sunflower=2,Clover=2},Effect={FlowerGrowthMultiplier=1.18,CoinMultiplier=1.08}},
  {Id="CrystalTriangle",Name="Crystal Triangle",Strength=34,Tier=3,Species={"CrystalRose","FrostLily","PrismBloom"},Levels={CrystalRose=3,FrostLily=3,PrismBloom=2},Effect={LuckMultiplier=1.10,FlowerGrowthMultiplier=1.12}},
  {Id="TwilightOpposite",Name="Twilight Pair",Strength=42,Tier=4,Species={"Nightshade","VoidLotus"},Levels={Nightshade=4,VoidLotus=4},Effect={PollinatorPowerMultiplier=1.14,CoinMultiplier=1.12}},
  {Id="MeadowRing",Name="Sevenfold Garden",Strength=50,Tier=5,Species={"Daisy","Tulip","Sunflower","Clover","CrystalRose","FrostLily","PrismBloom"},Levels={Daisy=3,Tulip=3,Sunflower=3,Clover=3,CrystalRose=3,FrostLily=3,PrismBloom=3},Effect={FlowerGrowthMultiplier=1.25,PollinatorYieldMultiplier=1.12}},
  {Id="AstralGarden",Name="Astral Garden",Strength=60,Tier=6,Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"},Levels={StarBloom=5,MoonOrchid=5,VoidLotus=5,EmberDahlia=5},Effect={LuckMultiplier=1.18,PollinatorYieldMultiplier=1.18,PollinatorPowerMultiplier=1.15}},
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
