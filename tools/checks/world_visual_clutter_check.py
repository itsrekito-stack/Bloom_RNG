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

# Existing world UI clutter guards stay intact.
need(flower,'info.Size = UDim2.fromOffset(142, 46)',"compact flower detail card")
need(flower,'info.MaxDistance = 28',"bounded flower detail distance")
need(flower,'info.Enabled = false',"flower cards start hidden")
need(garden,'local FLOWER_DETAIL_DISTANCE=24',"nearest flower focus radius")
need(garden,'descendant.Name=="FlowerInfo"',"FlowerInfo focus scan")
need(garden,'for _,info in ipairs(infos) do info.Enabled=info==nearest end',"single detailed flower card")
need(garden,'ui.Menu==nil and not ui:IsWorkshopExclusive()',"flower cards suppressed by menus")
need(activity,'billboard.MaxDistance=o.Tutorial and 90 or 58',"activity label default distance")

# Alpha map is intentionally sparse and authored.
need(player,'workspace:FindFirstChild("FruitOrchardHub")',"authored hub binding")
need(player,'{"ReferenceScenery","BrickCenter"}',"stale top-level scenery cleanup")
need(player,'{"LocationDecorTemplates","LocationTemplates"}',"stale Garden scenery cleanup")
if '"CentralMeadow"' in player:
    raise AssertionError("runtime CentralMeadow placeholder returned")
if 'Vector3.new(95,2,95)' in map_service:
    raise AssertionError("runtime sector placeholder slabs returned")

for token in ("GatePost","GateBeam","WorkshopGlow","AncientTreeCanopy"):
    if token in map_service:
        raise AssertionError(f"alpha-unneeded runtime decoration returned: {token}")

for token in ("PlotBorder","HiveBase","HiveBand_","HiveEntrance"):
    if token in garden_plot:
        raise AssertionError(f"alpha-unneeded plot decoration returned: {token}")

def walk(node,path=""):
    name=node.get("Name") or node.get("ClassName")
    here=f"{path}/{name}" if path else name
    yield here,node
    for child in node.get("Children",[]) or []:
        yield from walk(child,here)

nodes=list(walk(hub))
top={child.get("Name"):child for child in hub.get("Children",[]) or []}
required={"Terrain","Central Hub","Paths","Biome Zones","Environment"}
missing=required-set(top)
if missing:
    raise AssertionError(f"authored hub groups missing: {sorted(missing)}")

if len(nodes)>20:
    raise AssertionError(f"alpha hub became decorative again: {len(nodes)} nodes (budget 20)")

for group in ("Biome Zones","Environment"):
    if top[group].get("Children"):
        raise AssertionError(f"{group} must stay empty during alpha")

by_name={node.get("Name"):node for _,node in nodes if node.get("Name")}
main=by_name.get("Main Meadow Grass")
if not main:
    raise AssertionError("Main Meadow Grass missing")
props=main.get("Properties",{})
if props.get("Size") != [400,1,400]:
    raise AssertionError(f"unexpected alpha floor size: {props.get('Size')}")
if props.get("CanCollide") is not True or props.get("CanQuery") is not True:
    raise AssertionError("alpha floor must remain walkable/queryable")

def top_y(node):
    props=node.get("Properties",{})
    cf=props.get("CFrame")
    size=props.get("Size")
    if not (isinstance(cf,list) and len(cf)>=12 and isinstance(size,list) and len(size)>=3):
        raise AssertionError(f"cannot calculate Y for {node.get('Name')}")
    half=abs(cf[6])*size[0]/2+abs(cf[7])*size[1]/2+abs(cf[8])*size[2]/2
    return cf[1]+half

base_y=top_y(main)
walkable_names=[
    "Sunny Orchard Pad","Crystal Greenhouse Pad","Twilight Grove Pad",
    "Central Alpha Plaza","Path Sunny","Path Crystal","Path Twilight",
]
for name in walkable_names:
    node=by_name.get(name)
    if not node:
        raise AssertionError(f"alpha surface missing: {name}")
    if abs(top_y(node)-base_y)>.13:
        raise AssertionError(f"{name} is not aligned to base Y: top={top_y(node):.3f}, base={base_y:.3f}")

# Personal plots remain one clean ground disk + one bed + functional Hive/slots.
need(garden_plot,'base.Shape=Enum.PartType.Cylinder',"rounded player plot")
need(garden_plot,'bed.Shape=Enum.PartType.Cylinder',"single garden bed")
need(garden_plot,'hive.Shape=Enum.PartType.Cylinder',"functional Hive")
need(garden_plot,'pad.Shape=Enum.PartType.Cylinder',"rounded garden slots")
need(garden_plot,'origin-Vector3.new(0,.5,0)',"plot ground aligned to origin Y")
need(garden_plot,'pos+Vector3.new(0,.025,0)',"slot pads aligned close to plot Y")

retired_paths=[
 "src/Workspace/ReferenceScenery.rbxm",
 "src/Workspace/BrickCenter.rbxm",
 "src/Workspace/Garden/LocationDecorTemplates/CrystalGreenhouseDecor.model.json",
 "src/Workspace/Garden/LocationDecorTemplates/StarterOrchardDecor.model.json",
 "src/Workspace/Garden/LocationDecorTemplates/TwilightGroveDecor.model.json",
 "src/Workspace/Garden/LocationTemplates/CrystalGreenhouse.rbxm",
 "src/Workspace/Garden/LocationTemplates/StarterOrchard.rbxm",
 "src/Workspace/Garden/LocationTemplates/TwilightGrove.rbxm",
 "src/Workspace/Garden/GardenCenter.rbxm",
 "src/Workspace/SpawnLocation.rbxm",
]
for path in retired_paths:
    if (ROOT/path).exists():
        raise AssertionError(f"alpha-unneeded workspace asset returned: {path}")

for path in ("src/Workspace/Garden/GardenCenter.model.json","src/Workspace/SpawnLocation.model.json"):
    if not (ROOT/path).exists():
        raise AssertionError(f"invisible alpha marker missing: {path}")

print("world visual clutter contract: PASS")
print(f"Alpha world is sparse ({len(nodes)} authored nodes), flat on one gameplay Y plane, and free of retired scenery/template assets.")
