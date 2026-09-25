from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
config=(ROOT/'src/ReplicatedStorage/Config/TutorialConfig.luau').read_text()
guide=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau').read_text()
service=(ROOT/'src/ServerScriptService/Services/TutorialService.luau').read_text()
default=(ROOT/'src/ServerScriptService/Data/DefaultProfile.luau').read_text()
locations=(ROOT/'src/ReplicatedStorage/Config/LocationsConfig.luau').read_text()
bloom=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text()
activity=(ROOT/'src/ServerScriptService/Services/GardenActivityService.luau').read_text()
activity_client=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau').read_text()

targets=set(re.findall(r'Target="([^"]+)"',config))
screen={'Roll','SeedSatchel'}
world={'Hive','Garden','Token','Workshop'}
sectors=set(re.findall(r'(SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{',locations))
unknown=targets-screen-world-sectors
assert not unknown, f"tutorial has unmapped targets: {sorted(unknown)}"

for token in (
    'if target=="Roll" then',
    'if target=="SeedSatchel" then',
    'if target=="Hive" then',
    'if target=="Garden" then',
    'elseif target=="Token" then',
    'elseif target=="Workshop" then',
    'elseif L.Sectors[target] then',
):
    assert token in guide, f"guide target resolver missing {token}"

for token in (
    'math.clamp(localX+targetSize.X*.5',
    'math.clamp(localY+targetSize.Y*.5',
    'calloutY=math.clamp(calloutY,22,rootSize.Y-22)',
    'local calloutX=math.clamp(cx,calloutW*.5+8,rootSize.X-calloutW*.5-8)',
):
    assert token in guide, f"screen target edge clamp missing {token}"

def clamp(v,lo,hi): return max(lo,min(v,hi))
def place(root_w,root_h,x,y,target_w,target_h):
    w=clamp(target_w+18,58,max(58,root_w-20))
    h=clamp(target_h+18,54,max(54,root_h-20))
    cx=clamp(x+target_w*.5,w*.5+8,root_w-w*.5-8)
    cy=clamp(y+target_h*.5,h*.5+8,root_h-h*.5-8)
    return cx-w*.5,cy-h*.5,w,h

for root_w,root_h in ((1366,768),(1280,720)):
    for target in ((-30,-20,54,54),(root_w-20,root_h-10,75,75),(root_w*.5,root_h-70,75,75)):
        x,y,w,h=place(root_w,root_h,*target)
        assert x>=7.99 and y>=7.99 and x+w<=root_w-7.99 and y+h<=root_h-7.99, (root_w,root_h,target,(x,y,w,h))

assert 'Event="TutorialActivity",Text="Complete an activity",Target="Token"' in config, "final tutorial activity step missing"
assert 'local tutorialStep=T.Steps[p.Tutorial.Step]' in activity, "activity completion must inspect current tutorial step"
assert 'if tutorialStep and tutorialStep.Event=="TutorialActivity" then self.X:Emit(player,"TutorialActivity",1) end' in activity, "the next completed activity must advance the final tutorial step"
assert 'local completedSector=o.Sector or self.X.MapService:Sector(player)' in activity, "sector activity analytics must remain separate from tutorial progression"
assert 'if completedSector and completedSector~="Center" then self.X:Emit(player,"WorldActivity",1) end' in activity, "sector activity event must remain available"
assert 'workspace:GetPartsInPart(part,self.TouchParams)' in activity_client, "activity tutorial target must be touch-collected"
assert "ProximityPrompt" not in activity_client, "activity tutorial must not require E/ProximityPrompt"

assert 'p.Tutorial.Step=#T.Steps+1' in service, "Skip must follow TutorialConfig length"
assert 'p.Tutorial.Skipped=true' in service
assert 'if not p.StarterBeeGranted then self.X.HiveService:Interact(player) end' in service
assert 'function S:Replay(player) self.X:Send(player,"Replay",T.Steps) end' in service, "Replay must be presentation-only"
assert 'Tutorial={Version=2,Step=1,FeatureUnlocks={},Events={}}' in default
assert 'local step=T.Steps[ui.ReplayIndex or p.Tutorial.Step]' in guide, "guide must resume from persisted Tutorial.Step"
assert 'self.ReplayIndex=i%#T.Steps+1' in bloom and 'self.ReplayIndex=(i-2)%#T.Steps+1' in bloom
print(f"PASS tutorial acceptance: {len(targets)} target types map to current UI/world targets, edge clamps hold, replay/skip/resume contracts are config-driven")
