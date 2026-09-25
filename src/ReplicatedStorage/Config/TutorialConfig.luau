local Steps={
 {Id="HiveIntro",Event="HiveApproach",Text="Welcome to Bloom RNG. This is your Hive.",Helper="Walk to the highlighted Hive.",Target="Hive"},
 {Id="StarterBee",Event="StarterBee",Text="Claim your first Bee.",Helper="Use the Hive interaction to claim your Worker Bee.",Target="Hive"},
 {Id="BeeWork",Event="Work",Text="Your Bee automatically pollinates flowers.",Helper="Watch the highlighted Bee reach a flower.",Target="Bee"},
 {Id="PollenSpark",Event="PollenSpark",Text="Touch the glowing Pollen Spark.",Helper="Walk into the highlighted sphere. No key press is needed.",Target="TutorialToken"},
 {Id="Roll",Event="Roll",Text="Start rolling for Flowers and Bees.",Helper="Click the highlighted Roll button.",Target="Roll"},
 {Id="FirstSeed",Event="SeedReward",Text="You found a Flower Seed.",Helper="Seeds can be planted in your Garden.",Target="RouletteReward"},
 {Id="Plant",Event="Plant",Text="Plant your Flower.",Helper="Go to the highlighted empty bed and plant the seed.",Target="GardenSlot",Slot=3},
 {Id="Inventory",Event="SatchelOpen",Text="Open your Inventory.",Helper="Open the highlighted Inventory button.",Target="SeedSatchel"},
 {Id="InventoryExplain",Event="InventoryReviewed",Text="Learn what your Inventory shows.",Helper="Owned is total copies, Available is unplanted copies, and Mastery is long-term growth. Close Inventory when ready.",Target="InventoryStats"},
 {Id="Delivery",Event="Delivery",Text="Deliver Honey to grow your Hive.",Helper="Your Bee works automatically. Watch it return to the Hive.",Target="Hive"},
 {Id="HiveUpgrade",Event="HiveUpgrade",Text="Upgrade your Hive to unlock new areas.",Helper="Use the Hive interaction. The tutorial delivery covers this upgrade.",Target="Hive"},
 {Id="WorkshopVisit",Event="WorkshopVisit",Text="Spend upgrade points in the Workshop.",Helper="Follow the beam to the Workshop in the center.",Target="Workshop"},
 {Id="WorkshopPurchase",Event="WorkshopPurchase",Text="Buy your first Workshop node.",Helper="Select the highlighted affordable node. Click it again to buy.",Target="WorkshopNode",NodeId="ROLL_1"},
 {Id="Synergy",Event="Synergy",Text="Certain Flowers become stronger when planted together.",Helper="Plant the guaranteed Tulip beside your Daisy.",Target="SynergySlot",Slot=2,PartnerSlot=1},
 {Id="SunnyVisit",Event="SunnyVisit",Text="Your Hive unlocks new locations.",Helper="Unlock the highlighted gate if needed, then enter Sunny Orchard.",Target="SunnyOrchard"},
}
local IndexById={}
for i,step in ipairs(Steps) do IndexById[step.Id]=i end
return {Version=4,Steps=Steps,IndexById=IndexById}
