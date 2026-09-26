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
player=read("src/ServerScriptService/Services/PlayerService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
garden_plot=read("src/ServerScriptService/Services/GardenPlotService.luau")
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

# Static world should be authored, compact and composed from editable Roblox objects.
need(player,'workspace:FindFirstChild("FruitOrchardHub")',"authored hub binding")
if '"CentralMeadow"' in player:
    raise AssertionError("runtime 440-stud CentralMeadow baseplate returned")
if 'Vector3.new(95,2,95)' in map_service:
    raise AssertionError("runtime 95x95 sector placeholder slabs returned")

def walk(node,path=""):
    name=node.get("Name") or node.get("ClassName")
    here=f"{path}/{name}" if path else name
    yield here,node
    for child in node.get("Children",[]) or []:
        yield from walk(child,here)

nodes=list(walk(hub))
top_names={child.get("Name") for child in hub.get("Children",[]) or []}
required={"Terrain","Central Hub","Paths","Biome Zones","Environment"}
missing=required-top_names
if missing:
    raise AssertionError(f"authored hub groups missing: {sorted(missing)}")

if len(nodes)>300:
    raise AssertionError(f"authored hub became too dense: {len(nodes)} nodes (budget 300)")

for retired in ("Great fruit tree","Garden promenade","Golden hive monument"):
    if any(retired in path for path,_ in nodes):
        raise AssertionError(f"retired oversized/overdense scenery returned: {retired}")

by_name={node.get("Name"):node for _,node in nodes if node.get("Name")}
main=by_name.get("Main Meadow Grass")
if not main:
    raise AssertionError("Main Meadow Grass missing")
main_props=main.get("Properties",{})
if main_props.get("Size") != [1,296,296]:
    raise AssertionError(f"unexpected main meadow footprint: {main_props.get('Size')}")
if main_props.get("CanCollide") is not True or main_props.get("CanQuery") is not True:
    raise AssertionError("main meadow must remain a physical/queryable gameplay surface")

for name in ("Sunny Orchard Grass","Crystal Garden Grass","Twilight Grove Grass"):
    zone=by_name.get(name)
    if not zone:
        raise AssertionError(f"authored biome surface missing: {name}")
    props=zone.get("Properties",{})
    if props.get("CanCollide") is not True or props.get("CanQuery") is not True:
        raise AssertionError(f"biome surface must remain walkable/queryable: {name}")

canopies=[
    node for _,node in nodes
    if "Canopy" in (node.get("Name") or "") and node.get("ClassName")=="Part"
]
if not canopies:
    raise AssertionError("low-poly tree canopies missing")
for node in canopies:
    size=node.get("Properties",{}).get("Size") or []
    if not size or max(size)>12:
        raise AssertionError(f"camera-blocking canopy returned: {node.get('Name')} {size}")
    if node.get("Properties",{}).get("CanQuery") is not False:
        raise AssertionError(f"decorative canopy must be non-queryable: {node.get('Name')}")

# Personal plots stay gameplay-compatible but should no longer be neon/square placeholders.
need(garden_plot,'base.Shape=Enum.PartType.Cylinder',"rounded player plot")
need(garden_plot,'hive.Shape=Enum.PartType.Cylinder',"low-poly Hive body")
need(garden_plot,'pad.Shape=Enum.PartType.Cylinder',"rounded garden slots")
need(garden_plot,'hive.Material=Enum.Material.WoodPlanks',"Hive material")
if 'Vector3.new(44,2,48)' in garden_plot:
    raise AssertionError("old rectangular player plot returned")

print("world visual clutter contract: PASS")
print(f"Covered: authored low-poly hub ({len(nodes)} nodes), walkable biome surfaces, bounded canopies, rounded plots and no runtime sector/baseplate placeholders.")
