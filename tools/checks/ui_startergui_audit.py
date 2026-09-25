from pathlib import Path
import json,sys

ROOT=Path(__file__).resolve().parents[2]
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))
project=json.loads((ROOT/'default.project.json').read_text(encoding='utf-8'))
source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text(encoding='utf-8')
inventory_v2_source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau').read_text(encoding='utf-8')
player_source=(ROOT/'src/ServerScriptService/Services/PlayerService.luau').read_text(encoding='utf-8')
remote_source=(ROOT/'src/ServerScriptService/Services/RemoteService.luau').read_text(encoding='utf-8')
roll_source=(ROOT/'src/ServerScriptService/Services/RollService.luau').read_text(encoding='utf-8')
editor_source=(ROOT/'tools/bloom-ui-editor/app.js').read_text(encoding='utf-8')
editor_html=(ROOT/'tools/bloom-ui-editor/index.html').read_text(encoding='utf-8')
audio=(ROOT/'src/ReplicatedStorage/Config/RollAudioConfig.luau').read_text(encoding='utf-8')
checks=[]

def check(name,cond,detail=''): checks.append((name,bool(cond),detail))
def walk(n,path=''):
    name=n.get('Name') or n.get('ClassName')
    p=f'{path}/{name}' if path else name
    yield p,n
    for c in n.get('Children',[]) or []:
        yield from walk(c,p)

nodes=list(walk(model))
def find_fractional_udim_offsets(value,path='root',bad=None):
    if bad is None: bad=[]
    if isinstance(value,dict):
        if 'UDim' in value:
            arr=value['UDim']
            if isinstance(arr,list) and len(arr)==2 and not float(arr[1]).is_integer():
                bad.append((path+'.UDim',arr))
        if 'UDim2' in value:
            arr=value['UDim2']
            if isinstance(arr,list) and len(arr)==2:
                for i,component in enumerate(arr):
                    if isinstance(component,list) and len(component)==2 and not float(component[1]).is_integer():
                        bad.append((f'{path}.UDim2[{i}]',component))
        for key,item in value.items(): find_fractional_udim_offsets(item,f'{path}.{key}',bad)
    elif isinstance(value,list):
        for i,item in enumerate(value): find_fractional_udim_offsets(item,f'{path}[{i}]',bad)
    return bad

fractional_udim_offsets=find_fractional_udim_offsets(model)
by_name={}
for p,n in nodes: by_name.setdefault(n.get('Name'),[]).append((p,n))
def one(name):
    xs=by_name.get(name,[])
    return xs[0] if xs else (None,None)
def size(name):
    n=one(name)[1]
    return n and n.get('Properties',{}).get('Size',{}).get('UDim2')
def pos(name):
    n=one(name)[1]
    return n and n.get('Properties',{}).get('Position',{}).get('UDim2')

safe_path,_=one('SafeRoot')
roulette_path,roulette=one('VerticalRoulette')
button_path,_=one('RollButton')
rollhud_path,_=one('RollHUD')
panel=one('MainPanel')[1]
templates=one('Templates')[1]

check('Rojo-safe integer UDim offsets',not fractional_udim_offsets,str(fractional_udim_offsets[:4]))
check('StarterGui mapped to src/StarterGui',project['tree']['StarterGui'].get('$path')=='src/StarterGui')
check('BloomUI declarative ScreenGui',model.get('ClassName')=='ScreenGui' and model.get('Name')=='BloomUI')
check('ScreenGui uses Sibling ZIndex',model.get('Properties',{}).get('ZIndexBehavior')=='Sibling')
check('roulette direct child of SafeRoot',roulette_path==safe_path+'/VerticalRoulette',roulette_path or '')
check('roll direct child of SafeRoot',button_path==safe_path+'/RollButton',button_path or '')
check('meter direct child of SafeRoot',rollhud_path==safe_path+'/RollHUD',rollhud_path or '')

for name in ['ObjectiveCard','CurrencyHUD','MenuDock','RollHUD','VerticalRoulette','RollButton','MainPanel','Toast','RewardReveal']:
    n=one(name)[1]
    check(name+' authored hidden before data',n is not None and n.get('Properties',{}).get('Visible') is False)

check('objective compact',size('ObjectiveCard')==[[0,430],[0,62]])
check('currency compact',size('CurrencyHUD')==[[0,190],[0,205]])
check('dock compact',size('MenuDock')==[[0,44],[0,294]])
check('roulette top centered',pos('VerticalRoulette')==[[0.5,0],[0,82]] and roulette.get('Properties',{}).get('AnchorPoint',{}).get('Vector2')==[0.5,0])
check('roulette compact viewport',size('VerticalRoulette')==[[0,220],[0,122]] and roulette.get('Properties',{}).get('ClipsDescendants') is True)
check('main panel authored base size',panel is not None and size('MainPanel')==[[0,600],[0,420]])
check('roll button compact',size('RollButton')==[[0,150],[0,42]])
check('toast moved off center HUD',pos('Toast')==[[1,-12],[0,12]])

for role in ['Next','Current','Previous']:
    _,n=one(role)
    check('roulette '+role,n is not None)
    if n: check(role+' transparent',n.get('Properties',{}).get('BackgroundTransparency')==1)
check('no authored Buffer',one('Buffer')[1] is None and one('_RuntimeBuffer')[1] is None)
check('runtime buffer cloned locally','function UI:EnsureRouletteRuntimeBuffer' in source and 'source:Clone()' in source and '_RuntimeBuffer' in source)
check('42px roulette step','StepPixels=42' in audio and 'Position=UDim2.fromOffset(0,RollAudio.StepPixels)' in source)
marker=one('CurrentMarker')[1]
check('current slot clearly marked',marker is not None and {'LeftPointer','RightPointer','CurrentLabel'}.issubset({c.get('Name') for c in marker.get('Children',[])}))

