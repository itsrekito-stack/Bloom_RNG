local Steps={
 {Id="GardenSlot",Event="FirstGardenSlot",Text="Unlock your first Garden slot.",Helper="Start at your Hive. Unlock Garden Slot 1 to begin building your Garden.",Target="Hive"},
 {Id="FirstFlowerRoll",Event="TutorialFlowerRoll",Text="Roll your first Flower.",Helper="This tutorial Roll contains only Flowers. Your first Flower is guaranteed.",Target="Roll"},
 {Id="Plant",Event="Plant",Text="Plant your first Flower.",Helper="Open Garden, select Daisy, then place it in Garden Slot 1.",Target="GardenEditorSlot",Slot=1,FlowerId="Daisy"},
 {Id="FirstBeeRoll",Event="TutorialBeeRoll",Text="Roll your first Bee.",Helper="This tutorial Roll contains only Bees. Your first Bee is guaranteed.",Target="Roll"},
 {Id="EquipBee",Event="EquipBee",Text="Equip your first Bee.",Helper="Open Inventory, choose Worker Bee, then press EQUIP. Equipped Bees automatically work in your Garden.",Target="InventoryBeeEquip",BeeId="WorkerBee"},
 {Id="BeeWork",Event="Work",Text="Bees work automatically.",Helper="Watch your equipped Bee fly to the planted Flower. Bee abilities activate automatically.",Target="Bee"},
 {Id="NormalRoll",Event="TutorialNormalRoll",Text="Now the real RNG begins.",Helper="Roll again. From now on, Flowers and Bees come from the normal reward pool.",Target="Roll"},
 {Id="Inventory",Event="SatchelOpen",Text="Open your Inventory.",Helper="Inventory stores Bees, resources and keepsakes. Flowers are managed only from Garden.",Target="SeedSatchel"},
 {Id="InventoryExplain",Event="InventoryReviewed",Text="Learn Bees and Traits.",Helper="Bee duplicates raise Mastery. Traits combine equipped Bees; hover a Trait to see its members. Flowers and planting live in Garden. Review this, then close Inventory.",Target="InventoryStats"},
 {Id="PollenSpark",Event="PollenSpark",Text="Take an active opportunity.",Helper="Step onto the highlighted Pollen Spark. Activities give you reasons to move instead of waiting at the HUD.",Target="TutorialToken"},
 {Id="HiveUpgrade",Event="HiveUpgrade",Text="Upgrade your Hive.",Helper="Hive upgrades need Honey plus the current Hive Quest. Hive levels unlock more Garden and Bee slots.",Target="Hive"},
 {Id="WorkshopVisit",Event="WorkshopVisit",Text="Open the Workshop.",Helper="Workshop is your permanent branching hex upgrade tree. Follow the beam to the Workshop.",Target="Workshop"},
 {Id="WorkshopPurchase",Event="WorkshopPurchase",Text="Buy your first Workshop node.",Helper="Buy the highlighted ROLL_1 node. Workshop choices shape your permanent progression.",Target="WorkshopNode",NodeId="ROLL_1"},
 {Id="Synergy",Event="Synergy",Text="Build your first Garden Synergy.",Helper="Open Garden, select the guaranteed Tulip and place it in Slot 2 beside Daisy. Only your strongest valid Synergy is active.",Target="GardenEditorSlot",Slot=2,PartnerSlot=1,FlowerId="Tulip"},
 {Id="SunnyVisit",Event="SunnyVisit",Text="Explore Sunny Orchard.",Helper="Hive progression opens new locations. Unlock the highlighted gate if needed, then enter Sunny Orchard.",Target="SunnyOrchard"},
 {Id="Quests",Event="QuestsOpen",Text="Open Quests.",Helper="Hive Quests test discoveries, Synergies, Bee Mastery, Activities and Trials. Open Quests to see the goals that drive progression.",Target="QuestsButton"},
}
local IndexById={}
for i,step in ipairs(Steps) do IndexById[step.Id]=i end
return {Version=8,Steps=Steps,IndexById=IndexById}
