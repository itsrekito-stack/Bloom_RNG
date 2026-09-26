#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

activity_cfg=read("src/ReplicatedStorage/Config/ActivityConfig.luau")
activity=read("src/ServerScriptService/Services/GardenActivityService.luau")
boosts=read("src/ServerScriptService/Services/BoostService.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
ui_state=read("src/ServerScriptService/Services/UIStateService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
bootstrap=read("src/ServerScriptService/ServerBootstrap.server.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
hud=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BoostHUDController.luau")
journey=read("src/StarterPlayer/StarterPlayerScripts/Controllers/JourneyGuideController.luau")
model=json.loads(read("src/StarterGui/BloomUI.model.json"))

def walk(node):
    yield node
    for child in node.get("Children",[]) or []:
        yield from walk(child)

nodes={node.get("Name"):node for node in walk(model) if node.get("Name")}

need(activity_cfg,'SolarBloom={Life=30,Steps=3,Charge=12,CheckpointRadius=5.5,Boost={Duration=60,LuckMultiplier=1.20',"Solar Bloom actual boost config")
need(activity,'self.X.BoostService:ApplyActivity(player,kind)',"activity completion applies configured boost")
need(boosts,'function S:RollLuck(player,profile)',"server authoritative roll-luck aggregator")
need(boosts,'local base=self.X.StatsService:Get(p).Luck or 1',"bee trait/passive luck included in total")
need(boosts,'local solar=self:ActivityBoostMultiplier(player,"SolarBloom","LuckMultiplier")',"Solar Bloom luck included in total")
need(boosts,'for beeId,count in pairs(equippedCounts) do',"duplicate equipped bees aggregated by source")
need(boosts,'local _,activeTraits=Bees.GetTraitBonuses(p.Pollinators.EquippedBeeSlots)',"bee trait sources included")
need(boosts,'for slot,state in pairs(self.X.PollinatorService.States[player] or {}) do',"active bee abilities included")
need(boosts,'Id="BeeAbilities"',"active bee ability HUD entry")
need(boosts,'Id="SolarBloom"',"Solar Bloom timed HUD entry")
need(boosts,'source(buckets,stat,"Bees",bee.DisplayName.." ×"..count',"bee breakdown group")
need(boosts,'source(buckets,"Luck","Activity",tostring(solarCfg.Label or "Solar Bloom")',"activity breakdown group")
need(roll,'self.X.BoostService and self.X.BoostService:RollLuck(player,p)',"gameplay consumes authoritative boost total")
need(ui_state,'Boosts=self.X.BoostService and self.X.BoostService:Snapshot(player,profile) or {Items={}}',"boost summary exposed via UI state")
need(player,'if self.BoostService:Tick(player) then self:MarkStateDirty(player) end',"temporary boost expiry/state changes sync")
need(bootstrap,'"BoostService"',"BoostService registered")
need(ui,'self.BoostHUD=require(script.Parent.BoostHUDController)',"boost HUD controller wired")
need(ui,'self.BoostHUD:Update(boosts,self.State.Revision)',"boost HUD renders authoritative state")
need(ui,'if self.BoostHUD then self.BoostHUD:Tick() end',"boost HUD timer ticks")
need(hud,'badge.MouseEnter:Connect',"boost hover interaction")
need(hud,'self.TooltipBreakdown.Text=self:TooltipText(item)',"boost tooltip breakdown")
need(hud,'local line=group',"compact tooltip source line")
assert 'table.insert(lines,tostring(item.Description))' not in hud, "boost tooltip must not show long item descriptions"
assert 'table.insert(lines,"  "..tostring(entry.Description))' not in hud, "boost tooltip must not show long source descriptions"
need(hud,'local height=math.clamp(58+math.max(1,sourceCount)*20,78,180)',"compact tooltip height")
need(hud,'self.ItemsByBadge[badge]=item',"runtime boost timer data retained")
need(hud,'TweenService:Create(scale',"boost hover scale feedback")
need(hud,'function S:SetMinimized(minimized,animate)',"boost HUD minimize state")
need(hud,'self.Toggle.Activated:Connect',"authored minimize button binding")
need(hud,'self.Toggle.Text=self.Minimized and "+" or "−"', "minimize/expand visual state")
need(hud,'self.List.Visible=not self.Minimized and self.ItemCount>0',"collapsed list visibility")
need(hud,'function S:ApplyResponsiveLayout(width)',"collapsed HUD responsive sizing")
need(hud,'local contentWidth=16+count*52+math.max(0,count-1)*6',"boost-count-driven panel width")
need(hud,'local expandedWidth=math.clamp(contentWidth,168,maxWidth)',"compact boost panel width clamp")
need(hud,'self.ExpandedSize=UDim2.fromOffset(expandedWidth,82)',"compact expanded geometry")
need(hud,'self.Root.Position=UDim2.new(0,12,1,-14)',"bottom-left compact placement")
need(hud,'self:ApplyResponsiveLayout(safeWidth)',"boost count triggers responsive resize")
need(journey,'Reward: +20% Roll Luck for 60s',"Solar Bloom reward explained before completion")

root=nodes.get("ActiveBoostsHUD")
tooltip=nodes.get("ActiveBoostTooltip")
template=nodes.get("BoostTemplate")
minimize=nodes.get("MinimizeButton")
if not root or root.get("ClassName")!="Frame":
    raise AssertionError("authored ActiveBoostsHUD frame missing")
if not tooltip or tooltip.get("ClassName")!="Frame":
    raise AssertionError("authored ActiveBoostTooltip frame missing")
if not template or template.get("ClassName")!="ImageButton":
    raise AssertionError("authored BoostTemplate button missing")
if not minimize or minimize.get("ClassName")!="TextButton":
    raise AssertionError("authored Active Boosts minimize button missing")
if template.get("Properties",{}).get("Visible") is not False:
    raise AssertionError("BoostTemplate must stay authored but hidden")
if root.get("Properties",{}).get("AnchorPoint",{}).get("Vector2") != [0,1]:
    raise AssertionError("ActiveBoostsHUD must be bottom-left anchored")
root_size=root.get("Properties",{}).get("Size",{}).get("UDim2")
if root_size != [[0,168],[0,82]]:
    raise AssertionError(f"ActiveBoostsHUD authored compact size regressed: {root_size}")
boost_list=nodes.get("BoostList")
layout=nodes.get("UIListLayout")
value=next((child for child in template.get("Children",[]) if child.get("Name")=="Value"),None)
icon=next((child for child in template.get("Children",[]) if child.get("Name")=="Icon"),None)
if not boost_list or boost_list.get("Properties",{}).get("ScrollingDirection")!="X":
    raise AssertionError("BoostList must remain horizontal")
if not layout or layout.get("Properties",{}).get("FillDirection")!="Horizontal":
    raise AssertionError("BoostList UIListLayout must explicitly be horizontal")
if template.get("Properties",{}).get("Size",{}).get("UDim2") != [[0,52],[0,52]]:
    raise AssertionError("BoostTemplate compact card size regressed")
if not icon or icon.get("Properties",{}).get("Size",{}).get("UDim2") != [[0,30],[0,30]]:
    raise AssertionError("Boost icon size regressed")
if not value or value.get("Properties",{}).get("BackgroundTransparency",1)>=1:
    raise AssertionError("Boost value must use the authored compact badge treatment")
value_children={child.get("Name") for child in value.get("Children",[]) or []}
if not {"ValueCorner","ValueStroke"}<=value_children:
    raise AssertionError("Boost value badge decoration missing")

print("active boosts contract: PASS")
print("Solar Bloom reward, Bee aggregate sources, active abilities, authored HUD, hover tooltip, and server authority verified.")
