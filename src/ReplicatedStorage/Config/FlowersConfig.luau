--!strict
local C={Species={}}
local function s(id:string,name:string,rarity:string,shape:string,color:Color3,yield:number,sectors:{string},accent:Color3?)
 local a={}for _,x in ipairs(sectors)do a[x]=true end
 C.Species[id]={Id=id,DisplayName=name,Rarity=rarity,ShapeKey=shape,Color=color,AccentColor=accent or color:Lerp(Color3.new(1,1,1),.35),BaseYield=yield,AllowedSectors=a}
end
s("Daisy","Daisy","Common","Daisy",Color3.fromRGB(245,245,245),.20,{"StarterOrchard"},Color3.fromRGB(245,210,80))
s("Tulip","Tulip","Common","Tulip",Color3.fromRGB(235,80,100),.25,{"StarterOrchard"},Color3.fromRGB(255,176,84))
s("Sunflower","Sunflower","Uncommon","Sunflower",Color3.fromRGB(245,190,45),.35,{"StarterOrchard"},Color3.fromRGB(95,64,24))
s("Clover","Clover","Uncommon","Clover",Color3.fromRGB(80,210,100),.30,{"StarterOrchard"},Color3.fromRGB(140,255,165))
s("CrystalRose","Crystal Rose","Rare","CrystalRose",Color3.fromRGB(120,220,255),.48,{"CrystalGreenhouse"},Color3.fromRGB(210,247,255))
s("FrostLily","Frost Lily","Rare","FrostLily",Color3.fromRGB(190,235,255),.52,{"CrystalGreenhouse"},Color3.fromRGB(255,255,255))
s("PrismBloom","Prism Bloom","Epic","PrismBloom",Color3.fromRGB(185,120,255),.60,{"CrystalGreenhouse"},Color3.fromRGB(255,153,218))
s("MoonOrchid","Moon Orchid","Epic","MoonOrchid",Color3.fromRGB(110,145,255),.66,{"CrystalGreenhouse"},Color3.fromRGB(213,230,255))
s("Nightshade","Nightshade","Legendary","Nightshade",Color3.fromRGB(105,55,145),.82,{"TwilightGrove"},Color3.fromRGB(160,110,255))
s("VoidLotus","Void Lotus","Legendary","VoidLotus",Color3.fromRGB(80,40,115),.90,{"TwilightGrove"},Color3.fromRGB(220,120,255))
s("StarBloom","Star Bloom","Mythic","StarBloom",Color3.fromRGB(255,210,105),1.05,{"TwilightGrove"},Color3.fromRGB(255,248,195))
s("EmberDahlia","Ember Dahlia","Mythic","EmberDahlia",Color3.fromRGB(255,95,65),1.15,{"TwilightGrove"},Color3.fromRGB(255,190,105))
function C.GetSpecies(id:string)local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C.Species[id]end
function C.Exists(id:string):boolean local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C.Species[id]~=nil end
local weights={Daisy=280000,Tulip=220000,Sunflower=170000,Clover=130000,CrystalRose=40000,FrostLily=13330,PrismBloom=6670,MoonOrchid=3330,Nightshade=670,VoidLotus=200,StarBloom=40,EmberDahlia=20}
for id,f in pairs(C.Species) do
 f.DropWeight=weights[id] f.AllowedBiomes={} for sector in pairs(f.AllowedSectors) do f.AllowedBiomes[sector=="StarterOrchard" and "SunnyOrchard" or sector]=true end
 f.GrowthProfile={XPPerLevel=20,MaxLevel=100,ScalePerLevel=.025}
 f.Tags={f.AllowedBiomes.CrystalGreenhouse and "Crystal" or f.AllowedBiomes.TwilightGrove and "Twilight" or "Meadow"}
 f.PollinationEffect=({Daisy="NeighbourBoost",Sunflower="SwiftWindow",Clover="CoinPod",MoonOrchid="LuckDew",StarBloom="Astral",EmberDahlia="Pulse"})[id] or "Nectar"
 f.AdjacencyRules={Range=1} f.MutationPool={"Dewkissed","Radiant","Astral"} f.Model=f.ShapeKey f.Colors={Primary=f.Color,Accent=f.AccentColor} f.VFX={Color=f.AccentColor}
end
return C
