local Bloom=require(script.Parent.BloomConfig)

local C={
 Recipes={
  {Id="MeadowPair",Kind="Pair",Species={"Daisy","Tulip"}},
  {Id="GoldenPair",Kind="Pair",Species={"Sunflower","Clover"}},
  {Id="MeadowFamily",Kind="Family",Tag="Meadow",Count=3},
  {Id="CrystalTriangle",Kind="Pattern",Tag="Crystal",Slots={1,2,6}},
  {Id="MeadowLine",Kind="Pattern",Tag="Meadow",Slots={1,2,3}},
  {Id="MeadowRing",Kind="Pattern",Tag="Meadow",Slots={1,2,3,8,13,12,11,6}},
  {Id="TwilightOpposite",Kind="Pattern",Tag="Twilight",Slots={1,15}},
  {Id="MeadowSwarm",Kind="Bee",Tag="Meadow",Trait="Meadow",Count=2},
  {Id="CrystalResonance",Kind="Biome",Tag="Crystal",Biome="CrystalGreenhouse"},
  {Id="AstralGarden",Kind="Signature",Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"}},
 },
 Layout={
  InnerCount=5,
  InnerRadius=6,
  OuterRadius=11.45,
  SlotY=.10,
  HiveOffset=Vector3.new(21,2.87,0),
 }
}

function C.Position(i)
 if type(i)~="number" or i%1~=0 or i<1 or i>Bloom.MaxFlowerSlots then return Vector3.zero end
 local layout=C.Layout
 local count
 local index
 local radius
 local phase=-math.pi/2
 if i<=layout.InnerCount then
  count=layout.InnerCount
  index=i-1
  radius=layout.InnerRadius
 else
  count=Bloom.MaxFlowerSlots-layout.InnerCount
  index=i-layout.InnerCount-1
  radius=layout.OuterRadius
  phase+=math.pi/count
 end
 local angle=phase+(index/count)*math.pi*2
 return Vector3.new(math.cos(angle)*radius,layout.SlotY,math.sin(angle)*radius)
end

function C.LogicalPosition(i)
 return Vector3.new(((i-1)%5-2)*7,0,(math.floor((i-1)/5)-1)*7)
end

function C.Adjacent(a,b,range)
 local x,y=C.LogicalPosition(a),C.LogicalPosition(b)
 return a~=b and (x-y).Magnitude<=7.1*(range or 1)
end

return C
