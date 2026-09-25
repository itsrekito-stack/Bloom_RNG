from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
ui=(ROOT/'src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau').read_text()
state=(ROOT/'src/ServerScriptService/Services/UIStateService.luau').read_text()

def need(text,token,label):
    assert token in text, f"{label}: missing {token!r}"

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

print("PASS Workshop UI acceptance: exclusive fullscreen focus, LMB pan/wheel zoom, hidden-node redaction and server-derived node states/costs are wired")
