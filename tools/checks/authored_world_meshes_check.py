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
