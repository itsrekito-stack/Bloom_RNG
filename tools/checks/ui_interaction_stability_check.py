#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
boost=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BoostHUDController.luau")

# State sync must not destroy/recreate an open menu every revision.
assert 'if self.Menu and not self.WorkshopPanDragging then self:RenderMenu() end' not in ui,     "background state sync still rebuilds open menus"
need(ui,'and self.MenuRefreshRequested then',"open menu only refreshes when relevant action requested it")
need(ui,'local refreshMenu=MENU_REFRESH_ACTIONS[payload.Action]',"successful actions mark only their relevant menu dirty")
need(ui,'Setting="Settings"',"Settings refresh action mapping")
need(ui,'DissolveFilter="Settings"',"Settings filter refresh action mapping")
need(ui,'WorkshopBuy="Workshop"',"Workshop refresh action mapping")
need(ui,'EquipBee="SeedSatchel"',"Inventory refresh action mapping")

# Intentional menu refreshes preserve user interaction position.
need(ui,'function UI:CapturePanelInteractionState()',"generic panel interaction capture")
need(ui,'state.Scroll[key]=instance.CanvasPosition',"scroll position capture")
need(ui,'function UI:RestorePanelInteractionState(state)',"generic panel interaction restore")
need(ui,'frame.CanvasPosition=position',"scroll position restore")
need(ui,'function UI:RenderMenu(preserveInteraction)',"render supports stable refresh")
need(ui,'if not workshop and not preserveInteraction then self.Content.CanvasPosition=Vector2.new() end',
     "scroll reset limited to fresh menu opens")
need(ui,'self:RenderMenu(true)',"state-driven relevant refresh preserves interaction state")

# Hoverable Active Boost badges survive unrelated state revisions.
need(boost,'local function payloadSignature(payload)',"boost payload structural signature")
need(boost,'if item.Remaining==nil then table.insert(parts,tostring(item.ValueText or "")) end',
     "timed countdown changes do not force badge rebuild")
need(boost,'if signature==self.LastSignature then',"unrelated revisions do not clear boost badges")
need(boost,'self.LastRevision=revision',"revision still tracked without rebuild")
need(boost,'badge.MouseEnter:Connect',"hover remains event-driven")
need(boost,'badge.MouseLeave:Connect',"hover only closes on actual pointer leave")

print("UI interaction stability contract: PASS")
print("Background state sync cannot reset Settings scroll or destroy stable hover targets.")
