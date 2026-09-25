local Steps={
 {Id="HiveIntro",Event="HiveApproach",Text="Welcome to Bloom RNG. This is your Hive.",Helper="Walk to the highlighted Hive.",Target="Hive"},
 {Id="StarterBee",Event="StarterBee",Text="Claim your first Bee.",Helper="Use the Hive interaction to claim your Worker Bee.",Target="Hive"},
 {Id="BeeWork",Event="Work",Text="Your Bee automatically pollinates flowers.",Helper="Watch the highlighted Bee reach a flower.",Target="Bee"},
 {Id="PollenSpark",Event="PollenSpark",Text="Touch the glowing Pollen Spark.",Helper="Walk into the highlighted sphere. No key press is needed.",Target="Token"},
 {Id="FirstSeed",Event="SeedReward",Text="Roll for your first Flower Seed.",Helper="Click the highlighted Roll button.",Target="Roll"},
 {Id="Plant",Event="Plant",Text="Plant your Flower.",Helper="Go to the highlighted empty bed and plant the seed.",Target="GardenSlot"},
 {Id="Inventory",Event="SatchelOpen",Text="Open your Inventory.",Helper="See owned items, free copies and mastery.",Target="SeedSatchel"},
 {Id="Delivery",Event="Delivery",Text="Make one Honey delivery.",Helper="Your Bee works automatically. Watch it return to the Hive.",Target="Hive"},
 {Id="HiveUpgrade",Event="HiveUpgrade",Text="Upgrade your Hive.",Helper="Use the Hive interaction. The tutorial delivery covers this upgrade.",Target="Hive"},
 {Id="WorkshopVisit",Event="WorkshopVisit",Text="Visit the Workshop.",Helper="Follow the beam to the Workshop in the center.",Target="Workshop"},
 {Id="WorkshopPurchase",Event="WorkshopPurchase",Text="Buy your first Workshop node.",Helper="Select the highlighted affordable node.",Target="WorkshopNode"},
 {Id="Synergy",Event="Synergy",Text="Create a Garden synergy.",Helper="Plant the tutorial partner seed in the highlighted adjacent bed.",Target="SynergySlot"},
 {Id="SunnyVisit",Event="SunnyVisit",Text="Enter Sunny Orchard.",Helper="Follow the beam through the highlighted gate.",Target="SunnyOrchard"},
}
local IndexById={}
for i,step in ipairs(Steps) do IndexById[step.Id]=i end
return {Version=3,Steps=Steps,IndexById=IndexById}
