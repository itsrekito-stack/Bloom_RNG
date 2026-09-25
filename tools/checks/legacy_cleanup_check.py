#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
SRC=ROOT/"src"

packages=SRC/"ReplicatedStorage"/"Packages"
react_wrapper=SRC/"ReplicatedStorage"/"Shared"/"ReactPackages.luau"
if packages.exists():
    raise AssertionError("dead ReplicatedStorage/Packages vendor tree returned")
if react_wrapper.exists():
    raise AssertionError("dead Shared/ReactPackages wrapper returned")

fruit_map=SRC/"Workspace"/"FruitOrchardHub.model.json"
mapping=SRC/"ServerScriptService"/"Data"/"LegacyBloomMapping.luau"
if not fruit_map.exists():
    raise AssertionError("active world geometry FruitOrchardHub.model.json was removed")
if not mapping.exists():
    raise AssertionError("required legacy profile migration mapping was removed")

research=[p for p in SRC.rglob("*") if "research" in p.name.lower()]
if research:
    raise AssertionError("dead Research source returned: "+", ".join(str(p.relative_to(ROOT)) for p in research[:8]))

bootstrap=(SRC/"StarterPlayer"/"StarterPlayerScripts"/"ClientBootstrap.client.luau").read_text(encoding="utf-8")
if "Controllers.BloomUI" not in bootstrap:
    raise AssertionError("authoritative BloomUI client bootstrap changed unexpectedly")
if "ReactPackages" in bootstrap or "ReactRoblox" in bootstrap:
    raise AssertionError("client bootstrap depends on retired React path")

print("legacy cleanup contract: PASS")
print("Retired React vendor path absent; active map and migration compatibility retained.")
