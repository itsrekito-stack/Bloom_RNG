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


# Eight fixed Workspace Garden lots replace procedural player-plot placement.
project=read("default.project.json")
assert '"GardenLots"' in project
for index in range(1,9):
    assert f'"GardenLot{index:02d}"' in project, f"GardenLot{index:02d} missing from Rojo tree"
assert project.count('"$ignoreUnknownInstances": true')>=10, "Garden lots must preserve manually inserted meshes"
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


# Direct mesh asset IDs are authored into the eight editable Workspace lots.
project_text=read("default.project.json")
assert "rbxassetid://89934665266567" in project_text, "Bee mesh asset id missing"
assert project_text.count("rbxassetid://93439308097157")==8, "Garden mesh must exist in all 8 lots"
assert project_text.count("rbxassetid://72906636471163")==8, "Hive mesh must exist in all 8 lots"
assert '"Bee"' in project_text
assert 'Assets.ApplyTextureFallback(root,key)' in garden
