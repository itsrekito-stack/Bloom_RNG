#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

flower=read("src/ServerScriptService/Services/FlowerService.luau")
garden=read("src/StarterPlayer/StarterPlayerScripts/Controllers/GardenPresentationController.luau")
activity=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
hub=json.loads(read("src/Workspace/FruitOrchardHub.model.json"))

# Flower info is compact, disabled by default, and client-focus controlled.
need(flower,'info.Size = UDim2.fromOffset(142, 46)',"compact flower detail card")
need(flower,'info.MaxDistance = 28',"bounded flower detail distance")
need(flower,'info.Enabled = false',"flower cards start hidden")
need(garden,'local FLOWER_DETAIL_DISTANCE=24',"nearest flower focus radius")
need(garden,'descendant.Name=="FlowerInfo"',"FlowerInfo focus scan")
need(garden,'for _,info in ipairs(infos) do info.Enabled=info==nearest end',"single detailed flower card")
need(garden,'ui.Menu==nil and not ui:IsWorkshopExclusive()',"flower cards suppressed by menus")
need(garden,'local FLOWER_REFRESH_SECONDS=.18',"bounded flower focus refresh")

# Distant activity labels no longer fight flower/world UI for the screen center.
need(activity,'billboard.MaxDistance=o.Tutorial and 90 or 58',"activity label default distance")
need(activity,'item.Billboard.MaxDistance=tracked and 100 or (item.Tutorial and 90 or 58)',"tracked activity label distance")
need(activity,'Billboard=billboard',"activity billboard retained for state changes")

# Authored hub scenery must not contain the old camera-blocking gold orb or
# oversized 27-stud canopy spheres.
def walk(node,path=""):
    name=node.get("Name") or node.get("ClassName")
    here=f"{path}/{name}" if path else name
    yield here,node
    for child in node.get("Children",[]) or []:
        yield from walk(child,here)

nodes=list(walk(hub))
gold=next((n for p,n in nodes if n.get("Name")=="Golden hive monument"),None)
if not gold:
    raise AssertionError("Golden hive monument missing")
gold_size=gold.get("Properties",{}).get("Size")
if gold_size != [4.5,5,4.5]:
    raise AssertionError(f"Golden hive monument size regressed: {gold_size}")
if gold.get("Properties",{}).get("CanQuery") is not False:
    raise AssertionError("Golden hive monument must be non-queryable decorative scenery")

canopies=[n for p,n in nodes if "Great fruit tree" in p and (n.get("Name") or "").startswith("Canopy mass ")]
if len(canopies)!=7:
    raise AssertionError(f"Expected 7 Great fruit tree canopy masses, got {len(canopies)}")
for node in canopies:
    size=node.get("Properties",{}).get("Size")
    if size != [18,15,18]:
        raise AssertionError(f"Oversized Great fruit tree canopy returned: {node.get('Name')} {size}")
    if node.get("Properties",{}).get("CanQuery") is not False:
        raise AssertionError(f"Decorative canopy must be non-queryable: {node.get('Name')}")

print("world visual clutter contract: PASS")
print("Covered: oversized hub spheres, single focused flower card, menu suppression and bounded activity labels.")
