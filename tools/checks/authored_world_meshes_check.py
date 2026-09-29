#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

assets=read("src/ReplicatedStorage/Shared/AuthoredMeshTemplates.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
bees=read("src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau")
lots=json.loads(read("src/Workspace/GardenLots.model.json"))
bee=json.loads(read("src/Workspace/BloomBeeTemplate.model.json"))

for name in ("Bee","Garden","Hive","Bench"):
    assert name in assets, f"missing authored visual template key {name}"

assert 'Bee={"BloomBeeTemplate","Bee"}' in assets
assert 'Bench={"Bench","Curved Sandstone Benc","Curved Sandstone Bench"}' in assets
assert 'part:FindFirstChildOfClass("SurfaceAppearance") then return true' in assets
for forbidden in (".ColorMap", ".NormalMap", ".RoughnessMap", ".MetalnessMap"):
    assert forbidden not in assets, f"runtime must not read protected SurfaceAppearance property {forbidden}"

# Eight physical Workspace lots, each with actual Model -> MeshPart -> SurfaceAppearance.
lot_nodes=[x for x in lots.get("Children",[]) if x.get("Name","").startswith("GardenLot")]
assert len(lot_nodes)==8, f"expected 8 Garden lots, got {len(lot_nodes)}"

expected_mesh={
    "Garden":"rbxassetid://129177202413424",
    "Hive":"rbxassetid://81932595223184",
    "Bench":"rbxassetid://123879096199687",
}
expected_maps={
    "Garden":{
        "ColorMap":"rbxassetid://78412111995637",
        "NormalMap":"rbxassetid://136759550555690",
        "RoughnessMap":"rbxassetid://128004619420959",
        "MetalnessMap":"rbxassetid://105789290097643",
    },
    "Hive":{
        "ColorMap":"rbxassetid://76306025091711",
        "NormalMap":"rbxassetid://79842265130286",
        "RoughnessMap":"rbxassetid://126305584306389",
        "MetalnessMap":"rbxassetid://102368757888827",
    },
    "Bench":{
        "ColorMap":"rbxassetid://80716695702238",
        "NormalMap":"rbxassetid://83115535549013",
        "RoughnessMap":"rbxassetid://119534925989340",
        "MetalnessMap":"rbxassetid://71410551962327",
    },
}

for lot in lot_nodes:
    by_name={x.get("Name"):x for x in lot.get("Children",[])}
    assert {"Garden","Hive","Bench","LotOrigin"}<=set(by_name), f"{lot.get('Name')} incomplete"
    for key in ("Garden","Hive","Bench"):
        model=by_name[key]
        assert model.get("ClassName")=="Model", f"{lot.get('Name')}/{key} must be a Model"
        body=next((x for x in model.get("Children",[]) if x.get("ClassName")=="MeshPart"),None)
        assert body, f"{lot.get('Name')}/{key} missing MeshPart"
        props=body.get("Properties",{})
        assert props.get("MeshId")==expected_mesh[key], f"{lot.get('Name')}/{key} wrong mesh"
        assert props.get("Transparency")==0
        assert props.get("CanQuery") is True
        surface=next((x for x in body.get("Children",[]) if x.get("ClassName")=="SurfaceAppearance"),None)
        assert surface, f"{lot.get('Name')}/{key} missing SurfaceAppearance"
        sp=surface.get("Properties",{})
        for prop,value in expected_maps[key].items():
            assert sp.get(prop)==value, f"{lot.get('Name')}/{key} wrong {prop}"

bee_body=next((x for x in bee.get("Children",[]) if x.get("ClassName")=="MeshPart"),None)
assert bee.get("Name")=="BloomBeeTemplate" and bee_body
assert bee_body["Properties"]["MeshId"]=="rbxassetid://86695413882310"
bee_surface=next((x for x in bee_body.get("Children",[]) if x.get("ClassName")=="SurfaceAppearance"),None)
assert bee_surface
assert bee_surface["Properties"]["ColorMap"]=="rbxassetid://82885432584977"
assert bee_surface["Properties"]["NormalMap"]=="rbxassetid://78481603920082"
assert bee_surface["Properties"]["RoughnessMap"]=="rbxassetid://98327088756066"
assert bee_surface["Properties"]["MetalnessMap"]=="rbxassetid://81267734819459"

assert 'local authoredGarden=lotVisual(lot,"Garden")' in garden
assert 'local authoredHive=lotVisual(lot,"Hive")' in garden
assert 'local authoredBench=lotVisual(lot,"Bench")' in garden
assert 'plot.GardenCFrame:PointToWorldSpace(G.Position(slot))' in garden
assert 'function S:AcquireLot(player)' in garden

# Bee presentation contract.
assert 'Assets.Clone("Bee")' in bees
assert 'RunService.RenderStepped:Connect' in bees
assert 'CFrame.lookAt(position,position+direction,Vector3.yAxis)' in bees
assert 'spreadOffset(index,1.75)' in bees
assert 'spreadOffset(index,.58)' in bees
assert 'TweenService' not in bees

print("authored world model integration: PASS")
print("Garden/Hive/Bench/Bee are real models backed by mesh + SurfaceAppearance assets.")


# GardenLot01 is the only authored layout the developer needs to edit.
# At server start, GardenLot02-08 mirror its Garden/Hive/Bench relative transforms.
assert 'local MASTER_LOT_NAME="GardenLot01"' in garden
assert 'local function syncLotFromMaster(master,target)' in garden
assert 'local relative=masterOrigin.CFrame:ToObjectSpace(sourcePivot)' in garden
assert 'setObjectPivot(clone,targetOrigin.CFrame*relative)' in garden
assert 'lot~=master' in garden
