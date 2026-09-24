local C={Recipes={
{Id="MeadowPair",Kind="Pair",Species={"Daisy","Tulip"}},
{Id="GoldenPair",Kind="Pair",Species={"Sunflower","Clover"}},
{Id="MeadowFamily",Kind="Family",Tag="Meadow",Count=3},
{Id="CrystalTriangle",Kind="Pattern",Tag="Crystal",Slots={1,2,6}},
{Id="MeadowLine",Kind="Pattern",Tag="Meadow",Slots={1,2,3}},
{Id="MeadowRing",Kind="Pattern",Tag="Meadow",Slots={1,2,3,8,13,12,11,6}},
{Id="TwilightOpposite",Kind="Pattern",Tag="Twilight",Slots={1,15}},
{Id="MeadowSwarm",Kind="Bee",Tag="Meadow",Trait="Meadow",Count=2},
{Id="CrystalResonance",Kind="Biome",Tag="Crystal",Biome="CrystalGreenhouse"},
{Id="AstralGarden",Kind="Signature",Species={"StarBloom","MoonOrchid","VoidLotus","EmberDahlia"}}
}}
function C.Position(i) return Vector3.new(((i-1)%5-2)*7,0,(math.floor((i-1)/5)-1)*7) end
function C.Adjacent(a,b,range) local x,y=C.Position(a),C.Position(b) return a~=b and (x-y).Magnitude<=7.1*(range or 1) end
return C
