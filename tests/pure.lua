test("default game vision profile",function()
 local p=Schema.CreateDefault()
 assert(Schema.Prepare(p))
 assert(p.SchemaVersion==6 and p.Inventory==nil and p.Currencies.Coins==0)
 assert(p.Tutorial.Version==10 and p.Tutorial.Step==1)
 assert(p.Garden.UnlockedSlots==0 and #p.Garden.Slots==7)
 assert(next(p.FlowerCollection.OwnedSeedCopies)==nil and next(p.Pollinators.BeeInventory)==nil)
end)

test("Trial-free Journey migration preserves SeasonReady progress",function()
 local p=Schema.CreateDefault()
 p.Migrations.JourneyNoTrialV1=nil
 p.Quests.JourneyStep=15
 p.Quests.Claimed.Journey_14=true
 assert(Schema.Prepare(p))
 assert(p.Migrations.JourneyNoTrialV1==true and p.Quests.JourneyStep==14 and not p.Quests.Claimed.Journey_14)

 local done=Schema.CreateDefault()
 done.Migrations.JourneyNoTrialV1=nil
 done.Quests.JourneyStep=16
 done.Quests.Claimed.Journey_14=true
 done.Quests.Claimed.Journey_15=true
 assert(Schema.Prepare(done))
 assert(done.Quests.JourneyStep==15 and done.Quests.Claimed.Journey_14==true and done.Quests.Claimed.Journey_15==nil)
end)

test("legacy mapping migrates copies into species progression",function()
 local p={Inventory={Apple=2,UnknownFruit=3},Currencies={FruitDust=12,Coins=9,AncientSeeds=77},DiscoveredFruits={Apple=true},Garden={UnlockedSlots=3,Slots={{SpeciesId="Tulip",Level=2,XP=4}}},FruitMastery={Apple={Level=999}}}
 assert(Schema.Prepare(p))
 assert(p.SchemaVersion==6)
 assert(p.FlowerCollection.OwnedSeedCopies.Daisy==1 and p.FlowerCollection.ObtainedFlowers.Daisy>=2)
 assert(p.FlowerCollection.OwnedSeedCopies.Tulip==1 and p.FlowerCollection.ObtainedFlowers.Tulip>=1)
 assert(p.Currencies.PetalDust==27 and p.Currencies.AncientNectar==0)
 assert(p.LegacyArchive.AncientSeeds==77)
 assert(p.FlowerCollection.FlowerMastery.Daisy.Level==100)
 assert(p.FlowerCollection.FlowerMastery.Tulip.Level>=2)
 assert(p.Migrations.GameVisionV1==true)
 local before=U.Copy(p)
 assert(Schema.Prepare(p))
 assert(equal(before,p),"migration not idempotent")
end)

test("empty garden stays empty",function()
 local p=Schema.CreateDefault()
 p.Garden.Slots={{},{},{},{},{},{},{}}
 p.FlowerCollection.OwnedSeedCopies={}
 assert(Schema.Prepare(p))
 assert(p.Garden.UnlockedSlots==0 and not p.Garden.Slots[1].SpeciesId)
 assert(next(p.FlowerCollection.OwnedSeedCopies)==nil)
end)

test("migration rejects NaN without mutation",function()
 local p={Currencies={Coins=0/0},Inventory={Apple=2}}
 assert(not Schema.Prepare(p))
 assert(p.Inventory.Apple==2 and p.Migrations==nil)
end)

test("malformed nested containers repaired",function()
 local p={Currencies="oops",Garden={Slots="oops"},FlowerCollection="oops"}
 assert(Schema.Prepare(p))
 assert(type(p.Garden.Slots)=="table")
end)

test("all registries valid, Workshop 43",function()
 assert(require(node("ServerScriptService/Tests/ConfigValidation")).Run())
end)

test("odds normalized, 10000 samples known",function()
 local p=Schema.CreateDefault()
 local Pool=require(rs.Config.RollPoolConfig)
 local F=require(rs.Config.FlowersConfig)
 local B=require(rs.Config.BeesConfig)
 local pool,total=Pool.Build(p,1,{})
 local sum=0
 for _,v in ipairs(pool) do sum=sum+v.Chance end
 assert(math.abs(sum-1)<1e-9)
 for i=1,10000 do
  local t=math.random()*total
  local selected=pool[#pool]
  for _,v in ipairs(pool) do t=t-v.Weight if t<=0 then selected=v break end end
  assert(selected.Kind=="FlowerSeed" and F.Exists(selected.Id) or selected.Kind=="Bee" and B.Exists(selected.Id))
 end
end)

test("player-facing odds are whole and coarsely rounded",function()
 local Pool=require(rs.Config.RollPoolConfig)
 assert(Pool.FormatOddsNumber(65.5)=="65")
 assert(Pool.FormatOddsNumber(1739000)=="1700000")
 assert(Pool.FormatOddsNumber(999)=="990")
end)

test("roll pool tolerates missing temporary runtime state",function()
 local p=Schema.CreateDefault()
 p.RollState.SpecialRollReady=true
 local pool,total=require(rs.Config.RollPoolConfig).Build(p,1,nil)
 assert(type(pool)=="table" and #pool>0 and total>0)
end)

test("discovery guarantee only undiscovered",function()
 local p=Schema.CreateDefault()
 p.RollState.DiscoveryPity=29
 local pool=require(rs.Config.RollPoolConfig).Build(p,1,{})
 for _,v in ipairs(pool) do assert(v.Undiscovered) end
end)

test("all-discovered guarantee safe fallback",function()
 local p=Schema.CreateDefault()
 for id in pairs(require(rs.Config.FlowersConfig).Species) do p.FlowerCollection.DiscoveredFlowers[id]=true end
 for id in pairs(require(rs.Config.BeesConfig).Bees) do p.Pollinators.DiscoveredBees[id]=true end
 p.RollState.DiscoveryPity=29
 local pool,total=require(rs.Config.RollPoolConfig).Build(p,1,{})
 assert(#pool>0 and total>0)
end)

test("flower duplicates raise species level without copy stock",function()
 local p=Schema.CreateDefault()
 local fp=require(node("ServerScriptService/Services/FlowerProgressionService"))
 local inv=require(node("ServerScriptService/Services/InventoryService"))
 local x={Profile=function() return p end,Emit=function() end,PollinatorService={AddMastery=function() end}}
 fp:Init(x) x.FlowerProgressionService=fp inv:Init(x)
 assert(inv:Grant({},"FlowerSeed","Daisy")==true)
 assert(p.FlowerCollection.OwnedSeedCopies.Daisy==1 and p.FlowerCollection.ObtainedFlowers.Daisy==1)
 assert(inv:Grant({},"FlowerSeed","Daisy")==false)
 assert(p.FlowerCollection.OwnedSeedCopies.Daisy==1 and p.FlowerCollection.ObtainedFlowers.Daisy==2)
 assert(p.FlowerCollection.FlowerMastery.Daisy.Level==2)
 assert(not inv:Dissolve({},"Daisy",1))
end)

test("bee duplicates raise species mastery and equip is species-unique",function()
 local player={} local p=Schema.CreateDefault()
 local gained=0
 local inv=require(node("ServerScriptService/Services/InventoryService"))
 local x={
  Profile=function() return p end,
  PollinatorService={AddMastery=function(_,pl,id,amount) gained=gained+amount return true end},
  StatsService={BeeCapacity=function() return 3 end},
  U=U,
  GardenSynergyService={Recalculate=function() end},
  Emit=function() end,
  Send=function() end,
  MarkStateDirty=function() end,
 }
 inv:Init(x)
 assert(inv:Grant(player,"Bee","WorkerBee")==true)
 assert(inv:Grant(player,"Bee","WorkerBee")==false)
 assert(p.Pollinators.BeeInventory.WorkerBee==1 and p.Pollinators.BeeObtained.WorkerBee==2)
 assert(gained==require(rs.Config.BloomConfig).BeeDuplicateXP)
 assert(inv:EquipBee(player,"WorkerBee",1))
 assert(not inv:EquipBee(player,"WorkerBee",2))
 assert(not inv:DissolveBee(player,"WorkerBee",1))
end)

test("full Bee slots auto-replace only a lower-rarity Bee",function()
 local player={} local p=Schema.CreateDefault()
 p.Pollinators.BeeInventory.WorkerBee=1
 p.Pollinators.BeeInventory.NectarBee=1
 p.Pollinators.BeeInventory.RoyalBee=1
 p.Pollinators.EquippedBeeSlots[1]="WorkerBee"
 p.Pollinators.EquippedBeeSlots[2]="RoyalBee"
 local inv=require(node("ServerScriptService/Services/InventoryService"))
 local x={
  Profile=function() return p end,
  PollinatorService={AddMastery=function() return true end},
  StatsService={BeeCapacity=function() return 2 end},
  U=U,
  GardenSynergyService={Recalculate=function() end},
  Emit=function() end,
  Send=function() end,
 }
 inv:Init(x)
 assert(inv:EquipBee(player,"NectarBee",nil))
 assert(p.Pollinators.EquippedBeeSlots[1]=="NectarBee" and p.Pollinators.EquippedBeeSlots[2]=="RoyalBee")
 local ok,reason=inv:EquipBee(player,"WorkerBee",nil)
 assert(not ok and reason=="NO_LOWER_RARITY_BEE")
end)

test("season dry run deterministic and preserves species mastery",function()
 local p=Schema.CreateDefault()
 p.Tutorial.Skipped=true
 p.FlowerCollection.DiscoveredFlowers.Daisy=true
 p.FlowerCollection.OwnedSeedCopies.Daisy=1
 p.FlowerCollection.ObtainedFlowers.Daisy=4
 p.FlowerCollection.FlowerMastery.Daisy={Level=15,XP=8}
 p.Season.Keepsakes.Flower="Daisy"
 p.WorkshopV5.Nodes.ROLL_1=true
 p.WorkshopV5.Nodes.LEGACY_1=true
 p.WorkshopV5.LegacyNodes.LEGACY_1=true
 local before=U.Copy(p)
 local fn=require(rs.Shared.SeasonPlan).BuildSeasonTurnPlan
 local a=fn(p) local b=fn(p)
 assert(equal(a,b) and equal(p,before))
 assert(a.After.Season.Count==1 and a.After.Currencies.AncientNectar==5)
 assert(a.After.FlowerCollection.FlowerMastery.Daisy.Level==15 and a.After.WorkshopV5.Nodes.LEGACY_1)
 assert(not a.After.WorkshopV5.Nodes.ROLL_1 and a.After.Garden.Slots[1].SpeciesId=="Daisy" and a.After.Garden.UnlockedSlots>=1)
end)

test("strongest valid synergy replaces nested weaker synergy",function()
 local p=Schema.CreateDefault()
 p.FlowerCollection.FlowerMastery.Daisy={Level=3,XP=0}
 p.FlowerCollection.FlowerMastery.Tulip={Level=3,XP=0}
 p.FlowerCollection.FlowerMastery.Sunflower={Level=3,XP=0}
 p.FlowerCollection.FlowerMastery.Clover={Level=3,XP=0}
 p.Garden.Slots[1]={SpeciesId="Daisy"}
 p.Garden.Slots[2]={SpeciesId="Tulip"}
 p.Garden.Slots[3]={SpeciesId="Sunflower"}
 p.Garden.Slots[4]={SpeciesId="Clover"}
 local player={}
 local service=require(node("ServerScriptService/Services/GardenSynergyService"))
 service:Init({Profile=function() return p end,Temp={[player]={}},Emit=function() end})
 local active=service:Recalculate(player)
 assert(active.MeadowLine and not active.MeadowPair and p.Garden.ActiveSynergy=="MeadowLine")
 p.Garden.Slots[4]={}
 active=service:Recalculate(player)
 assert(active.MeadowFamily and p.Garden.ActiveSynergy=="MeadowFamily")
end)

test("roll independent players, cooldown and one-time Bloom",function()
 local a,b={},{}
 local profiles={[a]=Schema.CreateDefault(),[b]=Schema.CreateDefault()}
 local temp={[a]={},[b]={}}
 local rewards=0
 local inv=require(node("ServerScriptService/Services/InventoryService"))
 local roll=require(node("ServerScriptService/Services/RollService"))
 local x={
  Temp=temp,
  Profile=function(_,pl) return profiles[pl] end,
  StatsService={Get=function() return {Luck=1} end},
  BoostService={RollLuck=function() return 1 end},
  Send=function(_,pl,kind) if kind=="Reward" then rewards=rewards+1 end end,
  Broadcast=function() end,
  Emit=function() end,
  FlowerProgressionService={AddDuplicate=function() return true end},
  PollinatorService={AddMastery=function() return true end},
  GardenSynergyService={Recalculate=function() end},
  MarkStateDirty=function() end,
  U=U,
 }
 x.InventoryService=inv inv:Init(x) roll:Init(x)
 for _,p in pairs(profiles) do p.Tutorial.FeatureUnlocks.Roll=true p.Tutorial.Step=99 end
 profiles[a].RollState.SpecialRollReady=true profiles[a].RollState.BloomCharge=100
 assert(roll:Roll(a,false)) assert(profiles[a].RollState.BloomCharge==0)
 assert(roll:Roll(b,false)) assert(not roll:Roll(a,false))
 for i=1,30 do roll.Last[a]=-100 assert(roll:Roll(a,true)) end
 assert(profiles[a].RollState.TotalRolls==31 and profiles[b].RollState.TotalRolls==1 and rewards==32)
end)

test("effective luck can only reduce earned roll luck",function()
 local player={} local p=Schema.CreateDefault()
 p.Pollinators.DiscoveredBees.ScholarBee=true
 p.Pollinators.BeeInventory.ScholarBee=1
 p.Pollinators.EquippedBeeSlots[1]="ScholarBee"
 local stats=require(node("ServerScriptService/Services/StatsService")) stats:Init({})
 local service=require(node("ServerScriptService/Services/BoostService"))
 service:Init({Temp={[player]={}},Profile=function() return p end,StatsService=stats,PollinatorService={States={[player]={}}},MarkStateDirty=function() end,Send=function() end})
 local earned=service:RollLuck(player,p)
 assert(earned>=1)
 p.Settings.EffectiveLuck=1
 assert(service:RollLuck(player,p)==1)
 p.Settings.EffectiveLuck=999999
 assert(math.abs(service:RollLuck(player,p)-earned)<1e-6)
 p.Settings.EffectiveLuck=0
 assert(math.abs(service:RollLuck(player,p)-earned)<1e-6)
 local temp=service.X.Temp[player]
 temp.ServerBloomLuckRolls=1
 p.Settings.EffectiveLuck=1
 assert(service:RollLuck(player,p)==100)
 assert(service:ConsumeServerBloomRoll(player))
 assert(temp.ServerBloomLuckRolls==0 and service:RollLuck(player,p)==1)
 assert(not service:ConsumeServerBloomRoll(player))
end)

test("activity owner checkpoint order and expiry",function()
 local player,other={},{} local p=Schema.CreateDefault() local within=true local events={}
 local service=require(node("ServerScriptService/Services/GardenActivityService"))
 local x={Profile=function(_,who) if who==player then return p end end,Temp={[player]={}},U={WithinCheckpoint=function() return within end},Emit=function(_,pl,event) events[event]=(events[event] or 0)+1 end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},MapService={Sector=function() return "SunnyOrchard" end},GardenPlotService={HivePosition=function() return Vector3.zero end,Position=function(_,pl,i) return Vector3.new(i*7,0,0) end}}
 service:Init(x)
 service.Offers[player]={token={Id="token",Kind="PollenTrail",Index=1,Nodes={Vector3.zero,Vector3.new(3,0,0)},Expires=os.clock()+5,Revision=0}}
 assert(not service:Collect(other,"token",1,"Reach"))
 within=false assert(not service:Collect(player,"token",1,"Reach"))
 within=true assert(not service:Collect(player,"token",2,"Reach"))
 assert(service:Collect(player,"token",1,"Reach")) assert(service:Collect(player,"token",2,"Reach"))
 assert(events.PollenTrail==1 and events.ActivityCompleted==1 and events.WorldActivity==1)
 service.Offers[player].expired={Id="expired",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=-1}
 assert(not service:Collect(player,"expired",1,"Reach"))
end)

test("Workshop purchase prerequisites balance and idempotence",function()
 local p=Schema.CreateDefault() p.Hive.Level=8 p.Tutorial.FeatureUnlocks.Workshop=true p.WorkshopV5.Points=5 p.Currencies.Coins=1000
 local s=require(node("ServerScriptService/Services/WorkshopService"))
 s:Init({Profile=function() return p end,GardenPlotService={RefreshCapacity=function() end},TutorialService={Refresh=function() end},Emit=function() end})
 assert(not s:Buy({},"ROLL_2"))
 assert(s:Buy({},"ROLL_1"))
 assert(not s:Buy({},"ROLL_1"))
 assert(p.WorkshopV5.Points==4 and p.Currencies.Coins==900)
 assert(not s:Buy({},"LEGACY_1"))
end)

test("tutorial v10 gates future events and completes ordered flow",function()
 local player={} local p=Schema.CreateDefault() local completed=0 local sparks=0
 local service=require(node("ServerScriptService/Services/TutorialService"))
 local x={
  Profile=function() return p end,
  MarkStateDirty=function() end,
  EmitOnce=function(_,pl,event) if not p.Tutorial.Events[event] then p.Tutorial.Events[event]=1 if event=="TutorialComplete" then completed=completed+1 end end end,
  U={Near=function() return false end},
  GardenActivityService={EnsureTutorialSpark=function() sparks=sparks+1 end},
  GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end,RefreshCapacity=function() end},
  InventoryService={Grant=function(_,pl,kind,id) p.FlowerCollection.DiscoveredFlowers[id]=true p.FlowerCollection.OwnedSeedCopies[id]=1 return true end},
  WorkshopService={},
  GardenSynergyService={Recalculate=function() end},
 }
 service:Init(x)
 local T=require(rs.Config.TutorialConfig)
 assert(#T.Steps==13 and T.Version==10)
 p.Tutorial.Events.Delivery=99
 assert(not service:RecordEvent(player,"Delivery"))
 service:Refresh(player) assert(p.Tutorial.Step==1)
 for i,step in ipairs(T.Steps) do
  assert(p.Tutorial.Step==i)
  p.Tutorial.Events[step.Event]=(p.Tutorial.Events[step.Event] or 0)+1
  assert(service:RecordEvent(player,step.Event))
  service:Refresh(player)
  assert(p.Tutorial.Step==i+1)
 end
 assert(p.Tutorial.Step==#T.Steps+1 and completed==1 and sparks>0)
 assert(p.Hive.Honey>=40 and p.WorkshopV5.Points>=1 and p.Currencies.Coins>=30)
 assert((p.FlowerCollection.OwnedSeedCopies.Tulip or 0)>=1)
end)

test("tutorial rolls are flower-only then bee-only",function()
 local player={} local p=Schema.CreateDefault() local temp={[player]={}} local rewards={}
 local inv=require(node("ServerScriptService/Services/InventoryService"))
 local roll=require(node("ServerScriptService/Services/RollService"))
 local x={
  Temp=temp,Profile=function() return p end,
  StatsService={Get=function() return {Luck=1} end},
  BoostService={RollLuck=function() return 1 end},
  Send=function(_,pl,kind,r) if kind=="Reward" then rewards[#rewards+1]=r end end,
  Broadcast=function() end,
  Emit=function(_,pl,event) p.Tutorial.Events[event]=(p.Tutorial.Events[event] or 0)+1 end,
  FlowerProgressionService={AddDuplicate=function() end},
  PollinatorService={AddMastery=function() end},
  StatsService={Get=function() return {Luck=1} end,BeeCapacity=function() return 1 end},
  GardenSynergyService={Recalculate=function() end},
  U=U,
 }
 x.MarkStateDirty=function() end
 x.InventoryService=inv inv:Init(x) roll:Init(x)
 local T=require(rs.Config.TutorialConfig)
 p.Tutorial.FeatureUnlocks.Roll=true
 p.Tutorial.Step=T.IndexById.FirstFlowerRoll
 assert(roll:Roll(player,false))
 assert(rewards[1] and rewards[1].Kind=="FlowerSeed")
 roll.Last[player]=-100
 p.Tutorial.Step=T.IndexById.FirstBeeRoll
 assert(roll:Roll(player,false))
 assert(rewards[2] and rewards[2].Kind=="Bee")
 assert(p.Pollinators.BeeInventory[rewards[2].Id]==1 and p.Pollinators.EquippedBeeSlots[1]==nil)
end)

test("one-time point source and preservation of Nectar",function()
 local p=Schema.CreateDefault()
 local s=require(node("ServerScriptService/Services/WorkshopService"))
 s:Init({Profile=function() return p end})
 s:Point({},"same",2) s:Point({},"same",2)
 assert(p.WorkshopV5.Points==2 and p.Currencies.AncientNectar==0)
end)
