test("default profile",function() local p=Schema.CreateDefault() assert(Schema.Prepare(p)) assert(p.SchemaVersion==5 and p.Inventory==nil and p.Currencies.Coins==0) end)
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
test("activity owner, body contact, order, expiry, duplicate rejection",function()
 local player,other={},{} local p=Schema.CreateDefault() p.Tutorial.Step=18 local touching=true local events={}
 local service=require(node("ServerScriptService/Services/GardenActivityService")) local x={Profile=function(_,who) if who==player then return p end end,Temp={[player]={}},U={CharacterTouchesSphere=function() return touching end},Emit=function(_,pl,event) events[event]=(events[event] or 0)+1 end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},PollinatorService={AddMastery=function() end},MapService={Sector=function() return "SunnyOrchard" end},GardenPlotService={HivePosition=function() return Vector3.zero end,Position=function(_,pl,i) return Vector3.new(i*7,0,0) end}}
 service:Init(x) service.Offers[player]={token={Id="token",Kind="PollenTrail",Index=1,Nodes={Vector3.zero,Vector3.new(3,0,0)},Expires=os.clock()+5,Revision=0}}
 assert(not service:Collect(other,"token",1,"Collect")) touching=false assert(not service:Collect(player,"token",1,"Collect")) touching=true assert(not service:Collect(player,"token",2,"Collect")) assert(service:Collect(player,"token",1,"Collect")) assert(service:Collect(player,"token",2,"Collect")) assert(not service:Collect(player,"token",2,"Collect")) assert(events.PollenTrail==1 and events.ActivityCompleted==1 and events.TutorialActivity==1 and events.WorldActivity==1)
 service.Offers[player].expired={Id="expired",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=-1} assert(not service:Collect(player,"expired",1,"Collect"))
end)
test("activity collection accepts touch Collect only",function()
 local player={} local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/GardenActivityService"))
 local x={Profile=function() return p end,Temp={[player]={}},U={CharacterTouchesSphere=function() return true end},Emit=function() end,Send=function() end,RollService={Charge=function() end},SocialService={Contribute=function() end},PollinatorService={AddMastery=function() end},MapService={Sector=function() return "Center" end}}
 s:Init(x) s.Offers[player]={touch={Id="touch",Kind="PollenSpark",Index=1,Nodes={Vector3.zero},Expires=os.clock()+10}}
 assert(not s:Collect(player,"touch",1,"Begin")) assert(not s:Collect(player,"touch",1,"Cancel")) assert(s:Collect(player,"touch",1,"Collect"))
end)
test("Workshop purchase prerequisites, balance, idempotence",function()
 local p=Schema.CreateDefault() p.Hive.Level=8 p.Tutorial.FeatureUnlocks.Workshop=true p.WorkshopV5.Points=5 p.Currencies.Coins=1000
 local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end,GardenPlotService={RefreshCapacity=function() end},TutorialService={Refresh=function() end},Emit=function() end})
 assert(not s:Buy({},"ROLL_2")) assert(s:Buy({},"ROLL_1")) assert(not s:Buy({},"ROLL_1")) assert(p.WorkshopV5.Points==4 and p.Currencies.Coins==970) assert(not s:Buy({},"LEGACY_1"))
end)
test("tutorial has 18 steps, reconnect progress, unlocks",function()
 local p=Schema.CreateDefault() local service=require(node("ServerScriptService/Services/TutorialService")) service:Init({Profile=function() return p end,EmitOnce=function() end})
 local T=require(rs.Config.TutorialConfig) assert(#T.Steps==18)
 for i=1,18 do local e=T.Steps[i].Event if e=="Deliveries" then p.Tutorial.Events.Delivery=3 else p.Tutorial.Events[e]=1 end service:Refresh({}) assert(p.Tutorial.Step>=i+1) end
 local copy=U.Copy(p) assert(Schema.Prepare(copy)) assert(copy.Tutorial.Step==19 and copy.Tutorial.FeatureUnlocks.Roll and copy.Tutorial.FeatureUnlocks.Trials)
end)
test("one-time point source and preservation of Nectar",function()
 local p=Schema.CreateDefault() local s=require(node("ServerScriptService/Services/WorkshopService")) s:Init({Profile=function() return p end}) s:Point({},"same",2) s:Point({},"same",2) assert(p.WorkshopV5.Points==2 and p.Currencies.AncientNectar==0)
end)
