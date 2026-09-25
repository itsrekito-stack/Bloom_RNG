test("default profile",function() local p=Schema.CreateDefault() assert(Schema.Prepare(p)) assert(p.SchemaVersion==5 and p.Inventory==nil and p.Currencies.Coins==0 and p.Tutorial.Version==4 and p.Tutorial.Step==1) end)
test("legacy mapping, dust, planted ownership",function()
 local p={Inventory={Apple=2,UnknownFruit=3},Currencies={FruitDust=12,Coins=9,AncientSeeds=77},DiscoveredFruits={Apple=true},Garden={UnlockedSlots=3,Slots={{SpeciesId="Tulip",Level=2}}},FruitMastery={Apple={Level=999}}}
 assert(Schema.Prepare(p)) assert(p.FlowerCollection.OwnedSeedCopies.Daisy==3) assert(p.FlowerCollection.OwnedSeedCopies.Tulip==1) assert(p.Currencies.PetalDust==27) assert(p.Currencies.AncientNectar==0) assert(p.LegacyArchive.AncientSeeds==77) assert(p.FlowerCollection.FlowerMastery.Daisy.Level==100)
 local before=U.Copy(p) assert(Schema.Prepare(p)) assert(equal(before,p),"migration not idempotent")
end)
test("empty garden stays empty",function() local p=Schema.CreateDefault() p.Garden.Slots={{},{},{}} p.FlowerCollection.OwnedSeedCopies={} assert(Schema.Prepare(p)) assert(not p.Garden.Slots[1].SpeciesId) assert(not p.FlowerCollection.OwnedSeedCopies.Daisy) end)
test("migration rejects NaN without mutation",function() local p={Currencies={Coins=0/0},Inventory={Apple=2}} assert(not Schema.Prepare(p)) assert(p.Inventory.Apple==2 and p.Migrations==nil) end)
test("malformed nested containers repaired",function() local p={Currencies="oops",Garden={Slots="oops"},FlowerCollection="oops"} assert(Schema.Prepare(p)) assert(type(p.Garden.Slots)=="table") end)
test("all registries valid, Workshop 43",function() assert(require(node("ServerScriptService/Tests/ConfigValidation")).Run()) end)
test("odds normalized, 10000 samples known",function()
 local p=Schema.CreateDefault() local Pool=require(rs.Config.RollPoolConfig) local F=require(rs.Config.FlowersConfig) local B=require(rs.Config.BeesConfig)
 local pool,total=Pool.Build(p,1,{}) local sum=0 for _,v in ipairs(pool) do sum=sum+v.Chance end assert(math.abs(sum-1)<1e-9)
 for i=1,10000 do local t=math.random()*total local selected=pool[#pool] for _,v in ipairs(pool) do t=t-v.Weight if t<=0 then selected=v break end end assert(selected.Kind=="FlowerSeed" and F.Exists(selected.Id) or selected.Kind=="Bee" and B.Exists(selected.Id)) end
end)
test("discovery guarantee only undiscovered",function() local p=Schema.CreateDefault() p.RollState.DiscoveryPity=29 local pool=require(rs.Config.RollPoolConfig).Build(p,1,{}) for _,v in ipairs(pool) do assert(v.Undiscovered) end end)
test("all-discovered guarantee safe fallback",function() local p=Schema.CreateDefault() for id in pairs(require(rs.Config.FlowersConfig).Species) do p.FlowerCollection.DiscoveredFlowers[id]=true end for id in pairs(require(rs.Config.BeesConfig).Bees) do p.Pollinators.DiscoveredBees[id]=true end p.RollState.DiscoveryPity=29 local pool,total=require(rs.Config.RollPoolConfig).Build(p,1,{}) assert(#pool>0 and total>0) end)
test("ownership, dissolve protection, remaining copy",function()
 local p=Schema.CreateDefault() p.FlowerCollection.OwnedSeedCopies.Daisy=3 local inv=require(node("ServerScriptService/Services/InventoryService"))
 inv:Init({Profile=function() return p end,FlowerProgressionService={Add=function() end},Emit=function() end}) assert(inv:Available(p,"Daisy")==2)
 p.FlowerCollection.LockedFlowers.Daisy=true assert(not inv:Dissolve({},"Daisy",1)) p.FlowerCollection.LockedFlowers.Daisy=nil
 assert(inv:Dissolve({},"Daisy",2)) assert(p.Currencies.PetalDust==6) assert(not inv:Dissolve({},"Daisy",1)) assert(not inv:Dissolve({},"Daisy",0/0))
end)
test("season dry run deterministic and preserves mastery",function()
 local p=Schema.CreateDefault() p.FlowerCollection.FlowerMastery.Daisy={Level=15,XP=8} p.Season.Keepsakes.Flower="Tulip" p.FlowerCollection.OwnedSeedCopies.Tulip=2 p.WorkshopV5.Nodes.ROLL_1=true p.WorkshopV5.Nodes.LEGACY_1=true p.WorkshopV5.LegacyNodes.LEGACY_1=true
 local before=U.Copy(p) local fn=require(rs.Shared.SeasonPlan).BuildSeasonTurnPlan local a=fn(p) local b=fn(p) assert(equal(a,b) and equal(p,before)) assert(a.After.Season.Count==1 and a.After.Currencies.AncientNectar==5) assert(a.After.FlowerCollection.FlowerMastery.Daisy.Level==15 and a.After.WorkshopV5.Nodes.LEGACY_1) assert(not a.After.WorkshopV5.Nodes.ROLL_1 and a.After.Garden.Slots[1].SpeciesId=="Tulip")
end)
test("trait copies cannot be equipped beyond ownership",function()
 local p=Schema.CreateDefault() p.Pollinators.BeeInventory.WorkerBee=1 local inv=require(node("ServerScriptService/Services/InventoryService"))
 inv:Init({Profile=function() return p end,U=U,StatsService={BeeCapacity=function() return 3 end},GardenSynergyService={Recalculate=function() end},Emit=function() end})
 assert(inv:EquipBee({},"WorkerBee",1)) assert(not inv:EquipBee({},"WorkerBee",2)) assert(not inv:EquipBee({},"WorkerBee",0/0))
end)
test("synergies use physical adjacency, not equipped legacy",function()
 local p=Schema.CreateDefault() p.Garden.Slots[1]={SpeciesId="Daisy"} p.Garden.Slots[2]={SpeciesId="Tulip"} p.EquippedFruitIds={"Starfruit"}
 local service=require(node("ServerScriptService/Services/GardenSynergyService")) local player={}
 local x={Profile=function() return p end,Temp={[player]={}},Emit=function() end,MapService={Sector=function() return "Center" end}}
 service:Init(x) assert(service:Recalculate(player).MeadowPair) p.Garden.Slots[2]={} p.Garden.Slots[15]={SpeciesId="Tulip"} assert(not service:Recalculate(player).MeadowPair)
end)
test("roll independent players, 100 cycles, cooldown and one-time Bloom",function()
 local a,b={},{} local profiles={[a]=Schema.CreateDefault(),[b]=Schema.CreateDefault()} local temp={[a]={},[b]={}} local rewards=0 local inv=require(node("ServerScriptService/Services/InventoryService")) local roll=require(node("ServerScriptService/Services/RollService"))
 local x={Temp=temp,Profile=function(_,pl) return profiles[pl] end,StatsService={Get=function() return {Luck=1} end},Send=function(_,pl,kind,r) if kind=="Reward" then rewards=rewards+1 end end,Broadcast=function() end,Emit=function() end,FlowerProgressionService={Add=function() end}}
 x.InventoryService=inv inv:Init(x) roll:Init(x) for _,p in pairs(profiles) do p.Tutorial.FeatureUnlocks.Roll=true p.Tutorial.FeatureUnlocks.AutoRoll=false end
 profiles[a].RollState.SpecialRollReady=true profiles[a].RollState.BloomCharge=100
 assert(roll:Roll(a,false)) assert(profiles[a].RollState.BloomCharge==0) assert(roll:Roll(b,false)) assert(not roll:Roll(a,false))
 for i=1,100 do roll.Last[a]=-100 assert(roll:Roll(a,true)) end assert(profiles[a].RollState.TotalRolls==101 and profiles[b].RollState.TotalRolls==1 and rewards==102)
end)
test("activity owner, checkpoint reach, order, expiry, duplicate rejection",function()
 local player,other={},{} local p=Schema.CreateDefault() local within=true local events={}
 local service=require(node("ServerScriptService/Services/GardenActivityService")) local x={Profile=function(_,who) if who==player then return p end end,Temp={[player]={}},U={WithinCheckpoint=function() return within end},Emit=function(_,pl,event) events[event]=(events[event] or 0)+1 end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},PollinatorService={AddMastery=function() end},MapService={Sector=function() return "SunnyOrchard" end},GardenPlotService={HivePosition=function() return Vector3.zero end,Position=function(_,pl,i) return Vector3.new(i*7,0,0) end}}
 service:Init(x) service.Offers[player]={token={Id="token",Kind="PollenTrail",Index=1,Nodes={Vector3.zero,Vector3.new(3,0,0)},Expires=os.clock()+5,Revision=0}}
 assert(not service:Collect(other,"token",1,"Reach")) within=false assert(not service:Collect(player,"token",1,"Reach")) within=true assert(not service:Collect(player,"token",2,"Reach")) assert(service:Collect(player,"token",1,"Reach")) assert(service:Collect(player,"token",2,"Reach")) assert(not service:Collect(player,"token",2,"Reach")) assert(events.PollenTrail==1 and events.ActivityCompleted==1 and events.WorldActivity==1)
 service.Offers[player].expired={Id="expired",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=-1} assert(not service:Collect(player,"expired",1,"Reach"))
end)
test("activity collection accepts checkpoint Reach only",function()
 local player={} local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/GardenActivityService"))
 local x={Profile=function() return p end,Temp={[player]={}},U={WithinCheckpoint=function() return true end},Emit=function() end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},PollinatorService={AddMastery=function() end},MapService={Sector=function() return "Center" end}}
 s:Init(x) s.Offers[player]={touch={Id="touch",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=os.clock()+10}}
 assert(not s:Collect(player,"touch",1,"Begin")) assert(not s:Collect(player,"touch",1,"Collect")) assert(s:Collect(player,"touch",1,"Reach"))
end)
test("Workshop purchase prerequisites, balance, idempotence",function()
 local p=Schema.CreateDefault() p.Hive.Level=8 p.Tutorial.FeatureUnlocks.Workshop=true p.WorkshopV5.Points=5 p.Currencies.Coins=1000
 local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end,GardenPlotService={RefreshCapacity=function() end},TutorialService={Refresh=function() end},Emit=function() end})
 assert(not s:Buy({},"ROLL_2")) assert(s:Buy({},"ROLL_1")) assert(not s:Buy({},"ROLL_1")) assert(p.WorkshopV5.Points==4 and p.Currencies.Coins==970) assert(not s:Buy({},"LEGACY_1"))
