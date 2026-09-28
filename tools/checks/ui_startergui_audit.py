from pathlib import Path
import json,sys

ROOT=Path(__file__).resolve().parents[2]
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))
project=json.loads((ROOT/'default.project.json').read_text(encoding='utf-8'))
source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text(encoding='utf-8')
inventory_v2_source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau').read_text(encoding='utf-8')
quests_v2_source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/QuestsController.luau').read_text(encoding='utf-8')
boost_hud_source=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BoostHUDController.luau').read_text(encoding='utf-8')
boost_service_source=(ROOT/'src/ServerScriptService/Services/BoostService.luau').read_text(encoding='utf-8')
ui_state_source=(ROOT/'src/ServerScriptService/Services/UIStateService.luau').read_text(encoding='utf-8')
player_source=(ROOT/'src/ServerScriptService/Services/PlayerService.luau').read_text(encoding='utf-8')
remote_source=(ROOT/'src/ServerScriptService/Services/RemoteService.luau').read_text(encoding='utf-8')
roll_source=(ROOT/'src/ServerScriptService/Services/RollService.luau').read_text(encoding='utf-8')
editor_source=(ROOT/'tools/bloom-ui-editor/app.js').read_text(encoding='utf-8')
editor_html=(ROOT/'tools/bloom-ui-editor/index.html').read_text(encoding='utf-8')
editor_css=(ROOT/'tools/bloom-ui-editor/app.css').read_text(encoding='utf-8')
roflow_ui_sync=(ROOT/'tools/roflow/scripts/sync-ui-studio.mjs').read_text(encoding='utf-8')
roflow_web=(ROOT/'tools/roflow/web/app.js').read_text(encoding='utf-8')
roflow_rust=(ROOT/'tools/roflow/src-tauri/src/lib.rs').read_text(encoding='utf-8')
audio=(ROOT/'src/ReplicatedStorage/Config/RollAudioConfig.luau').read_text(encoding='utf-8')
bloom_config=(ROOT/'src/ReplicatedStorage/Config/BloomConfig.luau').read_text(encoding='utf-8')
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
roulette_clip=one('RouletteClip')[1]
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

# Pixel geometry and authored Visible values are designer-owned in Bloom UI Studio.
# Keep CI focused on structural validity so intentional UI moves do not become false failures.
def valid_udim2(name):
    value=size(name)
    return isinstance(value,list) and len(value)==2 and all(isinstance(part,list) and len(part)==2 for part in value)

for name in ['ObjectiveCard','CurrencyHUD','MenuDock','RollHUD','VerticalRoulette','RollButton','MainPanel','Toast','RewardReveal','ActiveBoostsHUD','ActiveBoostTooltip']:
    check(name+' authored',one(name)[1] is not None)
    check(name+' valid size',valid_udim2(name))

check('roulette content is clipped',
      (roulette is not None and roulette.get('Properties',{}).get('ClipsDescendants') is True)
      or (roulette_clip is not None and roulette_clip.get('Properties',{}).get('ClipsDescendants') is True))
check('main panel authored',panel is not None)

for role in ['Next','Current','Previous']:
    _,n=one(role)
    check('roulette '+role,n is not None)
    if n: check(role+' valid size',valid_udim2(role))
check('no authored Buffer',one('Buffer')[1] is None and one('_RuntimeBuffer')[1] is None)
check('runtime buffer cloned locally','function UI:EnsureRouletteRuntimeBuffer' in source and 'source:Clone()' in source and '_RuntimeBuffer' in source)
check('legacy reel matcher uses token boundaries','function hasLegacyReelToken(lower)' in source and 'string.find(lower,"reel",1,true)' not in source)
check('inventory FreeLabel survives roulette cleanup','FreeLabel' in json.dumps(model) and 'or hasLegacyReelToken(lower)' in source)
check('42px roulette step','StepPixels=42' in audio and 'Position=UDim2.fromOffset(0,RollAudio.StepPixels)' in source)
marker=one('CurrentMarker')[1]
check('current slot clearly marked',marker is not None and {'LeftPointer','RightPointer','CurrentLabel'}.issubset({c.get('Name') for c in marker.get('Children',[])}))

check('Templates folder authored',templates is not None)
for name in ['ButtonTemplate','LabelTemplate','SectionTemplate']:
    n=one(name)[1]
    check(name+' authored',n is not None and n.get('Properties',{}).get('Visible') is False)
