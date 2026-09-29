#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

assets=read("src/ReplicatedStorage/Shared/AuthoredMeshTemplates.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
bees=read("src/StarterPlayer/StarterPlayerScripts/Controllers/PollinatorController.luau")

for name in ("Bee","Garden","Hive","Bench"):
    assert name in assets, f"missing authored mesh template key {name}"

assert 'Assets.CaptureWorkspace()' in player
assert 'candidate:FindFirstChild("GardenCenter",true)' in player
assert 'usableVisual("Garden"' in garden
assert 'usableVisual("Hive"' in garden
assert 'usableVisual("Bench"' in garden
assert 'GardenCollider' in garden
assert 'Assets.Clone("Bee")' in bees
assert 'BloomFallbackVisual' in assets
assert 'SurfaceAppearance' in assets
assert 'function A.FaceAt(root,target,yawOffset)' in assets
assert 'safeContentProperty' in assets
assert 'part:FindFirstChildOfClass("SurfaceAppearance") then return true' in assets
for forbidden in (".ColorMap", ".NormalMap", ".RoughnessMap", ".MetalnessMap"):
    assert forbidden not in assets, f"server mesh scan must not read capability-protected SurfaceAppearance property {forbidden}"

print("authored world mesh integration: PASS")
print("Workspace mesh templates are captured safely, cloned into runtime visuals, and missing textures receive a material/color fallback.")


# Authored Bee presentation must face its path and animate smoothly without
# one-second positional tweens.
assert 'local BEE_FORWARD_FIX=CFrame.Angles(0,math.rad(90),0)' in bees
assert 'RunService.RenderStepped:Connect' in bees
assert 'CFrame.lookAt(position,position+direction,Vector3.yAxis)' in bees
assert 'estimatedPhase(frame,packet.ReceivedAt,now)' in bees
assert 'spreadOffset(index,1.75)' in bees
assert 'math.sin(now*BOB_SPEED+seed)*BOB_AMOUNT' in bees
assert 'animateWings(item,now)' in bees
assert 'string.find(lower,"wing",1,true)' in bees
assert 'TweenService' not in bees and 'Tween:Create' not in bees

assert 'ScaleToMaxDimension(template,2.1)' in bees
assert 'spreadOffset(index,.58)' in bees


# Workspace authoring contract: imported source meshes remain editable in Workspace
# and runtime clones preserve their authored relative transforms.
assert 'ServerStorage' not in assets
assert 'source.Parent=sources' not in assets
assert 'source.Name="_BloomSource_"' not in assets
assert 'hideAuthoringSource(source)' in assets
assert 'source:SetAttribute("BloomLayoutRole",key)' in assets
assert 'clone:SetAttribute("BloomSourcePivot",sourcePivot)' in assets
assert 'function A.AuthoredRelative(key,anchorKey,targetAnchorFootprint)' in assets
assert 'function A.PlaceRelative(root,anchorRoot,relative)' in assets
assert 'Assets.AuthoredRelative(key,"Garden",anchorFootprint)' in garden
assert 'Assets.PlaceRelative(visual,anchorVisual,relative)' in garden
assert 'plot.HivePosition=hivePosition' in garden
assert 'HIVE_INSET' not in garden
assert 'BENCH_RADIUS' not in garden
assert 'BENCH_ANGLE' not in garden
assert 'Assets.FaceAt(bench,origin)' not in garden


# Eight fixed Workspace Garden lots are a real Workspace model, not virtual project children.
import json
lots_path=ROOT/"src/Workspace/GardenLots.model.json"
assert lots_path.exists(), "GardenLots.model.json missing"
lots_data=json.loads(lots_path.read_text(encoding="utf-8"))
lots=[x for x in lots_data.get("Children",[]) if x.get("Name","").startswith("GardenLot")]
assert len(lots)==8, f"expected 8 actual Garden lots, got {len(lots)}"
for lot in lots:
    names={x.get("Name") for x in lot.get("Children",[])}
    assert {"Garden","Hive","LotOrigin"}<=names, f"{lot.get('Name')} missing real Garden/Hive/LotOrigin"
assert 'LOT_COUNT=8' in garden
assert 'function S:AcquireLot(player)' in garden
assert 'local authoredGarden=lotVisual(lot,"Garden")' in garden
assert 'local authoredHive=lotVisual(lot,"Hive")' in garden
assert 'local authoredBench=lotVisual(lot,"Bench")' in garden
assert 'local gardenCF=authoredGarden and visualCFrame(authoredGarden) or lotOrigin.CFrame' in garden
assert 'plot.GardenCFrame:PointToWorldSpace(G.Position(slot))' in garden
assert 'local lot,i=self:AcquireLot(player)' in garden
assert 'math.floor((i-1)/12)' not in garden
assert 'self.X.Origin+Vector3.new(math.cos(a)*r' not in garden
assert 'GardenAnchor' not in garden
assert 'HiveAnchor' not in garden
assert 'BenchAnchor' not in garden
assert 'function A.PlaceAtAnchor(root,anchorCFrame,alignBottom)' in assets


# Direct Garden/Hive mesh asset IDs are authored into the real Workspace lot model.
lots_text=read("src/Workspace/GardenLots.model.json")
assert lots_text.count("rbxassetid://93439308097157")==8, "Garden mesh must exist in all 8 lots"
assert lots_text.count("rbxassetid://72906636471163")==8, "Hive mesh must exist in all 8 lots"
assert 'Assets.ApplyTextureFallback(root,key)' in garden


# Each editable gameplay lot keeps the Hive outside the Garden rim.
lots_node={x["Name"]:x for x in lots_data.get("Children",[])}
for i in range(1,9):
    lot=lots_node[f"GardenLot{i:02d}"]
    parts={x["Name"]:x for x in lot.get("Children",[])}
    garden_cf=parts["Garden"]["Properties"]["CFrame"]
    hive_cf=parts["Hive"]["Properties"]["CFrame"]
    dx=hive_cf[0]-garden_cf[0]
    dz=hive_cf[2]-garden_cf[2]
    distance=(dx*dx+dz*dz)**0.5
    assert distance>=20.0, f"GardenLot{i:02d} Garden/Hive spacing too small: {distance:.2f}"
