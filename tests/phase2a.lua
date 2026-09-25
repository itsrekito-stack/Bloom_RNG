-- Cooperative virtual time lets UpdateAsync remain in flight across leave/close.
local oldClock,oldTime=os.clock,os.time
local oldGame=game
local now,queue,logs,guid=0,{}, {},0
local function spawn(fn,...)
 local args={...}
 table.insert(queue,{At=now,Thread=coroutine.create(function() fn(table.unpack(args)) end)})
end
local function runUntil(done,limit)
 local deadline=now+(limit or 100)
 local steps=0
 while not done() do
  table.sort(queue,function(a,b) return a.At<b.At end)
  local job=table.remove(queue,1)
  assert(job and job.At<=deadline,'scheduler deadline')
  now=job.At steps=steps+1 assert(steps<100000,'scheduler spin')
  local ok,delay=coroutine.resume(job.Thread)
  assert(ok,delay)
  if coroutine.status(job.Thread)~='dead' then
   job.At=now+(delay or .01);table.insert(queue,job)
  end
 end
end
local function scenario(fn)
 now=0 queue={} logs={} guid=0
 local done=false
 spawn(function() fn();done=true end)
 runUntil(function() return done end,300)
end
local function signal()
 local callbacks={}
 return {Connect=function(_,fn) table.insert(callbacks,fn);return {Disconnect=function() end} end,
 Fire=function(_,...) for _,fn in ipairs(callbacks) do spawn(fn,...) end end}
end
local function setup()
 local players={PlayerAdded=signal(),PlayerRemoving=signal()}
 function players:GetPlayers() return {} end
 local db={Values={},Calls=0,Writes=0,Mode='ok',Delay=0,InFlight=0,MaxInFlight=0,PerKey={}}
 function db:UpdateAsync(key,fn)
  self.Calls=self.Calls+1 self.InFlight=self.InFlight+1
  self.MaxInFlight=math.max(self.MaxInFlight,self.InFlight)
  self.PerKey[key]=(self.PerKey[key] or 0)+1
  assert(self.PerKey[key]==1,'concurrent writer for same key')
  local function finish() self.InFlight=self.InFlight-1 self.PerKey[key]=self.PerKey[key]-1 end
  if self.Delay>0 then task.wait(self.Delay) end
  local mode=self.Mode
  if mode=='before-error' then finish();error('mock service unavailable') end
  if mode=='nil' then finish();return nil end
  local value=fn(U.Copy(self.Values[key]))
  if value then self.Values[key]=U.Copy(value);self.Writes=self.Writes+1 end
  finish()
  if mode=='response-error' then error('mock lost acknowledgement') end
  return U.Copy(value)
 end
 os.clock=function() return now end;os.time=function() return 100000+math.floor(now) end
 task={spawn=spawn,wait=function(n) return coroutine.yield(n or .01) end}
 warn=function(...) table.insert(logs,table.concat({...},' ')) end
 Instance={new=function(kind) assert(kind=='BindableEvent');local s=signal();return {Event=s,Fire=function(_,...) s:Fire(...) end} end}
 game={JobId='test-server',GetService=function(_,name)
  if name=='Players' then return players end
  if name=='DataStoreService' then return {GetDataStore=function(_,name) assert(name=='FruitRNG_PlayerProfiles_TEST_v1');return db end} end
  if name=='RunService' then return {IsStudio=function() return true end} end
  if name=='HttpService' then return {GenerateGUID=function() guid=guid+1;return 'guid-'..guid end} end
  return node(name)
 end,BindToClose=function(self,fn) self.Close=fn end}
 cache['ServerScriptService/Services/DataService']=nil
 cache['ServerScriptService/Data/DataConfig']=nil
 local service=require(node('ServerScriptService/Services/DataService'));service:Init()
 local function player(id)
  local p={UserId=id,Name='P'..id,Parent=players,Attributes={}}
  function p:SetAttribute(k,v) self.Attributes[k]=v end
  function p:Kick(message) self.Kicked=message end
  assert(service:LoadProfile(p).Code=='SUCCESS')
  return p
 end
 return service,db,player,players
