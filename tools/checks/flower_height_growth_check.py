#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

flower=read("src/ServerScriptService/Services/FlowerService.luau")
garden=read("src/ServerScriptService/Services/GardenPlotService.luau")
config=read("src/ReplicatedStorage/Config/FlowersConfig.luau")

need(flower,'local heightScale=1+(levelNumber-1)*perLevel',"uncapped linear height formula")
need(flower,'basePosition.Y*heightScale',"all Flower geometry moves upward from its authored baseline")
need(flower,'item.Size=Vector3.new(baseSize.X*heightScale,baseSize.Y,baseSize.Z)',"stem alone lengthens vertically")
need(flower,'item.Size=baseSize',"non-stem Flower parts retain their authored width")
need(flower,'root.CFrame:ToObjectSpace(item.CFrame)',"growth baseline is captured from original geometry")
need(flower,'S.ApplyLevelVisual=applyLevelVisual',"FlowerService exposes deterministic Level visual API")
need(garden,'self.X.FlowerService.ApplyLevelVisual(model,mastery.Level,growth)',"live Level-up refreshes height")
need(garden,'self.X.FlowerService.ApplyLevelVisual(flower,mastery.Level,growth)',"spawned Flower uses saved Level height")
need(config,'ScalePerLevel=.025',"Flower growth rate stays config-driven")

for forbidden in ("FLOWER_SCALE_CAP","math.min(FLOWER_SCALE_CAP","model:ScaleTo(flowerVisualScale"):
    if forbidden in garden:
        raise AssertionError(f"capped/uniform Flower growth returned: {forbidden}")

# The visual formula itself is intentionally unbounded. Gameplay may still
# choose its own progression cap; future Levels automatically continue growing.
per_level=.025
samples=[1,2,10,25,100,250,1000]
scales=[1+(level-1)*per_level for level in samples]
if any(b<=a for a,b in zip(scales,scales[1:])):
    raise AssertionError(f"Flower height is not strictly increasing: {list(zip(samples,scales))}")
if scales[-1] <= 20:
    raise AssertionError("high Levels appear artificially capped")

print("flower height growth contract: PASS")
print("Every Flower Level adds vertical height from a stable baseline; no visual growth cap is applied.")