end)
test("tutorial v4 gates future events and completes ordered flow",function()
 local player={} local p=Schema.CreateDefault() local completed=0 local sparks=0
 local service=require(node("ServerScriptService/Services/TutorialService"))
 local x={
  Profile=function() return p end,
  MarkStateDirty=function() end,
  EmitOnce=function(_,pl,event) if not p.Tutorial.Events[event] then p.Tutorial.Events[event]=1 if event=="TutorialComplete" then completed=completed+1 end end end,
  U={Near=function() return false end},
  GardenActivityService={EnsureTutorialSpark=function() sparks=sparks+1 end},
  GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end},
  InventoryService={Available=function() return 0 end},
  HiveService={Interact=function() end},
 }
 service:Init(x)
 local T=require(rs.Config.TutorialConfig) assert(#T.Steps==15 and T.Version==4)
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
 assert(p.Tutorial.Step==16 and completed==1 and sparks>0)
 assert(p.Hive.Honey>=40)
 assert(p.WorkshopV5.Points>=1 and p.Currencies.Coins>=30)
 assert((p.FlowerCollection.OwnedSeedCopies.Tulip or 0)>=1)
end)
test("tutorial reconnect preserves current-step completion",function()
 local player={} local p=Schema.CreateDefault()
 local function make()
  local s=require(node("ServerScriptService/Services/TutorialService"))
  s:Init({Profile=function() return p end,MarkStateDirty=function() end,EmitOnce=function(_,pl,event) p.Tutorial.Events[event]=1 end,U={Near=function() return false end},GardenActivityService={EnsureTutorialSpark=function() end},GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end},InventoryService={Available=function() return 1 end},HiveService={Interact=function() end}})
  return s
 end
 local s=make()
 for i=1,5 do local step=require(rs.Config.TutorialConfig).Steps[p.Tutorial.Step] p.Tutorial.Events[step.Event]=(p.Tutorial.Events[step.Event] or 0)+1 assert(s:RecordEvent(player,step.Event)) s:Refresh(player) end
 assert(p.Tutorial.Step==6)
 local copy=U.Copy(p) p=copy
 local resumed=make() resumed:Refresh(player) assert(p.Tutorial.Step==6)
