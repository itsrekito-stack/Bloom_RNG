from pathlib import Path
import json,sys
ROOT=Path(__file__).resolve().parents[2]
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))
project=json.loads((ROOT/'default.project.json').read_text(encoding='utf-8'))
source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text(encoding='utf-8')
roll_service=(ROOT/'src/ServerScriptService/Services/RollService.luau').read_text(encoding='utf-8')
feature=(ROOT/'src/ReplicatedStorage/Config/FeatureUnlockConfig.luau').read_text(encoding='utf-8')
audio=(ROOT/'src/ReplicatedStorage/Config/RollAudioConfig.luau').read_text(encoding='utf-8')
checks=[]

def check(name,cond,detail=''): checks.append((name,bool(cond),detail))
def walk(n,path=''):
    name=n.get('Name') or n.get('ClassName')
    p=f'{path}/{name}' if path else name
    yield p,n
    for c in n.get('Children',[]) or []: yield from walk(c,p)
nodes=list(walk(model)); by_name={}
for p,n in nodes: by_name.setdefault(n.get('Name'),[]).append((p,n))
def one(name):
    xs=by_name.get(name,[]); return xs[0] if xs else (None,None)

safe_path,safe=one('SafeRoot')
rollhud_path,rollhud=one('RollHUD')
roulette_path,roulette=one('VerticalRoulette')
button_path,button=one('RollButton')
check('StarterGui mapped to src/StarterGui',project['tree']['StarterGui'].get('$path')=='src/StarterGui')
check('BloomUI declarative ScreenGui',model.get('ClassName')=='ScreenGui' and model.get('Name')=='BloomUI')
check('ScreenGui uses sibling ZIndex for dynamic menus',model.get('Properties',{}).get('ZIndexBehavior')=='Sibling')
check('roulette direct child of SafeRoot',roulette_path==safe_path+'/VerticalRoulette',roulette_path or '')
check('roll button direct child of SafeRoot',button_path==safe_path+'/RollButton',button_path or '')
check('Bloom meter independent',rollhud_path==safe_path+'/RollHUD',rollhud_path or '')
vp=roulette.get('Properties',{}) if roulette else {}
check('roulette transparent',vp.get('BackgroundTransparency')==1)
check('roulette clips to three visible rows',vp.get('ClipsDescendants') is True and vp.get('Size',{}).get('UDim2',[[0,0],[0,0]])[1][1]==140)
for role in ['Next','Current','Previous']:
    p,slot=one(role); check('roulette '+role,slot is not None)
    if slot:
        sp=slot.get('Properties',{})
        check(role+' transparent',sp.get('BackgroundTransparency')==1)
        names={c.get('Name') for c in slot.get('Children',[])}
        check(role+' only icon/name/chance',{'Icon','Name','Chance'}.issubset(names))
check('controller semantic roulette slots','Current=self.RouletteStrip:WaitForChild("Current")' in source and 'WaitForChild("Buffer")' not in source)
check('top next / middle current / bottom previous logic','RouletteSlots.Next' in source and 'RouletteSlots.Current' in source and 'RouletteSlots.Previous' in source)
check('runtime buffer cloned locally','function UI:EnsureRouletteRuntimeBuffer' in source and 'source:Clone()' in source and '_RuntimeBuffer' in source)
check('no authored Buffer required',one('Buffer')[1] is None)
check('fractional drop chance','"1 / "..compact' in source)
check('long settle sequence','SettleSteps' in audio and ('MinimumVisualSpin=2.35' in audio or 'MinimumVisualSpin=2.3' in audio) and 'function UI:ResolveRouletteReward' in source)
check('vertical downward tween','Position=UDim2.fromOffset(0,RollAudio.StepPixels)' in source)
check('spin sound','SpinSound=' in audio and 'PlayRouletteTick' in source)
check('reward sound','RewardSound=' in audio and 'PlayRouletteRewardSound' in source)
check('landing result animation','function UI:AnimateRouletteResult' in source and 'Scale=1.18' in source)
check('Roll is toggle','self:SetAutoRolling(not self.Auto)' in source)
check('auto-roll blocks while landing','not self.RouletteLanding then self:RollNow(true)' in source)
check('SeedSatchel unlocks on first seed','SeedSatchel={Event="SeedReward"}' in feature)
check('plant picker has explicit empty-state','Нет свободных семян' in source)
check('dynamic controls inherit panel ZIndex','parent.ZIndex+1' in source)
check('auto roll no longer Workshop-locked','automatic and not p.Tutorial.FeatureUnlocks.AutoRoll' not in roll_service)
# Authored desktop geometry: roulette right-mid, roll bottom center, meter above roll.
check('roulette editable position exists',vp.get('Position',{}).get('UDim2') is not None)
check('roll editable position exists',button.get('Properties',{}).get('Position',{}).get('UDim2') is not None if button else False)
check('roulette top centered',vp.get('Position',{}).get('UDim2')==[[0.5,0],[0,110]] and vp.get('AnchorPoint',{}).get('Vector2')==[0.5,0])
marker=one('CurrentMarker')[1]
check('current slot visibly marked',marker is not None and {c.get('Name') for c in marker.get('Children',[])}.issuperset({'LeftPointer','RightPointer','CurrentLabel'}))
panel=one('MainPanel')[1]
check('main panel compact',panel is not None and panel.get('Properties',{}).get('Size',{}).get('UDim2')==[[0,620],[0,440]])
check('softer roulette audio','button.wav' in audio and 'SpinVolume=.055' in audio and 'RewardVolume=.14' in audio)
check('Pet-Sim seed grid','InventoryGrid' in source and 'UIGridLayout' in source and 'SelectedDetails' in source)

check('live-sync resolver exists','function UI:ResolveBloomGui()' in source)
check('Studio prefers authored StarterGui template','RunService:IsStudio()' in source and 'StarterGui:FindFirstChild("BloomUI")' in source)
check('Studio fallback clones StarterGui into PlayerGui','local clone=template:Clone()' in source and 'clone.Parent=playerGui' in source)
check('old PlayerGui clone error removed','StarterGui/BloomUI was not cloned into PlayerGui' not in source)

out=[]
for name,ok,detail in checks: out.append(('PASS' if ok else 'FAIL')+' '+name+((' — '+detail) if detail else ''))
out.append(f'TOTAL {sum(x[1] for x in checks)}/{len(checks)} PASS')
text='\n'.join(out)+'\n'
(ROOT/'tests/ui_startergui_audit.txt').write_text(text,encoding='utf-8')
print(text,end='')
if not all(x[1] for x in checks): sys.exit(1)
