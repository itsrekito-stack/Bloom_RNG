#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

model=json.loads(read("src/StarterGui/BloomUI.model.json"))
state=read("src/ServerScriptService/Services/UIStateService.luau")
controller=read("src/StarterPlayer/StarterPlayerScripts/Controllers/IndexController.luau")
bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
inventory=read("src/StarterPlayer/StarterPlayerScripts/Controllers/InventoryV2Controller.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
editor=read("tools/bloom-ui-editor/app.js")
editor_html=read("tools/bloom-ui-editor/index.html")

def find(node,name):
    if node.get("Name")==name: return node
    for child in node.get("Children",[]) or []:
        hit=find(child,name)
        if hit: return hit
    return None

proto=find(model,"IndexPrototype")
if not proto: raise AssertionError("IndexPrototype missing")
for name in ["TopBar","CategoryNav","CatalogPanel","CatalogGrid","IndexCardTemplate","DetailsPanel","DetailContent","DetailScroll","DetailBody"]:
    if not find(proto,name): raise AssertionError(f"Index authored node missing: {name}")
for category in ["Flowers","Bees","Synergies","Traits"]:
    if not find(proto,"Category_"+category): raise AssertionError(f"Index category missing: {category}")
if not find(model,"Dock_Index"): raise AssertionError("authored Index dock button missing")

# Server payload: discovered entries are detailed, locked entries expose only slot/unlocked state.
for text,label in [
    ('flowers[#flowers+1]={Slot=slot,Unlocked=false}',"Flower locked redaction"),
    ('bees[#bees+1]={Slot=slot,Unlocked=false}',"Bee locked redaction"),
    ('synergies[#synergies+1]={Slot=slot,Unlocked=false}',"Synergy locked redaction"),
    ('traits[#traits+1]={Slot=slot,Unlocked=false}',"Trait locked redaction"),
    ('Flowers={Items=flowers,Progress=progress(flowers)}',"Flower category progress"),
    ('Bees={Items=bees,Progress=progress(bees)}',"Bee category progress"),
    ('Synergies={Items=synergies,Progress=progress(synergies)}',"Synergy category progress"),
    ('Traits={Items=traits,Progress=progress(traits)}',"Trait category progress"),
    ('New=read.Flowers[id]~=true',"Flower NEW state"),
    ('New=read.Bees[id]~=true',"Bee NEW state"),
    ('New=read.Synergies[recipe.Id]~=true',"Synergy NEW state"),
    ('New=read.Traits[id]~=true',"Trait NEW state"),
    ('function S:MarkIndexRead(profile,category,id)',"read-state mutation"),
]:
    need(state,text,label)

# Client shell: left nav, dense cards, right details, no hidden silhouette data.
for text,label in [
    ('local CATEGORY_ORDER={"Flowers","Bees","Synergies","Traits"}',"Index categories"),
    ('state={Category="Flowers",Selected={}}',"Index local navigation state"),
    ('catalogProgress.Text=pctText(data.Progress)',"per-category progress"),
    ('cardTemplate:Clone()',"dense card cloning"),
    ('lock.Visible=not unlocked',"lock-only hidden entry"),
    ('icon.Visible=unlocked',"hidden icon suppression"),
    ('name.Visible=unlocked',"hidden name suppression"),
    ('meta.Visible=unlocked',"hidden metadata suppression"),
    ('newBadge.Visible=unlocked and item.New==true',"NEW badge"),
    ('controller:Send("IndexViewed",category,item.Id)',"NEW clears on first selected view"),
    ('detail.Visible=true',"right detail panel"),
    ('flowerDetail(item)',"Flower details"),
    ('beeDetail(item)',"Bee details"),
    ('synergyDetail(item)',"Synergy details"),
    ('traitDetail(item)',"Trait details"),
    ('item.Level or 1',"Flower Level detail"),
    ('item.Obtained or 1',"Bee obtained detail"),
    ('item.Mastery',"Bee Mastery detail"),
    ('item.LevelRequirements',"Synergy level requirements"),
    ('item.Effect',"Synergy effect"),
    ('item.Breakpoints',"Trait tier thresholds"),
    ('item.BeeIds',"Trait member Bees"),
    ('item.BiomeModifiers',"Trait biome modifiers"),
]:
    need(controller,text,label)

if '"LOCKED"' in controller or '"???"' in controller:
    raise AssertionError("locked Index cards must remain empty aside from lock icon")

# Fullscreen focus and Inventory access.
for text,label in [
    ('Index="IndexV1"',"Index renderer route"),
    ('local fullscreen=workshop or index',"Index shares fullscreen geometry"),
    ('if name=="Index" then self:SetIndexFocus(true) end',"Index focus activation"),
    ('if wasIndex then self:SetIndexFocus(false) end',"Index focus restore"),
    ('self:ApplyIndexFocusVisibility()',"Index HUD suppression"),
    ('IndexV1.Render(self,p,ui)',"Index renderer dispatch"),
    ('IndexViewed="Index"',"read-state refresh mapping"),
]:
    need(bloom,text,label)
need(bloom,'for _,name in ipairs({"SeedSatchel","Garden","Index","Workshop","Trials","Settings"}) do',"Index opens from the authored bottom dock")
if 'controller:Open("Index"' in inventory:
    raise AssertionError("Inventory must not carry a second disconnected Index entry point")
need(player,'elseif action=="IndexViewed" then return self.UIStateService:MarkIndexRead(p,a,b)',"IndexViewed server route")
need(remote,'elseif action=="IndexViewed" then',"IndexViewed schema")

# UI Studio exposes the authored fullscreen shell.
need(editor_html,'data-ui-state="index"',"Index UI Studio state")
need(editor,'index:"Index"',"Index Studio title")
need(editor,'index:"IndexPrototype"',"Index Studio focus")
need(editor,'if(name==="IndexPrototype")return scene==="index";',"Index preview visibility")
need(editor,'scene==="index")return [[1,0],[1,0]]',"Index fullscreen preview")

print("index UI contract: PASS")
print("Fullscreen Index uses four category progress tracks, lock-only hidden cards, NEW-on-first-view state, dense catalog cards and category-specific right details.")