end

test('final save success releases confirmed snapshot',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=42
 assert(s:ReleaseProfile(p).Code=='SUCCESS');assert(s:GetPersistenceStatus(p).State=='Released')
 assert(db.Values.Player_1.Data.Currencies.Coins==42 and not db.Values.Player_1.Session)
end) end)
test('failed final save retains candidate and recovers same operation',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=91
 db.Mode='before-error';spawn(function() task.wait(1.5);assert(s:GetPersistenceStatus(p).State=='RetryPending');db.Mode='ok' end)
 local r=s:ReleaseProfile(p);assert(r.Code=='SUCCESS');assert(db.Values.Player_1.Data.Currencies.Coins==91)
end) end)
test('repeated ambiguous failure bounded and never released',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=91;db.Mode='before-error'
 local r=s:ReleaseProfile(p);assert(r.Code=='TIMEOUT' and r.Pending)
 runUntil(function() return s:GetPersistenceStatus(p).State=='UnknownOutcome' end)
 local calls=db.Calls;assert(calls==7);assert(s:ReleaseProfile(p).Code=='UNKNOWN_OUTCOME')
 assert(db.Calls==calls and s:GetProfile(p)==nil and db.Values.Player_1.Data.Currencies.Coins==0)
 assert(#logs>0)
end) end)
test('definite no-write retries bounded separately',function() scenario(function()
 local s,db,new=setup();local p=new(1);db.Mode='nil';s:ReleaseProfile(p)
 runUntil(function() return s:GetPersistenceStatus(p).State=='RecoveryFailed' end)
 assert(s:ReleaseProfile(p).Code=='RETRYABLE_FAILURE' and db.Calls==7)
end) end)
test('ownership loss prohibits final overwrite',function() scenario(function()
 local s,db,new=setup();local p=new(1);db.Values.Player_1.Session.Token='other';local writes=db.Writes
 assert(s:ReleaseProfile(p).Code=='OWNERSHIP_LOST');assert(db.Writes==writes and s:GetPersistenceStatus(p).State=='Lost')
end) end)
test('transaction committed with lost acknowledgement is confirmed by id',function() scenario(function()
 local s,db,new=setup();local p=new(1);local c=U.Copy(s:GetProfile(p));c.Season.Count=1
 db.Mode='response-error';spawn(function() task.wait(.5);db.Mode='ok' end)
 local r=s:CommitProfile(p,c,'turn-1');assert(r.Code=='SUCCESS');assert(s:GetProfile(p).Season.Count==1)
 assert(db.Writes==2,'confirmation must not rewrite');assert(db.Values.Player_1.Data.LastTransactionId=='turn-1')
end) end)
test('unknown transaction cannot be overwritten by stale normal save',function() scenario(function()
 local s,db,new=setup();local p=new(1);local c=U.Copy(s:GetProfile(p));c.Season.Count=1;db.Mode='response-error'
 local r=s:CommitProfile(p,c,'turn-1');assert(r.Code=='TIMEOUT')
 runUntil(function() return s:GetPersistenceStatus(p).State=='UnknownOutcome' end)
 local calls=db.Calls;assert(s:SaveProfile(p,false).Code~='SUCCESS');assert(s:ReleaseProfile(p).Code=='UNKNOWN_OUTCOME')
 assert(db.Calls==calls and db.Values.Player_1.Data.Season.Count==1 and not s:GetProfile(p))
end) end)
test('PlayerRemoving during transaction releases post-turn snapshot',function() scenario(function()
 local s,db,new=setup();local p=new(1);local c=U.Copy(s:GetProfile(p));c.Season.Count=1;db.Delay=2
 local result;spawn(function() result=s:CommitProfile(p,c,'turn-1') end)
 task.wait(.1);p.Parent=nil;local final=s:ReleaseProfile(p)
 assert(final.Code=='SUCCESS' and result.Code=='SUCCESS');assert(db.Values.Player_1.Data.Season.Count==1)
 assert(not db.Values.Player_1.Session and db.MaxInFlight==1)
end) end)
test('shutdown coordinates active transaction and concurrent player release',function() scenario(function()
 local s,db,new=setup();local p=new(1);local q=new(2);s:GetProfile(q).Currencies.Coins=17
 local c=U.Copy(s:GetProfile(p));c.Season.Count=1;db.Delay=2
 spawn(function() s:CommitProfile(p,c,'turn-1') end);task.wait(.1);s:Shutdown()
 assert(not db.Values.Player_1.Session and not db.Values.Player_2.Session)
 assert(db.Values.Player_1.Data.Season.Count==1 and db.Values.Player_2.Data.Currencies.Coins==17)
 assert(db.MaxInFlight>=2)
end) end)
test('hung operation cannot deadlock shutdown or start a second writer',function() scenario(function()
 local s,db,new=setup();local p=new(1);db.Delay=100
 spawn(function() s:SaveProfile(p,false) end);task.wait(.1);local start=now;s:Shutdown()
 assert(now-start<=25.1 and db.Calls==2 and s:GetPersistenceStatus(p).State~='Released')
 assert(logs[#logs]:find('SHUTDOWN_TIMEOUT_IN_FLIGHT'))
end) end)
test('rejoin on same server rejected while previous record unresolved',function() scenario(function()
 local s,db,new,players=setup();local p=new(1);db.Mode='before-error';s:ReleaseProfile(p)
 local q={UserId=1,Parent=players};function q:Kick(m) self.Kicked=m end
 assert(s:LoadProfile(q).Code=='RETRYABLE_FAILURE' and q.Kicked);assert(s:GetProfile(q)==nil)
end) end)
test('expired lease is never resurrected by an old save',function() scenario(function()
 local s,db,new=setup();local p=new(1);now=now+181
 assert(s:SaveProfile(p,false).Code=='OWNERSHIP_LOST' and db.Writes==1)
end) end)
os.clock=oldClock;os.time=oldTime;game=oldGame

local function respecFixture()
 local p=Schema.CreateDefault();p.WorkshopV5.Nodes={GARDEN_1=true,BEES_1=true};p.Garden.UnlockedSlots=4
 p.Garden.Slots[4]={};p.Tutorial.FeatureUnlocks.Workshop=true
 local s=require(node('ServerScriptService/Services/WorkshopService'))
 s:Init({Profile=function() return p end,GardenPlotService={RefreshCapacity=function() p.Garden.UnlockedSlots=require(rs.Shared.GardenRules).FlowerCapacity(p) end},
 GardenSynergyService={Recalculate=function() end},TutorialService={Refresh=function() end}})
 return p,s
end
test('respec with empty overflow preserves ownership and valid slots',function()
 local p,s=respecFixture();local copies=U.Copy(p.FlowerCollection.OwnedSeedCopies)
 assert(s:Respec({}));assert(p.Garden.UnlockedSlots==3 and equal(copies,p.FlowerCollection.OwnedSeedCopies))
 assert(Schema.Prepare(p))
end)
test('respec occupied overflow rejects atomically before refunds',function()
 local p,s=respecFixture();p.Garden.Slots[4]={SpeciesId='Daisy',Level=1,XP=0,Mutation='',TotalPollination=0}
 p.FlowerCollection.OwnedSeedCopies.Daisy=2
 local before=U.Copy(p);local ok,reason=s:Respec({});assert(not ok and reason=='RESPEC_GARDEN_OCCUPIED' and equal(before,p))
end)
test('respec progressed mutated overflow rejects without state loss',function()
 local p,s=respecFixture();p.Garden.Slots[4]={SpeciesId='Daisy',Level=12,XP=30,Mutation='Radiant',TotalPollination=80}
 p.FlowerCollection.OwnedSeedCopies.Daisy=2
 local before=U.Copy(p);assert(not s:Respec({}));assert(equal(before,p))
end)
test('respec overflow bee unequips without destroying bee ownership',function()
 local p,s=respecFixture();p.Pollinators.BeeInventory.WorkerBee=2;p.Pollinators.EquippedBeeSlots={'WorkerBee','WorkerBee'}
 assert(s:Respec({}));assert(p.Pollinators.BeeInventory.WorkerBee==2 and p.Pollinators.EquippedBeeSlots[1]=='WorkerBee' and not p.Pollinators.EquippedBeeSlots[2])
end)
test('schema negative active values repair and retain original diagnostic values',function()
 local p=Schema.CreateDefault();p.Currencies.Coins=-5;p.Hive.Honey=-20;p.WorkshopV5.Points=-3;p.FlowerCollection.OwnedSeedCopies.Tulip=-9
 assert(Schema.Prepare(p));assert(p.Currencies.Coins==0 and p.Hive.Honey==0 and p.WorkshopV5.Points==0 and p.FlowerCollection.OwnedSeedCopies.Tulip==0)
 assert(p.LegacyArchive.DomainV1.Currencies.Coins==-5)
end)
test('schema NaN and infinity reject without changing source',function()
 for _,bad in ipairs({0/0,math.huge,-math.huge}) do local p=Schema.CreateDefault();p.Currencies.Coins=bad;assert(not Schema.Prepare(p));assert(p.Garden.Slots[1].SpeciesId=='Daisy') end
end)
test('schema unknown registries archived and future keys retained',function()
 local p=Schema.CreateDefault();p.WorkshopV5.Nodes.OLD_NODE=true;p.WorkshopV5.Nodes.ROLL_1=false
 p.WorkshopV5.ClaimedSources.Hive_999_2=true;p.FlowerCollection.OwnedSeedCopies.OldFlower=7
 p.Pollinators.BeeInventory.OldBee=2;p.FutureSystem={Value=17};p.LegacyArchive={Original={K=1}}
 assert(Schema.Prepare(p));assert(not p.WorkshopV5.Nodes.OLD_NODE and not p.WorkshopV5.Nodes.ROLL_1)
 assert(p.WorkshopV5.ClaimedSources.Hive_999_2 and p.LegacyArchive.Original.K==1 and p.FutureSystem.Value==17)
 assert(p.LegacyArchive.DomainV1['WorkshopV5.Nodes'].OLD_NODE and p.LegacyArchive.DomainV1['FlowerCollection.OwnedSeedCopies'].OldFlower==7)
end)
test('schema excessive equipment repairs while preserving owned counts',function()
 local p=Schema.CreateDefault();p.Pollinators.BeeInventory.WorkerBee=10;p.Pollinators.EquippedBeeSlots={[1]='WorkerBee',[2]='WorkerBee',[99]='WorkerBee'}
 assert(Schema.Prepare(p));assert(p.Pollinators.BeeInventory.WorkerBee==10 and p.Pollinators.EquippedBeeSlots[1]=='WorkerBee' and not p.Pollinators.EquippedBeeSlots[2] and not p.Pollinators.EquippedBeeSlots[99])
end)
test('schema invalid occupied slot rejects without silent removal',function()
 local p=Schema.CreateDefault();p.Garden.Slots[4]={SpeciesId='Daisy',Level=6,XP=9,Mutation='Radiant'};p.FlowerCollection.OwnedSeedCopies.Daisy=2
 local before=U.Copy(p);local ok,why=Schema.Prepare(p);assert(not ok and why:find('GARDEN_CAPACITY_CONFLICT') and equal(before,p))
 p.Garden.Slots[4]=nil;p.Garden.Slots[1].SpeciesId='UnknownFlower';before=U.Copy(p);assert(not Schema.Prepare(p) and equal(before,p))
end)
test('schema inconsistent planted ownership rejected without granting copies',function()
 local p=Schema.CreateDefault();p.Garden.Slots[2]=U.Copy(p.Garden.Slots[1]);local before=U.Copy(p)
 assert(not Schema.Prepare(p) and equal(before,p))
end)
test('schema huge finite values reject instead of silently capping earned progression',function()
 local p=Schema.CreateDefault();p.Currencies.Coins=1e30;assert(not Schema.Prepare(p) and p.Currencies.Coins==1e30)
 p.Currencies.Coins=2e12;assert(Schema.Prepare(p) and p.Currencies.Coins==2e12)
end)
test('schema valid progression round trip idempotent after mutation',function()
 local p=Schema.CreateDefault();assert(Schema.Prepare(p))
 p.Hive.Level=4;p.Garden.UnlockedSlots=6;p.FlowerCollection.OwnedSeedCopies.Tulip=3;p.FlowerCollection.DiscoveredFlowers.Tulip=true
 p.Garden.Slots[6]={SpeciesId='Tulip',Level=7,XP=21,TotalPollination=99,Mutation='HistoricalMutation',Extra={Tag='keep'}}
 p.FlowerCollection.FlowerMastery.Tulip={Level=12,XP=17};p.FlowerCollection.FavoriteFlowers.Tulip=true;p.FlowerCollection.LockedFlowers.Tulip=true
 p.Currencies.Coins=1234.5;assert(Schema.Prepare(p));local before=U.Copy(p)
 assert(Schema.Validate(p));assert(Schema.Prepare(p) and equal(before,p))
 assert(p.Garden.Slots[6].Extra.Tag=='keep' and p.Garden.Slots[6].Mutation=='HistoricalMutation')
end)
test('schema old migration retains original legacy archive and mappings',function()
 local p={Inventory={Apple=2},Currencies={FruitDust=4},LegacyArchive={Preexisting='keep'}}
 assert(Schema.Prepare(p));assert(p.LegacyArchive.Preexisting=='keep' and p.FlowerCollection.OwnedSeedCopies.Daisy==3)
 local before=U.Copy(p);assert(Schema.Prepare(p) and equal(before,p))
end)
test('schema future version rejected rather than downgraded',function()
 local p=Schema.CreateDefault();p.SchemaVersion=99;assert(not Schema.Prepare(p) and p.SchemaVersion==99)
end)
test('plant replacement and unplant block progressed state loss',function()
 local p=Schema.CreateDefault();assert(Schema.Prepare(p));p.Garden.Slots[1].Level=2;p.Garden.Slots[1].Mutation='Radiant';p.FlowerCollection.OwnedSeedCopies.Tulip=1
 local s=require(node('ServerScriptService/Services/GardenPlotService'));local player={}
 s:Init({Profile=function() return p end,U={Integer=U.Integer,Near=function() return true end}})
 local oldPosition=s.Position;s.Position=function() return Vector3.zero end
 local before=U.Copy(p);local ok,reason=s:Plant(player,1,'');assert(not ok and reason=='GARDEN_PROGRESS_PROTECTED' and equal(p,before))
 assert(not s:Plant(player,1,'Tulip'));assert(s:Plant(player,1,'Daisy'));s.Position=oldPosition
end)
test('lease-expired read cannot return previous successful save as final success',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=2;assert(s:SaveProfile(p,false).Code=='SUCCESS')
 s:GetProfile(p).Currencies.Coins=3;now=now+181;assert(not s:GetProfile(p));assert(s:ReleaseProfile(p).Code=='OWNERSHIP_LOST')
 assert(db.Values.Player_1.Data.Currencies.Coins==2)
end) end)
test('leave during autosave uses fresh final snapshot after serialized save',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=1;db.Delay=2
 spawn(function() s:SaveProfile(p,false) end);task.wait(.1);s:GetProfile(p).Currencies.Coins=7
 assert(s:ReleaseProfile(p).Code=='SUCCESS');assert(db.Values.Player_1.Data.Currencies.Coins==7 and db.MaxInFlight==1)
end) end)
test('real Season caller does not rebuild after timed-out commit and late release',function() scenario(function()
 local s,db,new=setup();local player=new(1);local profile=s:GetProfile(player)
 local season=require(node('ServerScriptService/Services/SeasonService'));local previousEligible=season.Eligible;season.Eligible=function() return true end
 local rebuilt=0
 season:Init({Profile=function(_,p) return s:GetProfile(p) end,DataService=s,U=U,Revisions={[player]=0},Temp={[player]={}},
 Send=function() end,GardenActivityService={CancelGarden=function() end},PollinatorService={Remove=function() end},
 GardenPlotService={Build=function() rebuilt=rebuilt+1 end}})
 season.Pending[player]={Token='turn',Revision=0,Expires=now+30,Confirm=1,Before=U.Copy(profile)}
 db.Delay=21;local ok,why=season:Confirm(player,'turn');assert(not ok and why=='PERSISTENCE_UNCONFIRMED')
 assert(not s:GetProfile(player) and not season.Pending[player] and player.Kicked)
 runUntil(function() return s:GetPersistenceStatus(player).State=='Released' end,60)
 assert(db.Values.Player_1.Data.Season.Count==1 and rebuilt==0 and db.MaxInFlight==1)
 season.Eligible=previousEligible
end) end)
test('Start wires PlayerRemoving and BindToClose to same owner',function() scenario(function()
 local s,db,new,players=setup();s:Start();local p=new(1);s:GetProfile(p).Currencies.Coins=8;db.Delay=1
 p.Parent=nil;players.PlayerRemoving:Fire(p);task.wait(.1);game.Close()
 assert(s:GetPersistenceStatus(p).State=='Released' and db.Values.Player_1.Data.Currencies.Coins==8 and db.MaxInFlight==1)
end) end)
os.clock=oldClock;os.time=oldTime;game=oldGame
test('final release acknowledgement loss does not cause a duplicate write',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Currencies.Coins=11;db.Mode='response-error'
 spawn(function() task.wait(.5);db.Mode='ok' end)
 assert(s:ReleaseProfile(p).Code=='SUCCESS');assert(db.Writes==2 and not db.Values.Player_1.Session)
end) end)
test('invalid live profile is retained and has explicit final failure',function() scenario(function()
 local s,db,new=setup();local p=new(1);s:GetProfile(p).Garden.Slots[4]={SpeciesId='Daisy',Level=9}
 assert(s:SaveProfile(p,false).Code=='INVALID_PROFILE');assert(s:ReleaseProfile(p).Code=='INVALID_PROFILE')
 assert(s:GetPersistenceStatus(p).State=='RecoveryFailed' and db.Writes==1)
end) end)
test('successful Season caller rebuilds exactly once with committed data',function() scenario(function()
 local s,db,new=setup();local player=new(1);local profile=s:GetProfile(player)
 local season=require(node('ServerScriptService/Services/SeasonService'));local previousEligible=season.Eligible;season.Eligible=function() return true end
 local rebuilt=0
 season:Init({Profile=function(_,p) return s:GetProfile(p) end,DataService=s,U=U,Revisions={[player]=0},Temp={[player]={}},
 Send=function() end,GardenActivityService={CancelGarden=function() end},PollinatorService={Remove=function() end},
 GardenPlotService={Build=function() assert(s:GetProfile(player).Season.Count==1);rebuilt=rebuilt+1 end}})
 season.Pending[player]={Token='turn',Revision=0,Expires=now+30,Confirm=1,Before=U.Copy(profile)}
 assert(season:Confirm(player,'turn'));assert(rebuilt==1 and s:GetProfile(player) and not season.Pending[player]);season.Eligible=previousEligible
end) end)
os.clock=oldClock;os.time=oldTime;game=oldGame
