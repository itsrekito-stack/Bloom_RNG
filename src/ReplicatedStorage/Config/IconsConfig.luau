--!strict
local C={}
local function asset(id:number):string return id>0 and("rbxassetid://"..id)or""end
local function thumb(id:number):string return id>0 and("rbxthumb://type=Asset&id="..id.."&w=420&h=420")or""end

C.Ids={
Fruits={Apple=137259411920180,Banana=120948463128434,Lemon=103009882213725,Pear=92207064875831,Kiwi=70401616307003,Watermelon=100292298966757,Coconut=113261714314494,Pomegranate=123178380279789,Dragonfruit=94108458069090,Peach=77058315830936,Grape=109914546442995,Pineapple=130286215947765,Starfruit=129937365073228},
Bees={WorkerBee=120474399887250,SprinterBee=81841357837322,NectarBee=125666499506926,ScholarBee=113247515668453,TwinBee=79186329071015,RoyalBee=90863269031200,PrismBee=71487091178305,TwilightBee=114763891690754,BloomQueenBee=111205051533608,CrystalBee=105869326934726,MagmaBee=138449294199376,ShadowBee=133728580716533,StormBee=94635050980764,GardenerBee=0,CourierBee=0,ScoutBee=0,DewBee=0,MinerBee=0,MelodyBee=0,LanternBee=0,MossBee=0,SapphireBee=0,AuroraBee=0,CometBee=0,OracleBee=0,NovaBee=0,ChronoBee=0,SeraphBee=0},

-- New uploaded UI set.
Actions={Roll=125311014921608,AutoRoll=95369396982504},
Menus={Index=95009714203350,Inventory=124063432113598,Workshop=121024323846687,Settings=74677124320045,Shop=88512137472413},
Currencies={Coins=110435036629715,FruitDust=111742972197656},
System={
 ArrowLeft=77190512602362,
 ArrowRight=122373491010297,
 Bee=89451566883771,
 Close=136238101956753,
 Confirm=112568733630169,
 Flower=117046422836136,
 Garden=74690198578201,
 Hive=112708830524820,
 Info=72782667939249,
 Lock=139746584718669,
 Minus=120883253848128,
 Plus=123220293807442,
 Quests=131527836752075,
 Settings=74677124320045,
 Shop=88512137472413,
 Tutorial=110567723791302,
 Upgrade=131390447056966,
 Warning=72509884923996,
},
Traits={
 Arcane=107235778675419,
 Bloom=98986636122613,
 Meadow=94835696478747,
 Mirror=139563396062519,
 Royal=96988868577523,
 Twilight=90171956399486,
 -- Swift has no uploaded icon yet; UI automatically falls back to its letter.
},
WorkshopHex={
Core=71682727693014,Luck=73022903468214,Roll=96003454739859,AutoRoll=119772472490649,
Economy=130962287537873,Garden=95197859726989,Duplicate=79588703542322,FruitDust=85961992422194,
Loadout=77453527674761,Locked=135546891455390,LockedRoll=135546891455390,LockedGarden=135546891455390,LockedBees=135546891455390,LockedEconomy=135546891455390,LockedBloom=135546891455390,LockedExploration=135546891455390,LockedLegacy=135546891455390,Mastery=85961992422194,Bee=82707654930156,BeeHexagon=82707654930156,
},
}

