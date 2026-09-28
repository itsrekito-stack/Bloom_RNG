local Steps={
 {Id="GardenSlot",Event="FirstGardenSlot",Text="Unlock your first Garden slot.",Helper="Start at your Hive. Unlock Garden Slot 1 to begin building your Garden.",Target="Hive"},
 {Id="FirstFlowerRoll",Event="TutorialFlowerRoll",Text="Roll your first Flower.",Helper="This tutorial Roll contains only Flowers. Your first Flower is guaranteed.",Target="Roll"},
 {Id="Plant",Event="Plant",Text="Plant your first Flower.",Helper="Open Garden, select Daisy, then place it in Garden Slot 1.",Target="GardenEditorSlot",Slot=1,FlowerId="Daisy"},
 {Id="FirstBeeRoll",Event="TutorialBeeRoll",Text="Roll your first Bee.",Helper="This tutorial Roll contains only Bees. Your first Bee is guaranteed.",Target="Roll"},
 {Id="EquipBee",Event="EquipBee",Text="Equip your first Bee.",Helper="Open Inventory, choose Worker Bee, then press EQUIP. Equipped Bees automatically work in your Garden.",Target="InventoryBeeEquip",BeeId="WorkerBee"},
 {Id="FillBloom",Event="BloomReady",Text="Fill the Bloom Meter.",Helper="Your equipped Bee charges Bloom while working. Watch the Bloom meter — the next delivery will finish it.",Target="BloomMeter"},
 {Id="BloomRoll",Event="BloomRoll",Text="Use your Bloom Roll.",Helper="Bloom is full. Click Roll to spend it on a boosted Bloom Roll.",Target="Roll"},
 {Id="InventoryExplain",Event="InventoryReviewed",Text="Learn Bees and Traits.",Helper="Open Inventory. Bee duplicates raise Mastery. Traits combine equipped Bees; hover a Trait to see its members. Flowers and planting live in Garden. Review this, then close Inventory.",Target="InventoryStats"},
 {Id="PollenSpark",Event="PollenSpark",Text="Collect a Pollen Spark.",Helper="Step onto the highlighted Pollen Spark. It gives +4 Bloom Charge, counts as an Activity for progression and Hive Quests, and contributes to the Server Bloom.",Target="TutorialToken"},
 {Id="HiveUpgrade",Event="HiveUpgrade",Text="Upgrade your Hive.",Helper="Hive upgrades need Honey plus the current Hive Quest. Hive levels unlock more Garden and Bee slots.",Target="Hive"},
 {Id="WorkshopPurchase",Event="WorkshopPurchase",Text="Buy your first Workshop node.",Helper="Open Workshop from the bottom menu, then buy ROLL_1. Workshop upgrades are permanent.",Target="WorkshopNode",NodeId="ROLL_1"},
 {Id="Synergy",Event="Synergy",Text="Build your first Garden Synergy.",Helper="Open Garden, select the guaranteed Tulip and place it in Slot 2 beside Daisy. Only your strongest valid Synergy is active.",Target="GardenEditorSlot",Slot=2,PartnerSlot=1,FlowerId="Tulip"},
 {Id="Quests",Event="QuestsOpen",Text="Open Quests.",Helper="Hive Quests test discoveries, Synergies, Bee Mastery, Activities and Trials. Open Quests to see the goals that drive progression.",Target="QuestsButton"},
}
local IndexById={}
for i,step in ipairs(Steps) do IndexById[step.Id]=i end
return {Version=10,Steps=Steps,IndexById=IndexById}
