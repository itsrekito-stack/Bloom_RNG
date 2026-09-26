local Bloom=require(script.Parent.BloomConfig)

local C={
 Recipes={
  {Id="MeadowPair",Kind="Pair",Species={"Daisy","Tulip"}},
  {Id="GoldenPair",Kind="Pair",Species={"Sunflower","Clover"}},
  {Id="MeadowFamily",Kind="Family",Tag="Meadow",Count=3},
  {Id="CrystalTriangle",Kind="Pattern",Tag="Crystal",Slots={1,2,6}},
  {Id="MeadowLine",Kind="Pattern",Tag="Meadow",Slots={1,2,3}},
  {Id="MeadowRing",Kind="Pattern",Tag="Meadow",Slots={1,2,3,4,5,6,7,8}},
  {Id="TwilightOpposite",Kind="Pattern",Tag="Twilight",Slots={1,5}},
  {Id="MeadowSwarm",Kind="Bee",Tag="Meadow",Trait="Meadow",Count=2},
  {Id="CrystalResonance",Kind="Biome",Tag="Crystal",Biome="CrystalGreenhouse"},
  {Id="AstralGarden",Kind="Signature",Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"}},
 },
 Layout={
  Radius=8.1,
  SlotY=.10,
  HiveOffset=Vector3.new(13.9,2.07,0),
 }
}

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