end)
test("tutorial v2 profile beyond shortened flow migrates complete",function()
 local player={} local p=Schema.CreateDefault() p.Tutorial.Version=2 p.Tutorial.Step=16 p.Tutorial.Events={}
 local s=require(node("ServerScriptService/Services/TutorialService"))
 s:Init({Profile=function() return p end,MarkStateDirty=function() end,EmitOnce=function(_,pl,event) p.Tutorial.Events[event]=1 end,U={Near=function() return false end},GardenActivityService={EnsureTutorialSpark=function() end},GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end},InventoryService={Available=function() return 1 end},HiveService={Interact=function() end}})
 s:Refresh(player)
 assert(p.Tutorial.Version==4 and p.Tutorial.Step==16 and p.Tutorial.Events.TutorialComplete==1)
end)
test("tutorial SunnyVisit recovers if EmitOnce was consumed early",function()
 local player={} local p=Schema.CreateDefault() p.Tutorial.Step=15 p.Tutorial.Events.SunnyVisit=1
 local service=require(node("ServerScriptService/Services/TutorialService"))
 local x={
  Profile=function() return p end,
  MarkStateDirty=function() end,
  EmitOnce=function() end,
  Emit=function(_,pl,event)
   p.Tutorial.Events[event]=(p.Tutorial.Events[event] or 0)+1
   service:RecordEvent(pl,event)
   service:Refresh(pl)
  end,
  U={Near=function() return false end},
  GardenActivityService={EnsureTutorialSpark=function() end},
  GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end},
  InventoryService={Available=function() return 1 end},
  HiveService={Interact=function() end},
  MapService={Sector=function() return "SunnyOrchard" end},
 }
 service:Init(x)
 assert(service:Tick(player))
 assert(p.Tutorial.Step==16 and p.Tutorial.Events.TutorialStep_SunnyVisit==1)
