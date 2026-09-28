#!/usr/bin/env python3
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

bloom=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
settings=read("src/StarterPlayer/StarterPlayerScripts/Controllers/SettingsController.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
data_service=read("src/ServerScriptService/Services/DataService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
defaults=read("src/ServerScriptService/Data/DefaultProfile.luau")
tutorial=read("src/StarterPlayer/StarterPlayerScripts/Controllers/TutorialGuideController.luau")
model=json.loads(read("src/StarterGui/BloomUI.model.json"))

def find(node,name):
    if node.get("Name")==name: return node
    for child in node.get("Children",[]):
        hit=find(child,name)
        if hit: return hit
    return None

kit=find(model,"SettingsKit")
if not kit: raise AssertionError("authored SettingsKit missing")
for name in [
    "SettingsShell","CategoryPanel","ContentPanel","SettingsScroll",
    "Category_General","Category_Audio","Category_Gameplay","Category_Interface","Category_Graphics","Category_Controls",
    "TutorialsToggle","RewardPopupsToggle","MusicVolumeSlider","SfxVolumeSlider","MuteAllToggle",
    "AutoRollToggle","QuickRollToggle","RarityColorsToggle","CompactHudToggle","BloomToggle",
    "LowEffectsToggle","UiScaleSlider","EffectiveLuckInput","OpenMenuKeybind","RollKeybind","ResetButton","ApplyButton","SaveButton",
    "ResetProgressWarning","FullResetButton",
]:
    if not find(kit,name): raise AssertionError(f"SettingsKit authored node missing: {name}")

for name in ["CurrencyHUD","MenuDock","RollHUD","RollButton"]:
    node=find(model,name)
    if not node or not any(c.get("Name")=="UserScale" and c.get("ClassName")=="UIScale" for c in node.get("Children",[])):
        raise AssertionError(f"compact HUD authored UserScale missing: {name}")

need(bloom,'local SettingsV2=require(script.Parent.SettingsController)',"settings controller require")
need(bloom,'local MENU_RENDERERS={SeedSatchel="InventoryV2",Garden="GardenV1",Index="IndexV1",Trials="QuestsV2",Settings="SettingsV2"}',"settings renderer dispatch")
need(bloom,'elseif renderer=="SettingsV2" then',"settings renderer branch")
need(bloom,'SettingsV2.Render(self,p,ui)',"settings authored render")
if 'elseif name=="Settings" then' in bloom:
    raise AssertionError("legacy generated Settings branch returned")

for text,label in [
    ('function S.Render(ui,profile,uiState)',"authored Settings renderer"),
    ('template:Clone()',"SettingsKit clone"),
    ('ui:Send("Setting",key,lastValue)',"slider server commit"),
    ('ui:Send("ResetSettings")',"reset settings request"),
    ('ui:Send("SaveSettings")',"save settings request"),
    ('ui:SetAutoRolling(not ui.Auto)',"Auto Roll binding"),
    ('bindKeybind(ui,openKey,"OpenMenuKey")',"menu keybind"),
    ('bindKeybind(ui,rollKey,"RollKey")',"roll keybind"),
    ('find(scroll,"EffectiveLuckInput","TextBox")',"Effective Luck authored binding"),
    ('ui:Send("Setting","EffectiveLuck",value)',"Effective Luck server commit"),
    ('raw=="MAX"',"Effective Luck MAX sentinel"),
    ('object:IsA("BloomEffect")',"Bloom effect binding"),
    ('ui:Send("FullReset","RESET_ALL_PROGRESS")',"full reset confirmed request"),
    ('CONFIRM FULL RESET',"full reset second-click confirmation"),
]:
    need(settings,text,label)

for text,label in [
    ('SaveSettings=true,ResetSettings=true',"no-arg remote validation"),
    ('or short(b,16,false)',"string setting remote validation"),
    ('action=="FullReset"',"full reset remote route"),
    ('a=="RESET_ALL_PROGRESS"',"full reset confirmation token"),
]:
    need(remote,text,label)

for text,label in [
    ('elseif action=="SaveSettings" then',"settings persistence route"),
    ('elseif action=="ResetSettings" then',"settings reset route"),
    ('p.Settings=U.Copy(DefaultSettings)',"settings defaults reset"),
    ('MusicVolume={0,1}',"music volume clamp"),
    ('SFXVolume={0,1}',"SFX volume clamp"),
    ('UIScale={.8,1.15}',"UI scale clamp"),
    ('EffectiveLuck={0,1000000}',"Effective Luck clamp"),
    ('a=="EffectiveLuck" and b~=0 and b<1',"Effective Luck minimum validation"),
    ('a=="OpenMenuKey" or a=="RollKey"',"keybind allowlist"),
    ('TutorialsEnabled=true,RewardPopups=true,QuickRoll=true,ShowRarityColors=true,CompactHUD=true',"new boolean settings allowlist"),
    ('function X:FullReset(player)',"full reset server action"),
    ('self.DataService:ResetProfile(player)',"full reset persistence transaction"),
    ('self:RebuildFreshRuntime(player)',"full reset runtime rebuild"),
]:
    need(player,text,label)

for text,label in [
    ('function Service:ResetProfile(player)',"DataService full reset transaction"),
    ('Schema.CreateDefault()',"full reset creates a clean default profile"),
    ('self:CommitProfile(player,fresh,transactionId)',"full reset commits before runtime rebuild"),
]:
    need(data_service,text,label)

for text,label in [
    ('Language="English"',"language default"),
    ('TutorialsEnabled=true',"tutorials default"),
    ('RewardPopups=true',"reward popup default"),
    ('QuickRoll=false',"quick roll default"),
    ('ShowRarityColors=true',"rarity color default"),
    ('CompactHUD=false',"compact HUD default"),
    ('BloomEnabled=true',"Bloom default"),
    ('MuteAll=false',"mute default"),
    ('MusicVolume=.5',"music default"),
    ('SFXVolume=.5',"SFX default"),
    ('UIScale=1',"UI scale default"),
    ('OpenMenuKey="M"',"menu key default"),
    ('RollKey="R"',"roll key default"),
    ('EffectiveLuck=0',"Effective Luck defaults to MAX"),
]:
    need(defaults,text,label)


input_node=find(kit,"EffectiveLuckInput")
if input_node.get("ClassName")!="TextBox":
    raise AssertionError("EffectiveLuckInput must be authored as TextBox")
if input_node.get("Properties",{}).get("Text")!="MAX":
    raise AssertionError("EffectiveLuckInput authored default must display MAX")
reset_node=find(kit,"StudioTutorialResetButton")
if reset_node and "V8" not in reset_node.get("Properties",{}).get("Text",""):
    raise AssertionError("Studio tutorial reset copy is stale")
full_reset=find(kit,"FullResetButton")
if full_reset.get("Properties",{}).get("Text")!="RESET ALL PROGRESS":
    raise AssertionError("FullResetButton authored copy is wrong")

need(tutorial,'p.Settings and p.Settings.TutorialsEnabled==false',"tutorial visibility preference")
need(bloom,'self.State.Profile.Settings.RewardPopups~=false',"reward popup preference")
need(bloom,'self.State.Profile.Settings.QuickRoll==true',"quick roll preference")
need(bloom,'self.State.Profile.Settings.ShowRarityColors~=false',"rarity color preference")
need(bloom,'settings.MuteAll and 0',"mute preference")
need(bloom,'settings.OpenMenuKey or "M"',"menu key runtime")
need(bloom,'settings.RollKey or "R"',"roll key runtime")

print("settings-v2 runtime contract: PASS")
print("Covered: authored SettingsKit, Effective Luck MAX/value input, server authority/persistence, toggles, sliders, keybinds, audio, tutorial hints and compact HUD.")
