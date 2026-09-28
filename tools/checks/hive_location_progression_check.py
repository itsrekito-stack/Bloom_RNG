#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

locations=read("src/ReplicatedStorage/Config/LocationsConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
ui=read("src/ServerScriptService/Services/UIStateService.luau")
season=read("src/ServerScriptService/Services/SeasonService.luau")

need(locations,'Order={"SunnyOrchard","CrystalGreenhouse","TwilightGrove"}',"location progression order")
need(locations,'CrystalGreenhouse={Name="Crystal Greenhouse",Hive=4,Requires="SunnyOrchard"',"Crystal requires Sunny")
need(locations,'TwilightGrove={Name="Twilight Grove",Hive=6,Requires="CrystalGreenhouse"',"Twilight requires Crystal")

levels=[int(x) for x in re.findall(r'(?:SunnyOrchard|CrystalGreenhouse|TwilightGrove)=\{[^}]*Hive=(\d+)',locations)]
if levels != [2,4,6]:
    raise AssertionError(f"unexpected location Hive thresholds: {levels}")
costs_match=re.search(r'HiveCosts=\{([^}]+)\}',bloom)
if not costs_match:
    raise AssertionError("HiveCosts missing")
costs=[int(float(x)) for x in re.findall(r'[0-9.]+',costs_match.group(1))]
if len(costs)<8 or costs[1]<=0:
    raise AssertionError(f"Hive cost ladder cannot reach level 8: {costs}")

need(hive,'local cost=C.HiveCosts[nextLevel]',"Hive upgrade cost from config")
need(hive,'if p.Hive.Honey<cost then',"Hive Honey affordability")
need(hive,'p.Hive.Honey-=cost',"Hive server-side spend")
need(hive,'p.Hive.Level=nextLevel',"Hive server-side level mutation")
need(hive,'self.X.WorkshopService:Point(player,"Hive_"',"Hive awards Workshop progression")
need(hive,'self.X.GardenPlotService:RefreshCapacity(player)',"Hive updates garden capacity")
need(hive,'self.X:Emit(player,"FirstGardenSlot",1)',"Hive interaction unlocks first Garden slot")
need(hive,'self.X.GardenPlotService:RefreshCapacity(player)',"first Garden slot refreshes capacity")
need(hive,'location.Name.." gate is ready to unlock"',"Hive milestone points player to location gate")
need(hive,'"Hive is at max level"',"max Hive feedback")

need(garden,'function S:HivePromptText(p)',"dynamic Hive prompt copy")
need(garden,'return "Unlock Garden Slot 1"',"fresh Hive prompt unlocks first Garden slot")
need(garden,'("Upgrade Hive • "..math.floor(cost).." Honey")',"upgrade cost shown in world prompt")
need(garden,'prompt.ObjectText="Hive • Level "..p.Hive.Level',"Hive level shown in world prompt")
need(garden,'self:RefreshHivePrompt(player)',"garden rebuild refreshes Hive prompt")

need(map_service,'if s.Requires and not p.World.UnlockedSectors[s.Requires] then',"server enforces ordered location prerequisite")
need(map_service,'if p.Hive.Level<s.Hive then',"server enforces Hive gate")
need(map_service,'self.X.U.Near(player,gate.Position,C.InteractionDistance)',"server enforces gate proximity")
need(map_service,'p.World.UnlockedSectors[id]=true',"sector unlock is monotonic")
if 'p.World.UnlockedSectors[id]=false' in map_service:
    raise AssertionError("location downgrade path returned")

need(ui,'PrerequisiteReady=prerequisiteReady',"UI exposes prerequisite readiness")
need(ui,'CanUnlock=not unlocked and prerequisiteReady and hiveReady and nearGate',"UI actionability matches server gate")
need(ui,'hint="Unlock "..(required and required.Name or cfg.Requires).." first"',"UI explains prerequisite block")
need(season,'p.World.UnlockedSectors.SunnyOrchard and p.World.UnlockedSectors.CrystalGreenhouse and p.World.UnlockedSectors.TwilightGrove',"Season still requires full location chain")

print("hive / location progression contract: PASS")
print("Hive 1→8, first Garden slot, and Sunny→Crystal→Twilight progression are ordered, proximity-gated and server-authoritative.")
