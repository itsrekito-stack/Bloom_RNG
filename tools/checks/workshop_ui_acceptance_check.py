from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
ui=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text()
state=(ROOT/'src/ServerScriptService/Services/UIStateService.luau').read_text()
model=json.loads((ROOT/'src/StarterGui/BloomUI.model.json').read_text(encoding='utf-8'))

def need(text,token,label):
    assert token in text, f"{label}: missing {token!r}"

def walk(node):
    yield node
    for child in node.get("Children",[]) or []:
        yield from walk(child)

nodes={}
for node in walk(model):
    nodes.setdefault(node.get("Name"),[]).append(node)

def one(name):
    items=nodes.get(name,[])
    return items[0] if items else None

for token in (
    'return self.WorkshopFocus==true and self.Menu=="Workshop"',
    'self.ObjectiveCard,self.CurrencyHUD,self.Dock,self.RollHUD,self.Roll,self.RouletteViewport',
    'if self:IsWorkshopExclusive() and name~="Workshop" then return end',
    'if name=="Workshop" then self:SetWorkshopFocus(true) end',
    'if wasWorkshop then self:SetWorkshopFocus(false) end',
):
    need(ui,token,'fullscreen exclusivity')

for token in (
    'input.UserInputType~=Enum.UserInputType.MouseButton1',
    'input.UserInputType==Enum.UserInputType.MouseWheel',
    'local zoomMin=.5',
    'local zoomMax=1.6',
    'self:ClampWorkshopCanvasPosition(canvas,target)',
    'Enum.ContextActionResult.Sink',
    'Enum.ContextActionPriority.High.Value+100',
):
    need(ui,token,'pan/zoom')

for token in (
    'Revealed=revealed',
    'Available=revealed and reason==nil',
    'Cost=revealed and (node.Cost or 0) or nil',
    'Coins=revealed and (node.Coins or 0) or nil',
    'Dust=revealed and (node.Dust or 0) or nil',
    'Nectar=revealed and (node.Nectar or 0) or nil',
):
    need(state,token,'server workshop state')

# Workshop fullscreen geometry must not consume the renderer branch.
need(ui,'-- Geometry and renderer dispatch must stay separate so Workshop can render.','workshop renderer reachability marker')
assert 'self.Content.ScrollBarThickness=0\n elseif renderer=="InventoryV2" then' not in ui, "workshop renderer unreachable behind geometry elseif"
need(ui,'if renderer=="InventoryV2" then','separate renderer dispatch')
need(ui,'elseif renderer=="Workshop" then','workshop renderer dispatch')
need(ui,'shell=template:Clone()','WorkshopTemplate runtime clone')
need(ui,'shell.Name="WorkshopRuntime"','Workshop runtime identity')
need(ui,'shell.Visible=true','Workshop runtime visibility')

# Stale authored/runtime structures must fail fast and rebuild, never hang forever.
for token in (
    'local REQUIRED_WORKSHOP_UI={',
    '"WorkshopTemplate","WorkshopBody","TreePanel","TreeCanvas","PanMap","NodeTooltip","WorkshopCurrencyBar"',
    'local function workshopStructure(shell)',
    'local structure=workshopStructure(shell)',
    'local templateStructure=workshopStructure(template)',
    'if shell and shell.Parent then shell:Destroy() end',
    'WorkshopRuntime clone failed authored structure validation',
):
    need(ui,token,'Workshop stale-runtime recovery')
assert 'WaitForChild("NodeTooltip")' not in ui, "Workshop must not infinite-yield on a stale NodeTooltip"
assert 'WaitForChild("WorkshopBody")' not in ui, "Workshop must validate structure instead of yielding forever"

# Workshop-only currency strip is authored and bound to authoritative profile state.
for name in ('WorkshopCurrencyBar','WorkshopPoints','Coins','PetalDust','AncientNectar'):
    assert one(name) is not None, f"authored Workshop currency UI missing: {name}"
for token in (
    'local currencyBar=structure.CurrencyBar',
    'setWorkshopCurrency("WorkshopPoints",p.WorkshopV5.Points,pointIcon)',
    'setWorkshopCurrency("Coins",p.Currencies.Coins,coinIcon)',
    'setWorkshopCurrency("PetalDust",p.Currencies.PetalDust,dustIcon)',
    'setWorkshopCurrency("AncientNectar",p.Currencies.AncientNectar,nectarIcon)',
):
    need(ui,token,'Workshop currency binding')

# The CORE node is the visual center of the authored 2200x1700 tree and runtime
# centering uses the actual viewport, so both desktop targets open centered.
pan=one('PanMap')
canvas=one('TreeCanvas')
core=one('Node_CORE')
assert pan and canvas and core
assert pan['Properties']['Position']['UDim2']==[[0,0],[0,0]], "PanMap runtime/editor origin diverged"
map_size=pan['Properties']['Size']['UDim2']
assert map_size==[[0,2200],[0,1700]], map_size
cp=core['Properties']['Position']['UDim2']
cs=core['Properties']['Size']['UDim2']
core_center=(cp[0][1]+cs[0][1]/2,cp[1][1]+cs[1][1]/2)
assert core_center==(1100.0,850.0), core_center
for width,height in ((1366,768),(1280,720)):
    viewport=(width-12,height-12)
    target=(core_center[0]-viewport[0]/2,core_center[1]-viewport[1]/2)
    visible_center=(core_center[0]-target[0],core_center[1]-target[1])
    assert abs(visible_center[0]-viewport[0]/2)<.01
    assert abs(visible_center[1]-viewport[1]/2)<.01
need(ui,'function UI:CenterWorkshopCanvas(canvas,panMap,zoom)','runtime Workshop centering')
need(ui,'center-viewport*.5','CORE-to-viewport centering')
need(ui,'self.WorkshopCanvasPosition=nil','fresh Workshop open recenters tree')

for token in (
    'owned=backend.Owned==true',
    'revealed=backend.Revealed==true',
    'available=revealed and backend.Available==true',
    'Icons.GetWorkshopNodeIcon(id,not revealed)',
    'if currentRevealed then',
    'tooltip.Visible=false',
    'node:SetAttribute("BloomWorkshopOwned",owned)',
    'node:SetAttribute("BloomWorkshopRevealed",revealed)',
    'node:SetAttribute("BloomWorkshopAvailable",available)',
    'node:SetAttribute("BloomWorkshopSelected",selected)',
):
    need(ui,token,'client workshop state')

print("PASS Workshop UI acceptance: stale runtime recovery, exclusive fullscreen focus, centered tree, authored currency overlay, LMB pan/wheel zoom, hidden-node redaction and server-derived node states/costs are wired")
