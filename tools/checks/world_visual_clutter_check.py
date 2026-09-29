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
garden_ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/GardenPresentationController.luau")
activity=read("src/StarterPlayer/StarterPlayerScripts/Controllers/ActivityController.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
map_service=read("src/ServerScriptService/Services/MapService.luau")
garden_plot=read("src/ServerScriptService/Services/GardenPlotService.luau")
garden_layout=read("src/ReplicatedStorage/Config/GardenSynergyConfig.luau")
hub=json.loads(read("src/Workspace/FruitOrchardHub.model.json"))

# Existing world UI clutter guards stay intact.
need(flower,'info.Size = UDim2.fromOffset(142, 46)',"compact flower detail card")
need(flower,'info.MaxDistance = 28',"bounded flower detail distance")
need(flower,'info.Enabled = false',"flower cards start hidden")
need(garden_ui,'local FLOWER_DETAIL_DISTANCE=24',"nearest flower focus radius")
need(garden_ui,'descendant:IsA("BillboardGui") and descendant.Name=="FlowerInfo"',"FlowerInfo focus scan")
need(garden_ui,'for _,info in ipairs(infos) do info.Enabled=info==nearest end',"single detailed flower card")
need(garden_ui,'ui.Menu==nil and not ui:IsWorkshopExclusive()',"flower cards suppressed by menus")
need(activity,'billboard.MaxDistance=o.Tutorial and 90 or 58',"activity label default distance")
if 'Instance.new("Beam")' in garden_ui or 'LocalSynergyLines' in garden_ui:
    raise AssertionError("persistent garden synergy beam web returned")

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

# Player Garden prefers the authored mesh and keeps gameplay geometry invisible/subtle.
need(garden_plot,'local LOT_COUNT=8',"eight fixed Workspace Garden lots")
need(garden_plot,'local GARDEN_FOOTPRINT=32.5',"authored Garden target footprint")
need(garden_plot,'local HIVE_FOOTPRINT=5.2',"authored Hive target footprint")
need(garden_plot,'local BENCH_FOOTPRINT=5.8',"authored Bench target footprint")
need(garden_plot,'local authoredGarden=lotVisual(lot,"Garden")',"Garden lot reads the actual editable Garden mesh")
need(garden_plot,'local authoredHive=lotVisual(lot,"Hive")',"Garden lot reads the actual editable Hive mesh")
need(garden_plot,'local authoredBench=lotVisual(lot,"Bench")',"Garden lot reads the actual editable Bench mesh")
need(garden_plot,'plot.HasAuthoredGarden=gardenVisual~=nil',"authored Garden presentation flag")
need(garden_plot,'if not gardenVisual then',"fallback primitives only when authored Garden is absent")
need(garden_plot,'local hiveVisual=authoredHive',"authored Hive model is used directly")
need(garden_plot,'function S:AcquireLot(player)',"first free authored Garden lot assignment")
need(garden_plot,'plot.GardenCFrame:PointToWorldSpace(G.Position(slot))',"Flower slots follow authored lot transform")
need(garden_plot,'local hiveVisual=authoredHive',"Hive gameplay follows actual Workspace mesh")
need(garden_plot,'if not authoredBench and gardenVisual then',"Bench stays where authored in Workspace")
need(garden_plot,'plot.HivePosition=hivePosition',"gameplay Hive position follows authored visual")
need(garden_plot,'local collider=self.X:Part(m,"GardenCollider"', "invisible Garden gameplay collider")
need(garden_plot,'collider.Transparency=1',"Garden collider is presentation-invisible")
need(garden_plot,'local diameter=authored and 2.9 or 3.6',"authored Garden uses smaller slot markers")
need(garden_plot,'occupied and .92 or .80',"occupied/empty authored slot markers are restrained")
need(garden_plot,'unlocked and (occupied and .92 or .80) or 1',"ordinary locked authored slots are hidden")
need(garden_plot,'pad.CastShadow=false',"subtle authored slot markers cast no dark discs")
need(garden_plot,'for i=1,C.MaxFlowerSlots do',"all configured slots render")
need(garden_plot,'self.X.FlowerService.Build(i,f,pos)',"flower roots align exactly to slot position")
need(garden_plot,'self.X.FlowerService.ApplyLevelVisual(model,mastery.Level,growth)',"live Flower height follows Level")
need(garden_plot,'self.X.FlowerService.ApplyLevelVisual(flower,mastery.Level,growth)',"initial Flower height follows Level")
need(garden_plot,'function S:RefreshFlowerSpecies(player,id)',"planted Flower can refresh immediately after Level-up")
if 'FLOWER_SCALE_CAP' in garden_plot or 'flowerVisualScale' in garden_plot:
    raise AssertionError("Flower visual growth must not have a cap or uniform Model:ScaleTo helper")
need(garden_layout,'Radius=8.1',"compact slot ring radius")
need(garden_layout,'SlotY=.10',"slot surface micro-offset")
need(garden_layout,'function C.Position(i)',"deterministic shared slot layout")

for token in ("GardenBed","PlotBorder","HiveBand_","Tree","Lamp","Fence"):
    if token in garden_plot:
        raise AssertionError(f"alpha-unneeded Garden decoration returned: {token}")

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
print(f"Alpha world is sparse ({len(nodes)} authored nodes); player Garden is a flat, low-part circular gameplay asset with no beam/decor clutter.")


lots=json.loads(read("src/Workspace/GardenLots.model.json"))
garden_lots=[x for x in lots.get("Children",[]) if x.get("Name","").startswith("GardenLot")]
if len(garden_lots)!=8:
    raise AssertionError(f"expected 8 actual Workspace Garden lots, got {len(garden_lots)}")
for lot in garden_lots:
    names={x.get("Name") for x in lot.get("Children",[])}
    missing={"Garden","Hive","LotOrigin"}-names
    if missing:
        raise AssertionError(f"{lot.get('Name')} missing real gameplay meshes: {sorted(missing)}")