function C.GetFruitIcon(id:string):string local v=C.Ids.Fruits[id]return typeof(v)=="number"and asset(v)or""end
function C.GetBeeIcon(id:string):string local v=C.Ids.Bees[id]local icon=typeof(v)=="number"and thumb(v)or"" return icon~=""and icon or thumb(C.Ids.System.Bee or 0)end
function C.GetActionIcon(id:string):string local v=C.Ids.Actions[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetMenuIcon(id:string):string local v=C.Ids.Menus[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetCurrencyIcon(id:string):string local v=C.Ids.Currencies[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetSystemIcon(id:string):string local v=C.Ids.System[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetTraitIcon(id:string):string local v=C.Ids.Traits[id]return typeof(v)=="number"and thumb(v)or""end
function C.GetWorkshopHexIcon(id:string):string local v=C.Ids.WorkshopHex[id]return typeof(v)=="number"and thumb(v)or""end

C.WorkshopNodeIcons={
 CORE="Core",
 ROLL_1="Roll",ROLL_2="Mastery",ROLL_3="Roll",ROLL_4="Luck",ROLL_5="AutoRoll",ROLL_6="AutoRoll",
 GARDEN_1="Garden",GARDEN_2="Garden",GARDEN_3="Garden",GARDEN_4="Garden",GARDEN_5="Luck",GARDEN_6="Garden",
 BEES_1="BeeHexagon",BEES_2="BeeHexagon",BEES_3="BeeHexagon",BEES_4="BeeHexagon",BEES_5="BeeHexagon",BEES_6="BeeHexagon",
 ECONOMY_1="Duplicate",ECONOMY_2="Duplicate",ECONOMY_3="Duplicate",ECONOMY_4="Economy",ECONOMY_5="FruitDust",ECONOMY_6="Economy",
 BLOOM_1="Mastery",BLOOM_2="Garden",BLOOM_3="Luck",BLOOM_4="Mastery",BLOOM_5="Mastery",BLOOM_6="Luck",
 EXPLORATION_1="Luck",EXPLORATION_2="Loadout",EXPLORATION_3="Luck",EXPLORATION_4="Garden",EXPLORATION_5="Luck",EXPLORATION_6="Loadout",
 LEGACY_1="Loadout",LEGACY_2="Loadout",LEGACY_3="Mastery",LEGACY_4="Loadout",LEGACY_5="Loadout",LEGACY_6="Mastery",
}
C.WorkshopLockedBranchIcons={
 ROLL="LockedRoll",GARDEN="LockedGarden",BEES="LockedBees",ECONOMY="LockedEconomy",BLOOM="LockedBloom",EXPLORATION="LockedExploration",LEGACY="LockedLegacy",
}
function C.GetWorkshopNodeIcon(nodeId:string,locked:boolean?):string
 if locked then
  local branch=string.match(nodeId,"^([^_]+)") or ""
  return C.GetWorkshopHexIcon(C.WorkshopLockedBranchIcons[branch] or "Locked")
 end
 local key=C.WorkshopNodeIcons[nodeId] or "Locked"
 return C.GetWorkshopHexIcon(key)
end

-- All IDs are from the supplied project. Zero means no uploaded asset yet.
C.Ids.LegacyFruits=C.Ids.Fruits
C.Ids.Flowers={Daisy=0,Tulip=0,Sunflower=0,Clover=0,CrystalRose=0,FrostLily=0,PrismBloom=0,MoonOrchid=0,Nightshade=0,VoidLotus=0,StarBloom=0,EmberDahlia=0,Bluebell=0,HoneyPoppy=0,MintDaisy=0,AmberCrocus=0,RainIris=0,VelvetPeony=0,GlassTulip=0,AuroraLily=0,SapphireMoss=0,DreamOrchid=0,EchoFern=0,SolarLotus=0,CometRose=0,NebulaDahlia=0,CrownBloom=0}
C.Ids.Activities={PollenSpark=0,NectarBud=0,DewDrop=0,PollenTrail=0,CrossPollination=0,Overcharge=0,BloomSurge=0,PollenWind=0,SolarBloom=0,CrystalResonance=0,FireflyRoute=0,ShadowBloom=0}
C.Ids.Seasons={SpringResonance=0,SummerSwarm=0,AutumnFortune=0,CrystalSeason=0,TwilightSeason=0}
C.Ids.Currencies.PetalDust=C.Ids.Currencies.FruitDust C.Ids.Currencies.AncientNectar=0
C.Ids.Menus.SeedSatchel=C.Ids.Menus.Inventory C.Ids.Menus.FieldGuide=C.Ids.System.Flower C.Ids.Menus.Map=0 C.Ids.Menus.Trials=C.Ids.System.Quests C.Ids.Menus.Garden=C.Ids.System.Garden C.Ids.Menus.Hive=C.Ids.System.Hive
C.Ids.Traits.Swift=0
function C.Get(group,id) local t=C.Ids[group] local value=t and t[id] if type(value)~="number" or value<=0 then return "" end return group=="Fruits" and asset(value) or thumb(value) end
function C.GetFlowerIcon(id) local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end
function C.GetRewardIcon(kind,id) if kind=="Bee" then return C.Get("Bees",id) end local icon=C.Get("Flowers",id) return icon~="" and icon or C.Get("System","Flower") end
return C