check('Templates folder authored',templates is not None)
for name in ['ButtonTemplate','LabelTemplate','SectionTemplate']:
    n=one(name)[1]
    check(name+' authored',n is not None and n.get('Properties',{}).get('Visible') is False)
check('menu helpers clone authored templates','self.Templates and self.Templates:FindFirstChild("ButtonTemplate")' in source and 'LabelTemplate' in source and 'SectionTemplate' in source)
inventory_prototype=one('InventoryPrototype')[1]
item_card=one('ItemCardTemplate')[1]
check('InventoryPrototype authored',inventory_prototype is not None and inventory_prototype.get('Properties',{}).get('Visible') is False)
check('Inventory v2 item card authored',item_card is not None and item_card.get('Properties',{}).get('Visible') is False)
check('legacy SeedSatchelTemplate absent',one('SeedSatchelTemplate')[1] is None)
check('legacy InventoryTileTemplate absent',one('InventoryTileTemplate')[1] is None)

# BR-002: feature id and renderer are explicit and editor has one live inventory preview.
check('SeedSatchel explicitly routes to InventoryV2','MENU_RENDERERS={SeedSatchel="InventoryV2"}' in source)
check('Inventory v2 backend linked','InventoryV2Controller' in source and 'InventoryV2.Render(self,p,ui)' in source)
check('Inventory v2 rerender follows renderer','controller.MenuRenderer=="InventoryV2"' in inventory_v2_source)
check('Inventory v2 binds authoritative inventory','uiState.Inventory' in inventory_v2_source and 'controller:Send("Dissolve"' in inventory_v2_source and 'controller:Send("EquipBee"' in inventory_v2_source)
check('editor removed separate seedbag scene','value="seedbag"' not in editor_html and 'data-ui-state="seedbag"' not in editor_html)
check('editor migrates stale seedbag preference','p.previewScene==="seedbag"' in editor_source and 'state.previewScene="inventory_v2"' in editor_source)

# Duplicate-HUD guard.
check('live-sync resolver exists','function UI:ResolveBloomGui()' in source)
check('authoritative HUD guard exists','function UI:GuardBloomGui()' in source and 'BloomAuthoritative' in source)
check('late duplicate watcher exists','playerGui.ChildAdded:Connect' in source and 'Destroying late duplicate HUD' in source)
check('guard starts before static binding','self:GuardBloomGui()' in source and source.index('self:GuardBloomGui()')<source.index('self:BindStaticUI()'))

# BR-005: revision-aware state delivery and client duplicate protection.
check('state revision exists','StateRevisions={}' in player_source and 'function X:MarkStateDirty' in player_source)
check('state push is revision gated','LastPushedStateRevision' in player_source and 'if not force and self.LastPushedStateRevision[player]==revision then return false end' in player_source)
check('StateRequest supports known revision','function(player,knownRevision)' in remote_source and '"NOT_MODIFIED"' in remote_source)
check('client sends known revision','InvokeServer(self.State and self.State.Revision or nil)' in source)
check('client ignores duplicate revision','self.State.Revision==payload.Revision' in source)

# BR-007: Workshop is mounted once per open session.
check('Workshop runtime cached','self.WorkshopRuntime' in source and 'firstWorkshopBuild' in source)
check('Workshop node handlers bind once','BloomWorkshopBound' in source)
check('Workshop pan binds only on first build','if firstWorkshopBuild then' in source and 'self:BindWorkshopPan(canvas,nodes)' in source)

# BR-008: request/session correlation and stale landing cleanup guard.
check('roll request sequence exists','RollRequestSequence' in source and 'RollRequestSessions' in source)
check('roll request id sent to server','self:Send("Roll",automatic==true,requestId)' in source)
check('server reward echoes request id','RequestId=requestId' in roll_source)
check('remote ack echoes request id','RequestId=rollRequestId' in remote_source)
check('landing settle is generation guarded','self:StepRoulette(duration,final and target or nil,generation)' in source)
check('stale landing cannot clear new session','if generation~=self.RouletteGeneration then return end\n  self.RouletteLanding=false' in source)

check('first state reveals HUD','local firstState=self.State==nil' in source and 'self.ObjectiveCard.Visible=true' in source and 'self.CurrencyHUD.Visible=true' in source)
check('state request handshake retained','self.StateRequest=remotes:WaitForChild("StateRequest")' in source and 'InvokeServer(self.State and self.State.Revision or nil)' in source)
check('localized dock tooltips','tip.Text=MENU_NAMES[name] or name' in source)
check('dynamic header icon','self.PanelHeaderIcon' in source and 'Icons.Get("Menus",name)' in source)
check('soft roulette audio','SpinVolume=.04' in audio and 'RewardVolume=.16' in audio)
check('roll is toggle','self:SetAutoRolling(not self.Auto)' in source)

out=[]
for name,ok,detail in checks:
    out.append(('PASS' if ok else 'FAIL')+' '+name+((' — '+detail) if detail else ''))
out.append(f'TOTAL {sum(x[1] for x in checks)}/{len(checks)} PASS')
text='\n'.join(out)+'\n'
(ROOT/'tests/ui_startergui_audit.txt').write_text(text,encoding='utf-8')
print(text,end='')
if not all(x[1] for x in checks): sys.exit(1)