check('menu helpers clone authored templates','function UI:MenuTemplate(name)' in source and 'self:MenuTemplate("ButtonTemplate")' in source and 'self:MenuTemplate("LabelTemplate")' in source and 'self:MenuTemplate("SectionTemplate")' in source)
inventory_prototype=one('InventoryPrototype')[1]
item_card=one('ItemCardTemplate')[1]
check('InventoryPrototype authored',inventory_prototype is not None and inventory_prototype.get('Properties',{}).get('Visible') is False)
check('Inventory v2 item card authored',item_card is not None and item_card.get('Properties',{}).get('Visible') is False)
check('legacy SeedSatchelTemplate absent',one('SeedSatchelTemplate')[1] is None)
check('obsolete Seeds inventory category absent',one('Category_Seeds')[1] is None)
check('legacy InventoryTileTemplate absent',one('InventoryTileTemplate')[1] is None)

boost_root_path,boost_root=one('ActiveBoostsHUD')
boost_tooltip_path,boost_tooltip=one('ActiveBoostTooltip')
boost_template=one('BoostTemplate')[1]
boost_minimize=one('MinimizeButton')[1]
check('Trait HUD authored',one('TraitHUD')[1] is not None and one('TraitTemplate')[1] is not None and one('TraitTooltip')[1] is not None and one('TraitTierPopup')[1] is not None)
check('Active boosts direct child of SafeRoot',boost_root_path==safe_path+'/ActiveBoostsHUD',boost_root_path or '')
check('Active boost tooltip direct child of SafeRoot',boost_tooltip_path==safe_path+'/ActiveBoostTooltip',boost_tooltip_path or '')
check('Active boost template authored hidden',boost_template is not None and boost_template.get('ClassName')=='ImageButton' and boost_template.get('Properties',{}).get('Visible') is False)
check('Active boosts minimize button authored',boost_minimize is not None and boost_minimize.get('ClassName')=='TextButton' and boost_minimize.get('Properties',{}).get('Visible') is True)
check('Active boosts bottom-left authored anchor',boost_root is not None and boost_root.get('Properties',{}).get('AnchorPoint',{}).get('Vector2')==[0,1])
check('Active boosts clips runtime badges to panel',boost_root is not None and boost_root.get('Properties',{}).get('ClipsDescendants') is True)
check('Active boosts controller linked','self.BoostHUD=require(script.Parent.BoostHUDController)' in source and 'self.BoostHUD:Update(boosts,self.State.Revision)' in source)
check('Active boost hover states','badge.MouseEnter:Connect' in boost_hud_source and 'badge.MouseLeave:Connect' in boost_hud_source and 'TweenService:Create(scale' in boost_hud_source)
check('Active boosts minimize behavior','function S:SetMinimized(minimized,animate)' in boost_hud_source and 'self.Toggle.Activated:Connect' in boost_hud_source and 'self.List.Visible=not self.Minimized' in boost_hud_source)
check('Active boosts static Luck first',one('LuckBadge')[1] is not None and one('LuckBadge')[1].get('Properties',{}).get('LayoutOrder')==0 and 'self.LuckBadge=self.List and self.List:FindFirstChild("LuckBadge")' in boost_hud_source)
check('Active boosts horizontal controls',one('ScrollLeft')[1] is not None and one('ScrollRight')[1] is not None and 'CanvasPosition=Vector2.new(x,0)' in boost_hud_source)
check('Active boost source breakdown','self.TooltipBreakdown.Text=self:TooltipText(item)' in boost_hud_source and 'source(buckets,stat,"Bees",bee.DisplayName.." ×"..count' in boost_service_source and 'source(buckets,"Luck","Activity",tostring(solarCfg.Label or "Solar Bloom")' in boost_service_source)
check('Workshop hides active boosts','self.BoostHUD:SetSuppressed(exclusive)' in source and 'function S:SetSuppressed(suppressed)' in boost_hud_source)
check('Workshop visibility snapshot restore','function UI:CaptureWorkshopHUDVisibility()' in source and 'function UI:RestoreWorkshopHUDVisibility()' in source and 'self:RestoreWorkshopHUDVisibility()' in source)
check('BloomUI validates authored schema before choosing runtime clone','local REQUIRED_AUTHORED_UI={' in source and 'validateBloomGui(candidate)' in source and 'Rejecting stale PlayerGui/BloomUI' in source)
check('stale runtime BloomUI replaced from current StarterGui','Replacing stale runtime HUD from current StarterGui template' in source and 'template:Clone()' in source)
check('stale retired-menu HUD rejected','RETIRED_MENU_GUI={"Dock_FieldGuide","Dock_Map","FieldGuideKit","MapKit"}' in source and 'root:FindFirstChild(name,true)' in source)
check('boost HUD never infinite-waits authored roots','WaitForChild("ActiveBoostsHUD")' not in boost_hud_source and 'WaitForChild("ActiveBoostTooltip")' not in boost_hud_source)
check('boost HUD missing hierarchy fails fast','[BoostHUD] Authored boost HUD is missing from canonical BloomUI' in boost_hud_source and '[BoostHUD] Authored boost HUD hierarchy is incomplete' in boost_hud_source)