end)
test("tutorial v3 skipped profile stays complete after v4 migration",function()
 local player={} local p=Schema.CreateDefault() p.Tutorial.Version=3 p.Tutorial.Step=14 p.Tutorial.Skipped=true p.Tutorial.Events={}
 local s=require(node("ServerScriptService/Services/TutorialService"))
 s:Init({Profile=function() return p end,MarkStateDirty=function() end,EmitOnce=function() end})
 s:Refresh(player)
 assert(p.Tutorial.Version==4 and p.Tutorial.Step==16 and p.Tutorial.Skipped and p.Tutorial.Events.TutorialComplete==1)
end)
test("tutorial first seed presentation recovers from already confirmed reward",function()
 local player={} local p=Schema.CreateDefault() p.Tutorial.Step=6 p.Tutorial.Events.SeedReward=1
 local s=require(node("ServerScriptService/Services/TutorialService"))
 s:Init({
  Profile=function() return p end,
  MarkStateDirty=function() end,
  EmitOnce=function() end,
  U={Near=function() return false end},
  GardenActivityService={EnsureTutorialSpark=function() end},
  GardenPlotService={HivePosition=function() return Vector3.zero end,RefreshHivePrompt=function() end},
  InventoryService={Available=function() return 1 end},
  MapService={Sector=function() return "Center" end},
 })
 assert(s:Tick(player))
 assert(p.Tutorial.Step==7 and p.Tutorial.Events.TutorialStep_FirstSeed==1)
end)
test("tutorial skip does not grant economy assists",function()
 local player={} local p=Schema.CreateDefault() p.StarterBeeGranted=true
 local s=require(node("ServerScriptService/Services/TutorialService"))
 s:Init({Profile=function() return p end,HiveService={Interact=function() error("starter bee should already exist") end}})
 s:Skip(player)
 assert(p.Tutorial.Step==16 and p.Tutorial.Skipped and p.Hive.Honey==0 and p.Currencies.Coins==0 and p.WorkshopV5.Points==0)
end)
test("tutorial Pollen Spark offer is tagged, deduped and respawns after expiry",function()
 local player={Character={FindFirstChildOfClass=function() return {Health=100} end}} local p=Schema.CreateDefault()
 local service=require(node("ServerScriptService/Services/GardenActivityService"))
 local x={Profile=function() return p end,Temp={[player]={}},U={WithinCheckpoint=function() return false end},Emit=function() end,Send=function() end,GardenPlotService={HivePosition=function() return Vector3.zero end,Position=function(_,pl,i) return Vector3.new(i*7,0,0) end}}
 service:Init(x)
 assert(service:EnsureTutorialSpark(player))
 local count=0 local first
 for _,o in pairs(service.Offers[player]) do count=count+1 first=o end
 assert(count==1 and first.Tutorial and first.Kind=="PollenSpark")
 assert(not service:EnsureTutorialSpark(player))
 first.Expires=-1
 service:Tick(player)
 assert(service:EnsureTutorialSpark(player))
 count=0 for _,o in pairs(service.Offers[player]) do count=count+1 assert(o.Tutorial) end
 assert(count==1)
end)
test("first tutorial roll guarantees a Flower Seed",function()
 local player={} local p=Schema.CreateDefault() p.Tutorial.Step=5 p.Tutorial.FeatureUnlocks.Roll=true local temp={[player]={}} local reward
 local inv=require(node("ServerScriptService/Services/InventoryService")) local roll=require(node("ServerScriptService/Services/RollService"))
 local x={Temp=temp,Profile=function() return p end,StatsService={Get=function() return {Luck=1} end},Send=function(_,pl,kind,r) if kind=="Reward" then reward=r end end,Broadcast=function() end,Emit=function() end,FlowerProgressionService={Add=function() end}}
 x.InventoryService=inv inv:Init(x) roll:Init(x)
 assert(roll:Roll(player,false))
 assert(reward and reward.Kind=="FlowerSeed" and reward.Id=="Sunflower")
 assert((p.FlowerCollection.OwnedSeedCopies.Sunflower or 0)==1)
end)
test("one-time point source and preservation of Nectar",function()
 local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end}) s:Point({},"same",2) s:Point({},"same",2) assert(p.WorkshopV5.Points==2 and p.Currencies.AncientNectar==0)
end)
