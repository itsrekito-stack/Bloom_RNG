-- Workshop gameplay metadata. Runtime geometry is authored in StarterGui/BloomUI.model.json.
local C={
 Version=6,
 Nodes={},
 NodesPerBranch=6,
 Branches={
  "ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY",
  "FORTUNE","MASTERY","HONEY","COINS","GROWTH","POLLEN","POWER","SWIFT","ABILITY","CRITICAL",
  "CHARGE","DISCOVERY","RARITY","DUPLICATES","ACTIVITY","QUESTS","MUTATION","SEASON","SOCIAL","OVERDRIVE",
 },
 Tree={HexSize=90,HexSpacing=1.4,CanvasWidth=2800,CanvasHeight=2800,BaseRadius=430,RadialStep=150},
 BranchColors={
  ROLL=Color3.fromRGB(88,177,255),GARDEN=Color3.fromRGB(92,202,112),BEES=Color3.fromRGB(255,193,48),
  ECONOMY=Color3.fromRGB(255,187,82),BLOOM=Color3.fromRGB(216,112,255),EXPLORATION=Color3.fromRGB(87,220,211),
  LEGACY=Color3.fromRGB(255,108,131),FORTUNE=Color3.fromRGB(255,216,92),MASTERY=Color3.fromRGB(142,118,255),
  HONEY=Color3.fromRGB(255,171,61),COINS=Color3.fromRGB(255,205,72),GROWTH=Color3.fromRGB(89,211,129),
  POLLEN=Color3.fromRGB(173,225,78),POWER=Color3.fromRGB(255,115,95),SWIFT=Color3.fromRGB(78,194,255),
  ABILITY=Color3.fromRGB(118,160,255),CRITICAL=Color3.fromRGB(255,94,156),CHARGE=Color3.fromRGB(85,234,218),
  DISCOVERY=Color3.fromRGB(109,224,255),RARITY=Color3.fromRGB(238,114,255),DUPLICATES=Color3.fromRGB(188,142,255),
  ACTIVITY=Color3.fromRGB(89,215,174),QUESTS=Color3.fromRGB(116,191,255),MUTATION=Color3.fromRGB(238,104,196),
  SEASON=Color3.fromRGB(255,149,88),SOCIAL=Color3.fromRGB(109,221,184),OVERDRIVE=Color3.fromRGB(255,102,82),
 },
}

local names={
 ROLL={"Roll Tempo","Bloom Reserve","Fast Reveal","Discovery Lens","Roll Rhythm","Overclock"},
 GARDEN={"Healthy Soil","Garden Fortune","Quick Replant","Deep Roots","Pattern Lens","Living Garden"},
 BEES={"Stronger Wings","Ability Tokens","Mastery Practice","Trait Depth","Rich Nectar","Swarm Protocol"},
 ECONOMY={"Coin Sense","Honey Storage","Nectar Refining","Milestone Chest","Prosperity I","Prosperity II"},
 BLOOM={"Mutation Slot","Active Nectar","Rare Seed Rule","Charge Reserve","Mutation Study","Signature Rule"},
 EXPLORATION={"Event Radar","Route Bonus","Crystal Interaction","Wild Bloom Sense","Twilight Interaction","Wayfinder"},
 LEGACY={"Season Memory","Keepsake","Legacy Mutation","Quest Bounty","Third Memory","Season Scholar"},
 FORTUNE={"Lucky Start","Lucky Roots","Lucky Swarm","Lucky Garden","Lucky Bloom","Fortune Crown"},
 MASTERY={"Study Notes","Practice Loop","Expert Hands","Deep Study","Mastery Engine","Grandmaster"},
 HONEY={"Sweet Cells","Honey Flow","Wax Reserve","Golden Comb","Royal Storage","Endless Honey"},
 COINS={"Pocket Change","Coin Trail","Profit Bloom","Golden Route","Rich Harvest","Prosperity Crown"},
 GROWTH={"Rich Soil","Fast Roots","Deep Bed","Verdant Pulse","Ancient Soil","Eternal Garden"},
 POLLEN={"Soft Pollen","Dense Pollen","Rich Pollen","Pollen Storm","Golden Pollen","Infinite Pollen"},
 POWER={"Strong Wings","Heavy Work","Power Cycle","Force Bloom","Royal Force","Apex Swarm"},
 SWIFT={"Quick Wings","Fast Route","Slipstream","Wind Line","Flash Flight","Light Speed"},
 ABILITY={"Quick Trigger","Short Cycle","Ability Flow","Cooldown Core","Rapid Cast","Perfect Rhythm"},
 CRITICAL={"Sharp Instinct","Lucky Hit","Critical Bloom","Royal Crit","Celestial Strike","Perfect Hit"},
 CHARGE={"Spark Charge","Bloom Battery","Charge Flow","Bloom Reactor","Overcharge Core","Endless Charge"},
 DISCOVERY={"Curious Eye","New Scent","Hidden Petal","Scout Instinct","Discovery Lens","Collector Vision"},
 RARITY={"Rare Sense","Epic Signal","Legendary Pull","Mythic Echo","Celestial Trace","Fate Distortion"},
 DUPLICATES={"Spare Value","Recycle Study","Duplicate XP","Memory Copy","Echo Mastery","Perfect Reuse"},
 ACTIVITY={"Field Radar","Fast Events","Busy Garden","Activity Rush","World Pulse","Endless Motion"},
 QUESTS={"Small Bounty","Better Rewards","Quest Momentum","Hero Pay","Grand Bounty","Bloom Legend"},
 MUTATION={"Unstable Seed","Radiant Touch","Mutation Study","Bloom Shift","Astral Gene","Perfect Mutation"},
 SEASON={"Season Start","Season Memory","Nectar Reserve","Legacy Yield","Season Crown","Eternal Cycle"},
 SOCIAL={"Friendly Hive","Shared Pollen","Neighbour Gift","Hive Blessing","Community Bloom","United Garden"},
 OVERDRIVE={"Ability Spark","Ability Yield","Overcharge Flow","Burst Harvest","Perfect Ability","Swarm Overdrive"},
}

local HIVE_BY_INDEX={1,2,3,5,7,9}
local COINS_BY_INDEX={100,250,700,1800,4500,10000}
local DUST_BRANCHES={ECONOMY=true,BLOOM=true,FORTUNE=true,MASTERY=true,DISCOVERY=true,RARITY=true,DUPLICATES=true,MUTATION=true}
local PERMANENT_BRANCHES={LEGACY=true}

C.Nodes.CORE={Id="CORE",Name="Bloom Core",Cost=0,Branch="CORE",Index=0,IconKey="Core"}

for b,branch in ipairs(C.Branches) do
 for i,name in ipairs(names[branch]) do
  local id=branch.."_"..i
  local nectar=0
  if branch=="LEGACY" then nectar=i
  elseif branch=="SEASON" then nectar=math.max(0,math.ceil((i-2)/2)) end
  C.Nodes[id]={
   Id=id,Name=name,Branch=branch,Index=i,Cost=1,
   Coins=COINS_BY_INDEX[i] or 0,
   Dust=DUST_BRANCHES[branch] and math.ceil(i*2.5) or 0,
   Nectar=nectar,
   Parent=i==1 and "CORE" or branch.."_"..(i-1),
   Hive=HIVE_BY_INDEX[i],
   Angle=(b-1)*math.pi*2/#C.Branches,
   Radius=C.Tree.BaseRadius+(i-1)*C.Tree.RadialStep,
   Permanent=PERMANENT_BRANCHES[branch]==true,
   IconKey=id,
  }
 end
end

return C