# BR-002: feature id and renderer are explicit and editor has one live inventory preview.
check('authored v2 menu routes','SeedSatchel="InventoryV2"' in source and 'Garden="GardenV1"' in source and 'Index="IndexV1"' in source and 'Trials="QuestsV2"' in source and 'Settings="SettingsV2"' in source)
check('Inventory v2 backend linked','InventoryV2Controller' in source and 'InventoryV2.Render(self,p,ui)' in source)
check('Index backend linked','IndexController' in source and 'IndexV1.Render(self,p,ui)' in source and one('IndexPrototype')[1] is not None and one('IndexCardTemplate')[1] is not None)
check('authored dock exposes Index access',one('Dock_Index')[1] is not None and 'for _,name in ipairs({"SeedSatchel","Garden","Index","Workshop","Trials","Settings"}) do' in source)
check('Quests v2 backend linked','QuestsController' in source and 'QuestsV2.Render(self,p,ui)' in source and one('QuestsPrototype')[1] is not None and one('QuestCardTemplate')[1] is not None)
check('legacy TrialsKit removed',one('TrialsKit')[1] is None)
check('dynamic menus use authored state kits','self.StateKits=self.Panel:FindFirstChild("StateKits")' in source and 'function UI:MenuTemplate(name)' in source and 'self:MenuTemplate("ButtonTemplate")' in source)
check('state kits are authored in ScreenGui',one('StateKits')[1] is not None and all(one(name+'Kit')[1] is not None for name in ['Garden','Settings','Season','Replay','Cards']))
check('retired alpha menus removed',all(one(name)[1] is None for name in ['PlantKit','FieldGuideKit','MapKit','Dock_FieldGuide','Dock_Map']))
check('world UI prototypes authored in ScreenGui',one('WorldUIPrototypes')[1] is not None and one('TutorialWorldLabelTemplate')[1] is not None and one('ActivityCheckpointLabelTemplate')[1] is not None)
check('UI Studio empty desk hides Explorer tree','if(!state.activeUiState){' in editor_source and 'No UI State open' in editor_source)
check('UI Studio Explorer is scoped to active state','function activeStateTreeIds()' in editor_source and 'const stateIds=activeStateTreeIds();' in editor_source and 'if(!stateIds.has(n.__id))return;' in editor_source)
check('UI Studio desktop panels are resizable','explorerResizer' in editor_html and 'inspectorResizer' in editor_html and 'state.panelResize={side}' in editor_source and 'applyPanelWidths()' in editor_source and '.panel-resizer' in editor_css)
check('UI Studio state rail uses Bloom icons','data-asset-id=' in editor_html and '.ui-state-btn b img' in editor_css and 'hydrateStudioIcons()' in editor_source)
check('RoFlow native UI Studio injection is version agnostic','appScript=/<script src=' in roflow_ui_sync and '__ROFLOW_EMBEDDED__=true' in roflow_ui_sync and 'app.js?v=8' not in roflow_ui_sync)
check('UI Studio thumbnails use native bridge','roflow-asset:' in editor_source and 'nativeThumbnail(assetId)' in editor_source and 'roblox_thumbnail_url' in editor_source)
check('RoFlow serves UI Studio live from project','fn ui_studio_document(state: State<AppState>)' in roflow_rust and 'tools").join("bloom-ui-editor' in roflow_rust and 'ui_studio_document,' in roflow_rust)
check('RoFlow reloads live UI Studio after AI Sync','const documentHtml=await invoke("ui_studio_document")' in roflow_web and 'frame.srcdoc=documentHtml' in roflow_web and 'if(state.currentPage==="ui")await ensureUiStudio(true)' in roflow_web and 'unloadUiStudio("AI Sync while inactive")' in roflow_web)
check('RoFlow keeps bundled UI Studio as fallback','frame.src="./ui-studio/index.html?ts="+Date.now()' in roflow_web and 'Bundled UI Studio fallback loaded' in roflow_web)
check('Inventory v2 rerender follows renderer','controller.MenuRenderer=="InventoryV2"' in inventory_v2_source)
check('Inventory v2 binds authoritative species inventory','uiState.Inventory' in inventory_v2_source and 'item.Obtained or 1' in inventory_v2_source and 'controller:Send("EquipBee"' in inventory_v2_source)
check('Inventory Bee Trait filter authored',one('TraitFilterPanel')[1] is not None and one('TraitChipTemplate')[1] is not None and 'availableTraits(all.Bees)' in inventory_v2_source)
check('Inventory Bee summary is compact authored UI',one('BeeSummary')[1] is not None and one('PassiveRowTemplate')[1] is not None and one('AbilityDescription')[1] is not None and 'description.Visible=not isBee' in inventory_v2_source and 'stats.Visible=not isBee' in inventory_v2_source)
check('Inventory equipped Bee states are authored',one('EquippedBadge')[1] is not None and one('UnequipAllButton')[1] is not None and 'controller:Send("UnequipAllBees")' in inventory_v2_source)
check('Inventory card hover scale authored',one('InventoryHoverScale')[1] is not None and 'TweenService:Create(hoverScale' in inventory_v2_source)
check('Garden used Flower state authored',one('UsedBadge')[1] is not None)
check('Garden final ghost slot authored',one('GhostBadge')[1] is not None and one('Slot7')[1] is not None)
check('Garden menu owns authored Garden editor','function UI:OpenGardenMenu(slot)' in source and 'self:Open("Garden",{Slot=slot})' in source and 'GardenEditor.Render(self,p,ui)' in source and one('GardenKit')[1] is not None)
check('Inventory v2 keeps Flower planting out of Inventory','CATEGORY_ORDER={"Bees","Resources","Special"}' in inventory_v2_source and '"PLANT IN GARDEN"' not in inventory_v2_source and '"EDIT / REMOVE IN GARDEN"' not in inventory_v2_source and 'controller:Send("GardenEdit"' not in inventory_v2_source)
check('standalone Plant menu removed','elseif name=="Plant" then' not in source and one('PlantKit')[1] is None)
check('BR-010 map exposes physical gate actionability','NearGate=nearGate' in ui_state_source and 'PrerequisiteReady=prerequisiteReady' in ui_state_source and 'CanUnlock=not unlocked and prerequisiteReady and hiveReady and nearGate' in ui_state_source and 'UnlockHint=hint' in ui_state_source)
check('BR-010 map tells Hive-ready players to use gate','Hive ready — go to the ' in ui_state_source and 'Use the world gate prompt to unlock' in ui_state_source)
check('Trials are menu-started without world shrine dependency','NearShrine=true' in ui_state_source and 'StartHint=startHint' in ui_state_source and 'Ready to start from Quests' in ui_state_source and 'Garden Trials shrine' not in ui_state_source)
check('Quests client renders server-derived trial guidance','trial.StartHint' in quests_v2_source and 'controller:Send("Trial",trial.Id)' in quests_v2_source)
check('UI Studio uses desktop state rail','class="state-rail"' in editor_html and 'class="app-titlebar"' in editor_html and 'class="app-workspace"' in editor_html)
check('UI Studio exposes all authored state buttons',all(('data-ui-state="'+state+'"') in editor_html for state in ['gameplay','inventory_v2','index','traits','garden','workshop','trials','settings','season','replay','cards','reward','toast','tutorial','boosts','world_ui','loading']))
check('UI Studio hides retired alpha menus','data-ui-state="fieldguide"' not in editor_html and 'data-ui-state="map"' not in editor_html and 'data-ui-state="plant"' not in editor_html)
check('UI STATE toggles active state back to empty workspace','const closing=state.activeUiState===scene' in editor_source and 'state.activeUiState=null' in editor_source and 'Empty workspace' in editor_source)
check('UI Studio removed HTML runtime mock injection','MOCK PREVIEW · NOT RUNTIME' not in editor_source and '<div class="preview-menu-generic">' not in editor_source and 'function injectRuntimePreview(){/* UI STATE shows authored Roblox instances only.' in editor_source)
check('UI Studio switches authored loading ScreenGui model','LOADING_TARGET="src/ReplicatedFirst/BloomLoadingTemplate.model.json"' in editor_source and 'switchUiModel(LOADING_TARGET,"loading")' in editor_source)
check('editor removed separate seedbag scene','value="seedbag"' not in editor_html and 'data-ui-state="seedbag"' not in editor_html)

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

