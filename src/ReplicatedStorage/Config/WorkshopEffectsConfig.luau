-- Numeric values here are the single runtime source of truth for Workshop effects.
local E={
 ROLL_1={RollCooldown=1.4},ROLL_2={Reserve=10},ROLL_3={RevealScale=.70},ROLL_4={Feature="PityDetails"},ROLL_5={RollCooldown=1.2},ROLL_6={RollCooldown=.8},
 GARDEN_1={FlowerGrowthMultiplier=1.06},GARDEN_2={LuckMultiplier=1.03},GARDEN_3={Feature="RepeatPlant"},GARDEN_4={FlowerGrowthMultiplier=1.12},GARDEN_5={Feature="PatternHints"},GARDEN_6={PollinatorYieldMultiplier=1.10},
 BEES_1={PollinatorPowerMultiplier=1.08},BEES_2={Feature="GuaranteedAbilityToken"},BEES_3={BeeXP=2},BEES_4={TraitCooldown=.9},BEES_5={PollinatorYieldMultiplier=1.12},BEES_6={AbilityYield=1.2},
 ECONOMY_1={CoinYield=1.05},ECONOMY_2={HiveHoneyMultiplier=1.05},ECONOMY_3={DustYield=1.2},ECONOMY_4={MilestoneCoins=100},ECONOMY_5={CoinYield=1.10},ECONOMY_6={CoinYield=1.15},
 BLOOM_1={Feature="SeedMutation"},BLOOM_2={ManualCharge=1.2},BLOOM_3={NewWeight=1.2},BLOOM_4={Reserve=10},BLOOM_5={MutationChance=.1},BLOOM_6={SignatureWeight=1.5},
 EXPLORATION_1={Feature="EventRadar"},EXPLORATION_2={RouteCharge=1.2},EXPLORATION_3={CrystalSeconds=20},EXPLORATION_4={WildInterval=.8},EXPLORATION_5={EclipseWeight=1.3},EXPLORATION_6={Feature="LaunchPads"},
 LEGACY_1={Feature="KeepSeasonCard"},LEGACY_2={MemoryMastery=25},LEGACY_3={Feature="MemoryMutation"},LEGACY_4={QuestRewardMultiplier=1.25},LEGACY_5={Feature="ThirdMemory"},LEGACY_6={SeasonNectar=2},
}

local branchDefs={
 FORTUNE={Key="LuckMultiplier",Values={1.04,1.05,1.06,1.07,1.08,1.10}},
 MASTERY={Key="MasteryXPMultiplier",Values={1.08,1.10,1.12,1.15,1.18,1.22}},
 HONEY={Key="HiveHoneyMultiplier",Values={1.04,1.05,1.06,1.07,1.08,1.10}},
 COINS={Key="CoinMultiplier",Values={1.04,1.05,1.06,1.07,1.08,1.10}},
 GROWTH={Key="FlowerGrowthMultiplier",Values={1.03,1.04,1.05,1.06,1.07,1.09}},
 POLLEN={Key="PollinatorYieldMultiplier",Values={1.03,1.04,1.05,1.06,1.07,1.09}},
 POWER={Key="PollinatorPowerMultiplier",Values={1.03,1.04,1.05,1.06,1.07,1.09}},
 SWIFT={Key="PollinatorTravelSpeedMultiplier",Values={1.02,1.03,1.04,1.05,1.06,1.08}},
 ABILITY={Key="AbilityCooldownMultiplier",Values={.98,.97,.96,.95,.94,.92}},
 CRITICAL={Key="CriticalChance",Values={.01,.01,.015,.015,.02,.03}},
 CHARGE={Key="BloomChargeMultiplier",Values={1.04,1.05,1.06,1.07,1.08,1.10}},
 DISCOVERY={Key="DiscoveryWeightMultiplier",Values={1.05,1.07,1.09,1.12,1.15,1.20}},
 RARITY={Key="RareWeightMultiplier",Values={1.04,1.06,1.08,1.10,1.13,1.18}},
 DUPLICATES={Key="DuplicateXPMultiplier",Values={1.08,1.10,1.12,1.15,1.18,1.22}},
 ACTIVITY={Key="ActivityIntervalMultiplier",Values={.98,.97,.96,.95,.94,.92}},
 QUESTS={Key="QuestRewardMultiplier",Values={1.05,1.06,1.07,1.08,1.10,1.12}},
 MUTATION={Key="MutationChance",Values={.01,.01,.015,.02,.025,.03}},
 SEASON={Key="SeasonRewardMultiplier",Values={1.03,1.04,1.05,1.06,1.08,1.10}},
 SOCIAL={Key="BlessingMultiplier",Values={1.02,1.03,1.04,1.05,1.06,1.08}},
 OVERDRIVE={Key="AbilityRewardMultiplier",Values={1.04,1.05,1.06,1.07,1.08,1.10}},
}
for branch,def in pairs(branchDefs) do
 for i,value in ipairs(def.Values) do E[branch.."_"..i]={[def.Key]=value} end
end
return table.freeze(E)
