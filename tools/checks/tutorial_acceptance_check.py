from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

config=read("src/ReplicatedStorage/Config/TutorialConfig.luau")
features=read("src/ReplicatedStorage/Config/FeatureUnlockConfig.luau")
guide=read("src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau")
service=read("src/ServerScriptService/Services/TutorialService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
default=read("src/ServerScriptService/Data/DefaultProfile.luau")
locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
activity_client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
pollinator_client=read("src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

ids=re.findall(r'\{Id="([^"]+)"',config)
expected=[
    "HiveIntro","StarterBee","BeeWork","PollenSpark","FirstSeed","Plant","Inventory",
    "Delivery","HiveUpgrade","WorkshopVisit","WorkshopPurchase","Synergy","SunnyVisit",
]
assert ids==expected, f"unexpected tutorial sequence: {ids}"
assert 'Version=3' in config
assert len(ids)==13

# Mandatory onboarding cannot depend on rare/random content.
for forbidden in ("Trait","BloomRoll","WorldActivity","TutorialActivity","Deliveries"):
    assert f'Event="{forbidden}"' not in config, f"random/slow mandatory step returned: {forbidden}"
need(config,'Target="TutorialToken"',"guaranteed tutorial token target")
need(config,'Target="WorkshopNode",NodeId="ROLL_1"',"exact first Workshop node target")
need(config,'Target="GardenSlot",Slot=3',"first planting slot")
need(config,'Target="SynergySlot",Slot=2',"synergy planting slot")

targets=set(re.findall(r'Target="([^"]+)"',config))
screen={"Roll","SeedSatchel","WorkshopNode"}
world={"Hive","Bee","TutorialToken","GardenSlot","SynergySlot","Workshop"}
sectors=set(re.findall(r'(SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{',locations))
unknown=targets-screen-world-sectors
assert not unknown, f"tutorial has unmapped targets: {sorted(unknown)}"

# UI and world guide resolvers.
for token in (
    'if step.Target=="Roll" then',
    'if step.Target=="SeedSatchel" then',
    'if step.Target=="WorkshopNode" then',
    'if target=="Hive" then',
    'elseif target=="Bee" then',
    'elseif target=="TutorialToken" then',
    'elseif target=="GardenSlot" then',
    'elseif target=="SynergySlot" then',
    'elseif target=="Workshop" then',
    'elseif L.Sectors[target] then',
):
    need(guide,token,"guide target resolver")

for token in (
    'math.clamp(localX+targetSize.X*.5',
    'math.clamp(localY+targetSize.Y*.5',
    'calloutY=math.clamp(calloutY,24,rootSize.Y-24)',
    'local calloutX=math.clamp(cx,calloutW*.5+8,rootSize.X-calloutW*.5-8)',
):
    need(guide,token,"screen target edge clamp")

need(guide,'self.Beam.Enabled=distance>15',"short-distance beam suppression")
need(guide,'Instance.new("Highlight")',"world highlight")
need(guide,'warn(string.format("[Tutorial] target missing step=%s target=%s"', "missing target diagnostic")
need(guide,'ui.Activities:Target("Tutorial")',"tutorial token pointer")
need(guide,'ui.Bees:Target(true)',"local bee pointer")
need(guide,'runtime:FindFirstChild("Node_"..tostring(step.NodeId or "ROLL_1"),true)',"Workshop node pointer")
need(guide,'if step.Id=="Delivery" and ui.Menu=="SeedSatchel" then ui:Close() end',"Inventory handoff")
need(guide,'if step.Id=="Synergy" and ui.Menu=="Workshop" then ui:Close() end',"Workshop handoff")
need(pollinator_client,'function S:Target(ownerOnly)',"bee target accessor")

def clamp(v,lo,hi):
    return max(lo,min(v,hi))

def place(root_w,root_h,x,y,target_w,target_h):
    w=clamp(target_w+18,58,max(58,root_w-20))
    h=clamp(target_h+18,54,max(54,root_h-20))
    cx=clamp(x+target_w*.5,w*.5+8,root_w-w*.5-8)
    cy=clamp(y+target_h*.5,h*.5+8,root_h-h*.5-8)
    return cx-w*.5,cy-h*.5,w,h

for root_w,root_h in ((1920,1080),(1366,768),(1280,720)):
    for target in ((-30,-20,54,54),(root_w-20,root_h-10,75,75),(root_w*.5,root_h-70,75,75)):
        x,y,w,h=place(root_w,root_h,*target)
        assert x>=7.99 and y>=7.99 and x+w<=root_w-7.99 and y+h<=root_h-7.99, (root_w,root_h,target,(x,y,w,h))

# Server-authoritative ordered progression.
need(service,'local function completionKey(step)',"step completion persistence")
need(service,'function S:RecordEvent(player,event)',"current-step event recorder")
need(service,'if not step or step.Event~=event then return false end',"future event rejection")
need(player,'self.TutorialService:RecordEvent(player,event)',"PlayerService tutorial event routing")
need(service,'while T.Steps[t.Step] and t.Events[completionKey(T.Steps[t.Step])] do',"ordered step progression")
need(service,'self.X.U.Near(player,pos,6.5)',"Hive approach server validation")
need(service,'self.X.GardenActivityService:EnsureTutorialSpark(player)',"guaranteed tutorial Pollen Spark")
need(service,'elseif step.Id=="SunnyVisit" then',"SunnyVisit recovery branch")
need(service,'self.X.MapService:Sector(player)=="SunnyOrchard"',"SunnyVisit server position recovery")
need(service,'self.X:Emit(player,"SunnyVisit",1)',"SunnyVisit current-step event replay")
need(service,'p.Hive.Honey=need',"tutorial Hive upgrade assist")
need(service,'p.WorkshopV5.Points=math.max(p.WorkshopV5.Points,node.Cost or 0)',"Workshop point assist")
need(service,'p.Currencies.Coins=math.max(p.Currencies.Coins,node.Coins or 0)',"Workshop Coin assist")
need(service,'p.FlowerCollection.OwnedSeedCopies.Tulip=(p.FlowerCollection.OwnedSeedCopies.Tulip or 0)+1',"synergy seed assist")
need(player,'self.TutorialService:Tick(player)',"tutorial recovery tick")

# Guaranteed activity and first roll.
need(activity,'function S:EnsureTutorialSpark(player)',"tutorial activity factory")
need(activity,'Tutorial=tutorial==true',"tutorial activity ownership")
need(activity,'function S:HasTutorialOffer(player,kind)',"tutorial activity dedupe")
need(activity,'o.Expires>=workspace:GetServerTimeNow()',"expired tutorial offer rejection")
need(activity_client,'workspace:GetPartsInPart(part,self.TouchParams)',"client body overlap")
assert "ProximityPrompt" not in activity_client, "activity client must not require E/ProximityPrompt"
need(activity,'self.X.U.CharacterTouchesSphere(player,o.Nodes[o.Index],cfg.Radius or .75,A.TouchTolerance or .5)',"server body overlap")
need(roll,'tutorialStep.Id=="FirstSeed"', "tutorial roll detection")
need(roll,'v.Kind=="FlowerSeed" and v.Id=="Sunflower"', "deterministic first seed")

# Persistence/migration/reconnect.
need(default,'Tutorial={Version=3,Step=1,FeatureUnlocks={},Events={}}',"new profile tutorial version")
need(service,'if t.Version==T.Version then return false end',"tutorial migration guard")
need(service,'local wasComplete=t.Events.TutorialComplete or t.Step>#T.Steps',"shortened tutorial completion migration")
need(service,'t.Events[completionKey(step)]=1',"legacy event migration")
need(service,'p.Tutorial.Step=#T.Steps+1',"Skip follows config length")
need(service,'p.Tutorial.Skipped=true',"Skip persistence")
need(service,'function S:Replay(player)',"Replay endpoint")
need(service,'self.X:Send(player,"Replay",T.Steps)',"Replay presentation only")
need(features,'Roll={Step=5}',"Roll unlock timing")

# Completion handoff.
need(bloom,'self.ObjectiveTitle.Text="TUTORIAL COMPLETE"',"completion title")
need(bloom,'self.ObjectiveText.Text="Your garden journey begins now."',"completion copy")
need(bloom,'if previousTutorialStep and previousTutorialStep<=#T.Steps and nextTutorialStep and nextTutorialStep>#T.Steps then',"completion transition")
need(bloom,'self.ObjectiveTitle.Text="JOURNEY  •  STEP "',"Journey handoff")
need(guide,'local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]',"persisted guide resume")
need(bloom,'self.ReplayIndex=i%#T.Steps+1',"Replay next is config-driven")
need(bloom,'self.ReplayIndex=(i-2)%#T.Steps+1',"Replay previous is config-driven")

# No stale fixed tutorial-length assumptions in live tutorial code/check.
for path in (
    "src/ReplicatedStorage/Config/TutorialConfig.luau",
    "src/ServerScriptService/Services/TutorialService.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau",
    "src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau",
):
    text=read(path)
    for stale in ("18/18","17/17","#T.Steps==18","#T.Steps==17"):
        assert stale not in text, f"{path} contains stale tutorial length {stale}"

print("PASS tutorial acceptance: 13 deterministic server-authoritative steps, exact UI/world pointers, migration/recovery and responsive guide contracts")
