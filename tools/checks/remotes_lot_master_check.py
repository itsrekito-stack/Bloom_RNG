#!/usr/bin/env python3
from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
remote_model=ROOT/"src/ReplicatedStorage/BloomRemotes.model.json"
remote_service=(ROOT/"src/ServerScriptService/Services/RemoteService.luau").read_text(encoding="utf-8")
ui=(ROOT/"src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau").read_text(encoding="utf-8")
garden=(ROOT/"src/ServerScriptService/Services/GardenPlotService.luau").read_text(encoding="utf-8")

model=json.loads(remote_model.read_text(encoding="utf-8"))
assert model["ClassName"]=="Folder" and model["Name"]=="BloomRemotes"
children={c["Name"]:c["ClassName"] for c in model.get("Children",[])}
assert children=={"Request":"RemoteEvent","Event":"RemoteEvent","StateRequest":"RemoteFunction"}

assert 'local old=RS:FindFirstChild("BloomRemotes") if old then old:Destroy() end' not in remote_service
assert 'ensureRemote(folder,"RemoteEvent","Request")' in remote_service
assert 'ensureRemote(folder,"RemoteFunction","StateRequest")' in remote_service
assert 'RS:WaitForChild("BloomRemotes",10)' in ui
assert 'BloomRemotes contract incomplete' in ui

assert 'MASTER_LOT_NAME="GardenLot01"' in garden
assert 'for _,child in ipairs(target:GetChildren()) do' in garden
assert 'if child~=targetOrigin then child:Destroy() end' in garden
assert 'for _,source in ipairs(master:GetChildren()) do' in garden
assert 'if source~=masterOrigin then' in garden
assert 'rebaseClone(source,clone,masterOrigin,targetOrigin)' in garden
print("Bloom remotes + GardenLot01 master contract: PASS")
