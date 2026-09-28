#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

model=json.loads(read("src/StarterGui/BloomUI.model.json"))
controller=read("src/StarterPlayer/StarterPlayerScripts/Controllers/TraitHUDController.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")

def find(node,name):
    if node.get("Name")==name: return node
    for child in node.get("Children",[]) or []:
        hit=find(child,name)
        if hit: return hit
    return None

for name in ["TraitHUD","TraitList","TraitTemplate","TraitTooltip","TraitTierPopup"]:
    if not find(model,name): raise AssertionError(f"authored trait UI missing: {name}")

template=find(model,"TraitTemplate")
for name in ["IconBadge","TraitIcon","Name","Tier","Progress","HighlightScale"]:
    if not find(template,name): raise AssertionError(f"TraitTemplate missing {name}")
if find(template,"BeeStrip"): raise AssertionError("TraitTemplate must not show Bee icons persistently")
tooltip=find(model,"TraitTooltip")
for name in ["BeeStrip","BeeIconTemplate"]:
    if not find(tooltip,name): raise AssertionError(f"TraitTooltip missing hover Bee UI: {name}")

for text,label in [
    ('local function signature(traits,equippedSlots)',"stable trait + equipped Bee signature"),
    ('if nextSignature==self.LastSignature then',"unrelated state revisions keep rows stable"),
    ('if (tonumber(item.Count) or 0)>0 then visible[#visible+1]=item end',"only equipped-build traits shown"),
    ('progressText(item)',"n1/n2 presentation"),
    ('traitIcon(item.Id)',"Trait icon projection"),
    ('local beeStrip=self.Tooltip:FindFirstChild("BeeStrip")',"Bee icons live in hover tooltip"),
    ('beeIcon(beeId)',"member Bee icon projection"),
    ('local isEquipped=equipped[beeId]==true',"equipped Bee visual state"),
    ('member.ImageTransparency=isEquipped and 0 or .42',"unequipped Bee dimming"),
    ('row.MouseEnter:Connect(function() self:ShowTooltip(item) end)',"hover tooltip enter"),
    ('row.MouseLeave:Connect(function() self:HideTooltip() end)',"hover tooltip leave"),
    ('thresholdText(item)',"tooltip threshold effects"),
    ('beeNames(item)',"tooltip member Bees"),
    ('tier>previous',"tier increase detection"),
    ('self:ShowTierPopup(item,row)',"tier-up feedback"),
    ('task.delay(1.7',"short tier popup duration"),
    ('TweenService:Create(stroke,TweenInfo.new(1.4',"temporary row highlight"),
    ('self.Root.Visible=not self.Suppressed',"suppression-aware root"),
]:
    need(controller,text,label)

for text,label in [
    ('self.TraitHUD=require(script.Parent.TraitHUDController)',"Trait HUD lifecycle wiring"),
    ('self.TraitHUD:Init(self)',"Trait HUD init"),
    ('self.TraitHUD:Update(traits,inventory.EquippedBeeSlots or {},self.State.Revision)',"Trait HUD state + equipped Bee update"),
    ('self.TraitHUD:SetSuppressed(exclusive)',"Workshop suppresses Trait HUD"),
    ('self.TraitHUD:SetSuppressed(false)',"Workshop restores Trait HUD"),
]:
    need(bloom,text,label)

need(bees,'function C.GetTraitState(equipped:{string}?):{any}',"authoritative trait-state helper")
need(bees,'NextThreshold=nextThreshold',"next threshold projection")
need(bees,'BeeIds=C.GetTraitBees(traitId)',"member Bee projection")

need(editor_html,'data-ui-state="traits"',"Trait UI Studio state")
need(editor,'traits:"Traits"',"Trait UI Studio title")
need(editor,'traits:"TraitHUD"',"Trait UI Studio focus")
need(editor,'if(name==="TraitHUD")return scene==="gameplay"||scene==="traits";',"HUD/Traits preview visibility")
need(editor,'if(name==="TraitTooltip"||name==="TraitTierPopup")return scene==="traits";',"Trait detail preview visibility")

print("trait HUD contract: PASS")
print("TFT-style left Trait list, n1/n2 progress, hover details and short tier-up feedback are authored and state-stable.")
