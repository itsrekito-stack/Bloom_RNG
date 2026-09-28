#!/usr/bin/env python3
from pathlib import Path
import re, json

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/QuestConfig.luau")
service=read("src/ServerScriptService/Services/QuestService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")
state=read("src/ServerScriptService/Services/UIStateService.luau")
hive=read("src/ServerScriptService/Services/HiveService.luau")
synergies=read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau")
bloom=read("src/ReplicatedStorage/Config/BloomConfig.luau")
season=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
workshop=read("src/ServerScriptService/Services/WorkshopService.luau")
default=read("src/ServerScriptService/Data/DefaultProfile.luau")
schema=read("src/ServerScriptService/Data/ProfileSchema.luau")

order_match=re.search(r'C\.Order=\{(.*?)\n\}',cfg,re.S)
if not order_match: raise AssertionError("Quest order missing")
order=re.findall(r'"(Q\d+_[A-Za-z0-9_]+)"',order_match.group(1))
if len(order)!=25 or len(set(order))!=25:
    raise AssertionError(f"expected exactly 25 unique quests, got {len(order)}")
if order[0]!="Q01_FirstRolls" or order[-1]!="Q25_BloomKeeper":
    raise AssertionError(f"quest endpoints drifted: {order[0]} -> {order[-1]}")

for i,id in enumerate(order,1):
    if not re.search(rf'\b{re.escape(id)}=\{{',cfg):
        raise AssertionError(f"Quest definition missing: {id}")
need(cfg,'Q05_FirstBloom={Title="Bloom Spark"', "early Bloom quest")
need(cfg,'Q18_BeeScholar={Title="Bee Scholar"', "Bee Mastery quest")
need(cfg,'Q24_HiveTen={Title="Hive Architect"', "late Hive quest")
need(cfg,'Q25_BloomKeeper={Title="Bloom Keeper"', "final collection quest")
need(cfg,'Q09_SynergyPractice={Title="Garden Chemistry",Text="Discover 2 Garden Synergies.",Kind="GardenSynergies"',"early distinct-synergy quest")
need(cfg,'Q19_SynergyBuilder={Title="Pattern Builder",Text="Discover 8 Garden Synergies.",Kind="GardenSynergies"',"late distinct-synergy quest")
synergy_count=len(re.findall(r'\{Id="[^"]+",Name="[^"]+",Strength=',synergies))
if synergy_count<8: raise AssertionError("quest line requires more distinct Garden Synergies than the game ships")

need(service,'function S:Progress(profile,quest)',"server progress evaluator")
need(service,'function S:Claim(player,id)',"server reward claim")
need(service,'if order>1 and profile.Quests.Claimed[C.Order[order-1]]~=true then return false,"QUEST_LOCKED" end',"sequential quest authority")
need(service,'if current<target then return false,"QUEST_INCOMPLETE" end',"objective authority")
need(service,'self.X.WorkshopService:Point(player,"Quest_"..id,points)',"quest Workshop Point source")
need(service,'function S:SyncJourney(profile)',"HUD quest pointer")
need(player,'elseif action=="ClaimQuest" then return self.QuestService:Claim(player,a)',"claim route")
need(remote,'or action=="ClaimQuest"', "claim remote schema")
need(state,'Quests=self.X.QuestService:State(profile)',"quest snapshot")
need(hive,'self.X.QuestService:ClaimedCount(profile)',"Hive quest gate uses new quests")
need(bloom,'[8]={Quests=6}',"Hive 8 quest gate")
need(season,'Quests=15',"Season quest threshold")
need(workshop,'function S:ReconcileHivePoints(player)',"missing Hive point recovery")
need(workshop,'HiveSeason_', "season-aware Hive point source")
need(default,'Quests={JourneyStep=1,Claimed={}}',"Trial-free quest profile")
need(schema,'TrialsRemovedV1',"legacy Trial archive migration")

for deleted in [
    "src/ReplicatedStorage/Config/BuildTrialConfig.luau",
    "src/ServerScriptService/Services/BuildTrialService.luau",
    "src/ServerScriptService/Services/MetaProgressionService.luau",
]:
    if (ROOT/deleted).exists():
        raise AssertionError(f"retired progression file still exists: {deleted}")

runtime=[player,remote,state,hive,service]
for token in ("BuildTrialService","BuildTrialConfig",'action=="Trial"',"Quests.Trials","FeatureUnlocks.Trials"):
    if any(token in src for src in runtime):
        raise AssertionError(f"retired Trial runtime token returned: {token}")

print("quest progression contract: PASS")
print("25 sequential quests, server-authoritative claims, Hive/Season gates and Trial-free runtime verified.")