# BR-006: public replication is filtered before network delivery.
check('public replication has bounded cadence','PublicSyncSeconds=1' in bloom_config)
check('public replication has spatial radius','PublicReplicationRadius=180' in bloom_config)
check('server filters other bees by setting','profile.Settings.ShowOtherPollinators' in player_source)
check('server filters other tokens by setting','profile.Settings.HideOtherPlayersTokens' in player_source)
check('server filters public data spatially','Magnitude<=radius' in player_source)
check('public bees no longer globally broadcast','self:Broadcast("Bees",frames)' not in player_source)
check('public tokens no longer globally broadcast','self:Broadcast("OtherTokens",tokenFrames)' not in player_source)

# BR-008: request/session correlation and stale landing cleanup guard.
check('roll request sequence exists','RollRequestSequence' in source and 'RollRequestSessions' in source)
check('roll request id sent to server','self:Send("Roll",automatic==true,requestId)' in source)
check('server reward echoes request id','RequestId=requestId' in roll_source)
check('remote ack echoes request id','RequestId=rollRequestId' in remote_source)
check('landing settle is generation guarded','self:PrepareRouletteLandingTarget(target,#steps)' in source and 'if generation and generation~=self.RouletteGeneration then return false end' in source)
check('stale landing cannot clear new session','if generation~=self.RouletteGeneration then return end\n  self.RouletteLanding=false' in source)

