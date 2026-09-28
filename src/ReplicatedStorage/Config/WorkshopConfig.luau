-- Tree is legacy/default layout metadata only; runtime Workshop geometry is authored in StarterGui/BloomUI.model.json.
local C={
 Version=5,
 Nodes={},
 Branches={"ROLL","GARDEN","BEES","ECONOMY","BLOOM","EXPLORATION","LEGACY"},
 Tree={HexSize=90,HexSpacing=1.4,CanvasWidth=2200,CanvasHeight=1700,BaseRadius=190,RadialStep=135},
}

local names={
 ROLL={"Roll Tempo","Bloom Reserve","Fast Reveal","Discovery Lens","Roll Rhythm","Overclock"},
 GARDEN={"Healthy Soil","Garden Fortune","Quick Replant","Deep Roots","Pattern Lens","Living Garden"},
 BEES={"Stronger Wings","Ability Tokens","Mastery Practice","Trait Depth","Rich Nectar","Swarm Protocol"},
 ECONOMY={"Coin Sense","Honey Storage","Nectar Refining","Milestone Chest","Prosperity I","Prosperity II"},
 BLOOM={"Mutation Slot","Active Nectar","Rare Seed Rule","Charge Reserve","Mutation Study","Signature Rule"},
 EXPLORATION={"Event Radar","Route Bonus","Crystal Interaction","Wild Bloom Sense","Twilight Interaction","Wayfinder"},
 LEGACY={"Season Memory","Keepsake","Legacy Mutation","Advanced Trials","Third Memory","Season Scholar"},
}

-- Six nodes should span the midgame instead of collapsing into Hive 1-3.
-- The final two nodes share Hive 5 so complete branches are available before
-- the Hive 8 Season Turn requirement.
local HIVE_BY_INDEX={1,2,3,4,5,5}

C.Nodes.CORE={Id="CORE",Name="Bloom Core",Cost=0,Branch="CORE",Index=0,IconKey="Core"}

for b,branch in ipairs(C.Branches) do
 for i,name in ipairs(names[branch]) do
  local id=branch.."_"..i
  C.Nodes[id]={
   Id=id,
   Name=name,
   Branch=branch,
   Index=i,
   Cost=1,
   Coins=i*30,
   Dust=(branch=="ECONOMY" or branch=="BLOOM") and i*3 or 0,
   Nectar=branch=="LEGACY" and i or 0,
   Parent=i==1 and "CORE" or branch.."_"..(i-1),
   Hive=HIVE_BY_INDEX[i],
   Angle=(b-1)*math.pi*2/7,
   Radius=132+(i-1)*92,
   Permanent=branch=="LEGACY",
   IconKey=id,
  }
 end
end

return C
