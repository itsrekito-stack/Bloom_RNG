--!strict
local C={}

C.Order={
 "Q01_FirstRolls","Q02_HoneyRoute","Q03_NewFaces","Q04_FieldWork","Q05_FirstBloom",
 "Q06_HiveThree","Q07_FlowerBook","Q08_BeeBook","Q09_SynergyPractice","Q10_WorkshopPath",
 "Q11_RollCentury","Q12_HoneyHundred","Q13_ActiveGarden","Q14_BloomRoutine","Q15_HiveSix",
 "Q16_FlowerHunter","Q17_BeeHunter","Q18_BeeScholar","Q19_SynergyBuilder","Q20_WorkshopBuilder",
 "Q21_RollMachine","Q22_HoneyEngine","Q23_BloomVeteran","Q24_HiveTen","Q25_BloomKeeper",
}

C.Quests={
 Q01_FirstRolls={Title="Warm Up the Roulette",Text="Complete 10 rolls.",Kind="Event",Event="Roll",Target=10,Reward={Coins=150}},
 Q02_HoneyRoute={Title="Honey Route",Text="Complete 15 Hive deliveries.",Kind="Event",Event="Delivery",Target=15,Reward={Coins=250}},
 Q03_NewFaces={Title="Meet the Garden",Text="Discover 5 total Flowers or Bees.",Kind="TotalDiscoveries",Target=5,Reward={PetalDust=5}},
 Q04_FieldWork={Title="Field Work",Text="Complete 3 world Activities.",Kind="Event",Event="ActivityCompleted",Target=3,Reward={Coins=400}},
 Q05_FirstBloom={Title="Bloom Spark",Text="Use 2 Bloom Rolls.",Kind="Event",Event="BloomRoll",Target=2,Reward={WorkshopPoints=1}},
 Q06_HiveThree={Title="Growing Hive",Text="Reach Hive Level 3.",Kind="HiveLevel",Target=3,Reward={Coins=700}},
 Q07_FlowerBook={Title="Flower Journal",Text="Discover 8 Flowers.",Kind="FlowerDiscoveries",Target=8,Reward={PetalDust=10}},
 Q08_BeeBook={Title="Bee Journal",Text="Discover 5 Bees.",Kind="BeeDiscoveries",Target=5,Reward={PetalDust=10}},
 Q09_SynergyPractice={Title="Garden Chemistry",Text="Discover 2 Garden Synergies.",Kind="GardenSynergies",Target=2,Reward={Coins=900}},
 Q10_WorkshopPath={Title="Workshop Route",Text="Purchase 3 Workshop nodes.",Kind="WorkshopNodes",Target=3,Reward={WorkshopPoints=1}},
 Q11_RollCentury={Title="One Hundred Chances",Text="Complete 100 rolls.",Kind="Event",Event="Roll",Target=100,Reward={Coins=1400}},
 Q12_HoneyHundred={Title="Reliable Swarm",Text="Complete 100 Hive deliveries.",Kind="Event",Event="Delivery",Target=100,Reward={Coins=1800}},
 Q13_ActiveGarden={Title="Always Moving",Text="Complete 10 world Activities.",Kind="Event",Event="ActivityCompleted",Target=10,Reward={PetalDust=15}},
 Q14_BloomRoutine={Title="Bloom Routine",Text="Use 8 Bloom Rolls.",Kind="Event",Event="BloomRoll",Target=8,Reward={WorkshopPoints=1,Coins=1000}},
 Q15_HiveSix={Title="Established Hive",Text="Reach Hive Level 6.",Kind="HiveLevel",Target=6,Reward={Coins=3000}},
 Q16_FlowerHunter={Title="Rare Petals",Text="Discover 15 Flowers.",Kind="FlowerDiscoveries",Target=15,Reward={PetalDust=20}},
 Q17_BeeHunter={Title="Swarm Collection",Text="Discover 10 Bees.",Kind="BeeDiscoveries",Target=10,Reward={PetalDust=20}},
 Q18_BeeScholar={Title="Bee Scholar",Text="Reach Bee Mastery Level 4 on any Bee.",Kind="BestBeeMastery",Target=4,Reward={WorkshopPoints=2}},
 Q19_SynergyBuilder={Title="Pattern Builder",Text="Discover 8 Garden Synergies.",Kind="GardenSynergies",Target=8,Reward={Coins=3500,PetalDust=15}},
 Q20_WorkshopBuilder={Title="Permanent Progress",Text="Purchase 8 Workshop nodes.",Kind="WorkshopNodes",Target=8,Reward={WorkshopPoints=2}},
 Q21_RollMachine={Title="Roll Machine",Text="Complete 500 rolls.",Kind="Event",Event="Roll",Target=500,Reward={Coins=6000}},
 Q22_HoneyEngine={Title="Honey Engine",Text="Complete 350 Hive deliveries.",Kind="Event",Event="Delivery",Target=350,Reward={Coins=7500}},
 Q23_BloomVeteran={Title="Bloom Veteran",Text="Use 25 Bloom Rolls.",Kind="Event",Event="BloomRoll",Target=25,Reward={PetalDust=35,AncientNectar=1}},
 Q24_HiveTen={Title="Hive Architect",Text="Reach Hive Level 10.",Kind="HiveLevel",Target=10,Reward={Coins=12000,WorkshopPoints=3}},
 Q25_BloomKeeper={Title="Bloom Keeper",Text="Discover 30 total Flowers or Bees.",Kind="TotalDiscoveries",Target=30,Reward={Coins=25000,PetalDust=50,WorkshopPoints=5,AncientNectar=2}},
}

function C.Get(id:string)
 return C.Quests[id]
end

return table.freeze(C)
