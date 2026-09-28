local C={
 SchemaVersion=7,
 MaxFlowerSlots=7,
 StartingSlots=0,
 MaxBeeSlots=8,
 MasteryCap=100,
 MasteryXP=25,
 FlowerLevelXP=20,
 FlowerDuplicateXP=25,
 BeeDuplicateXP=20,
 RollCooldown=1.55,
 MinRollCooldown=.45,
 DiscoveryThreshold=30,
 DiscoveryPityMaxRarity="Epic",
 BloomMax=100,
 SpecialRareMultiplier=2,
 SpecialNewMultiplier=2,
 SpecialMutationChance=.12,
 UnknownCopyDust=5,
 ComboCompensation=5,
 DustPerCopy=3,
 BeeDustPerCopy=5,
 TickSeconds=.5,
 DeliverySeconds=8,
 HoneyPerDelivery=4,
 CoinsPerDelivery=6,
 ActivityInterval=18,
 SyncSeconds=1,
 PublicSyncSeconds=1,
 PublicReplicationRadius=180,
 InteractionDistance=14,
 RemoteBurst=12,
 RemoteRate=6,
 HiveCosts={0,40,100,220,450,850,1500,2500},
 HiveCoinCosts={0,60,180,450,1000,2000,3500,6000},
 GardenSlotHiveMilestones={2,3,4,5,6,7},
 BeeSlotHiveMilestones={2,3,4,5,6,7,8},
 WorkshopPointHiveMilestones={[2]=2,[4]=1,[6]=1,[8]=2},
 EndlessHiveCostGrowth=1.35,
 EndlessHiveCostRound=50,
 EndlessHiveCoinGrowth=1.70,
 EndlessHiveCoinRound=100,
 EndlessHivePointsPerLevel=1,
 HiveQuestRequirements={
  [2]={Discoveries=2},
  [3]={Discoveries=4},
  [4]={Synergies=1},
  [5]={BeeMasteryLevel=2},
  [6]={Activities=3},
  [7]={Discoveries=10},
  [8]={Quests=6},
 },
 Charge={Delivery=2,Token=4,Nectar=6,World=12,Event=15},
 SeasonReward=5,
 NectarDistillCost=1,
 NectarDistillDust=10,
 ActivityBurstCoins=5,
 CloverBurstCoins=3,
 NeighbourBonus=1.15,
 NeighbourSeconds=20,
 SwiftBonus=1.2,
 SwiftSeconds=15,
 MaxBlessings=1,
 BlessingSeconds=60,
 BlessingMultiplier=1.05,
 WorldCooldown=25,
 LandmarkDust=3,
 LandmarkCharge=10,
 JourneyCoins=10,
 AbilityTokenChance=.6,
 RollRhythmCooldown=1.2,
 OverclockCooldown=.8,
}

function C.HiveUpgradeCost(nextLevel)
 local level=math.max(2,math.floor(tonumber(nextLevel) or 2))
 local fixed=C.HiveCosts[level]
 if fixed then return fixed end
 local extra=level-#C.HiveCosts
 local base=C.HiveCosts[#C.HiveCosts] or 2500
 local growth=math.max(1,tonumber(C.EndlessHiveCostGrowth) or 1.35)
 local roundTo=math.max(1,math.floor(tonumber(C.EndlessHiveCostRound) or 50))
 local raw=base*(growth^extra)
 return math.max(base,math.floor(raw/roundTo+.5)*roundTo)
end

function C.HiveCoinCost(nextLevel)
 local level=math.max(2,math.floor(tonumber(nextLevel) or 2))
 local fixed=C.HiveCoinCosts[level]
 if fixed then return fixed end
 local extra=level-#C.HiveCoinCosts
 local base=C.HiveCoinCosts[#C.HiveCoinCosts] or 6000
 local growth=math.max(1,tonumber(C.EndlessHiveCoinGrowth) or 1.70)
 local roundTo=math.max(1,math.floor(tonumber(C.EndlessHiveCoinRound) or 100))
 local raw=base*(growth^extra)
 return math.max(base,math.floor(raw/roundTo+.5)*roundTo)
end

function C.WorkshopPointsForHiveLevel(level)
 local n=math.max(1,math.floor(tonumber(level) or 1))
 local milestone=C.WorkshopPointHiveMilestones[n]
 if milestone then return milestone end
 if n>#C.HiveCosts then return math.max(0,math.floor(tonumber(C.EndlessHivePointsPerLevel) or 1)) end
 return 0
end

return C