check('first state reveals HUD','local firstState=self.State==nil' in source and 'self.ObjectiveCard.Visible=true' in source and 'self.CurrencyHUD.Visible=true' in source)
check('state request handshake retained','self.StateRequest=remotes:WaitForChild("StateRequest")' in source and 'InvokeServer(self.State and self.State.Revision or nil)' in source)
check('localized dock tooltips','tip.Text=MENU_NAMES[name] or name' in source)
check('core HUD dock stays compact until a menu opens','local visible=name=="SeedSatchel" or menuDockOpen' in source and 'b.Visible=inventoryUnlocked and visible' in source)
check('secondary menu access lives in authored expandable dock',all(one('Dock_'+name)[1] is not None for name in ['Garden','Index','Workshop','Trials','Settings']) and 'local menuDockOpen=MENU_DOCK_CONTEXT[self.Menu]==true' in source and 'self:Open(name)' in source)
check('hover state survives state renders','local PERSISTENT_HOVERS=setmetatable({}, {__mode="k"})' in source and 'refreshPersistentHovers()' in source and 'BloomDockHovered' in source)
check('Index and Workshop use shared authored bottom navigation',one('MenuNav')[1] is None and all(one('Dock_'+name)[1] is not None for name in ['SeedSatchel','Garden','Index','Workshop','Trials','Settings']) and 'function UI:BindMenuNavigation(root)' not in source)
check('Workshop explains progression currencies',one('CurrencyHelp')[1] is not None and 'ANCIENT NECTAR' in json.dumps(model) and 'PETAL DUST' in json.dumps(model))
check('OpenMenuKey toggles Inventory directly','if self.Menu=="SeedSatchel" then' in source and 'self:Open("SeedSatchel")' in source)
check('dynamic header icon','self.PanelHeaderIcon' in source and 'Icons.Get("Menus",name)' in source)
check('soft roulette audio','SpinVolume=.04' in audio and 'RewardVolume=.16' in audio)
check('roulette continues beneath menus','local controlsVisible=rollUnlocked and self.Menu==nil' in source and 'self.RouletteViewport.Visible=rollUnlocked and' in source)
check('roulette smooth target preparation','function UI:PrepareRouletteLandingTarget(targetIndex,stepCount)' in source and 'self.RouletteCursor=((targetIndex-2)%#pool)+1' not in source)
check('roll is toggle','self:SetAutoRolling(not self.Auto)' in source)

out=[]
for name,ok,detail in checks:
    out.append(('PASS' if ok else 'FAIL')+' '+name+((' — '+detail) if detail else ''))
out.append(f'TOTAL {sum(x[1] for x in checks)}/{len(checks)} PASS')
text='\n'.join(out)+'\n'
(ROOT/'tests/ui_startergui_audit.txt').write_text(text,encoding='utf-8')
print(text,end='')
if not all(x[1] for x in checks): sys.exit(1)
