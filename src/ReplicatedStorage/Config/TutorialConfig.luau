local Steps={
 {Id="HiveIntro",Event="HiveApproach",Text="Welcome to Bloom RNG. This is your Hive.",Helper="Walk to the highlighted Hive.",Target="Hive"},
 {Id="GardenSlot",Event="FirstGardenSlot",Text="Unlock your first Garden slot.",Helper="Use the Hive to unlock Garden Slot 1.",Target="Hive"},
 {Id="FirstFlowerRoll",Event="TutorialFlowerRoll",Text="Roll for your first Flower.",Helper="This tutorial Roll contains only Flowers.",Target="Roll"},
 {Id="Plant",Event="Plant",Text="Plant your first Flower.",Helper="Go to Garden Slot 1 and plant the Flower.",Target="GardenSlot",Slot=1},
 {Id="FirstBeeRoll",Event="TutorialBeeRoll",Text="Roll for your first Bee.",Helper="This tutorial Roll contains only Bees.",Target="Roll"},
 {Id="BeeWork",Event="Work",Text="Your Bee automatically pollinates Flowers.",Helper="Watch the highlighted Bee reach your Flower.",Target="Bee"},
 {Id="PollenSpark",Event="PollenSpark",Text="Reach the glowing Pollen Spark checkpoint.",Helper="Step onto the highlighted checkpoint. No key press is needed.",Target="TutorialToken"},
 {Id="Inventory",Event="SatchelOpen",Text="Open your Inventory.",Helper="Open the highlighted Inventory button.",Target="SeedSatchel"},
 {Id="InventoryExplain",Event="InventoryReviewed",Text="Learn what your Inventory shows.",Helper="1/N is base rarity. Duplicate Flowers increase Level and duplicate Bees increase Mastery.",Target="InventoryStats"},
 {Id="Delivery",Event="Delivery",Text="Deliver Honey to grow your Hive.",Helper="Your Bee works automatically. Watch it return to the Hive.",Target="Hive"},
 {Id="HiveUpgrade",Event="HiveUpgrade",Text="Upgrade your Hive.",Helper="Hive upgrades require Honey and the current Hive Quest.",Target="Hive"},
 {Id="WorkshopVisit",Event="WorkshopVisit",Text="Spend upgrade points in the Workshop.",Helper="Follow the beam to the Workshop in the center.",Target="Workshop"},
 {Id="WorkshopPurchase",Event="WorkshopPurchase",Text="Buy your first Workshop node.",Helper="Select the highlighted affordable node. Click it again to buy.",Target="WorkshopNode",NodeId="ROLL_1"},
 {Id="Synergy",Event="Synergy",Text="Certain Flower combinations create a Synergy.",Helper="Plant the guaranteed Tulip beside your Daisy.",Target="SynergySlot",Slot=2,PartnerSlot=1},
 {Id="SunnyVisit",Event="SunnyVisit",Text="Your Hive unlocks new locations.",Helper="Unlock the highlighted gate if needed, then enter Sunny Orchard.",Target="SunnyOrchard"},
}
local IndexById={}
for i,step in ipairs(Steps) do IndexById[step.Id]=i end
return {Version=5,Steps=Steps,IndexById=IndexById}
