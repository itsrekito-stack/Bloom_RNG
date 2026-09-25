#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[2]
DATA_CONFIG = ROOT / "src/ServerScriptService/Data/DataConfig.luau"
MANIFEST = ROOT / "src/ReplicatedStorage/Config/ReleaseContentManifest.luau"
PROJECT = ROOT / "default.project.json"

def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")

def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)

data = read(DATA_CONFIG)
manifest = read(MANIFEST)
project = json.loads(read(PROJECT))

def config_string(name: str) -> str:
    match = re.search(rf'DataConfig\.{re.escape(name)}\s*=\s*"([^"]+)"', data)
    require(match is not None, f"{name} missing from DataConfig")
    return match.group(1)

production_store = config_string("ProductionStoreName")
studio_store = config_string("StudioStoreName")

require(production_store != studio_store, "production and Studio DataStore names must differ")
for marker in ("test", "studio", "dev", "qa"):
    require(marker not in production_store.lower(), f"production DataStore contains non-production marker: {marker}")
require("test" in studio_store.lower(), "Studio DataStore should remain visibly test-only")

require("RunService:IsStudio()" in data, "DataStore selection must be environment-aware")
require("return DataConfig.StudioStoreName" in data, "Studio branch must return StudioStoreName")
require("return DataConfig.ProductionStoreName" in data, "non-Studio branch must return ProductionStoreName")

runtime_hits = []
for path in (ROOT / "src").rglob("*.luau"):
    if path == DATA_CONFIG:
        continue
    text = read(path)
    if studio_store in text:
        runtime_hits.append(path.relative_to(ROOT).as_posix())
require(not runtime_hits, f"Studio/test DataStore literal leaked into runtime source: {runtime_hits}")

tree = project.get("tree", {})
require(project.get("name") == "Bloom RNG", "default.project.json must build Bloom RNG")
workspace = tree.get("Workspace", {}).get("$properties", {})
require(workspace.get("StreamingEnabled") is True, "release project must keep StreamingEnabled=true")
require(tree.get("TextChatService", {}).get("$properties", {}).get("ChatVersion") == "TextChatService",
        "release project must keep TextChatService enabled")

require(re.search(r'\bVersion\s*=\s*1\b', manifest) is not None, "release manifest Version=1 missing")
require('ReleaseId="BloomRNG-v1"' in manifest, "release manifest id must remain BloomRNG-v1")
require("LegacyFruitsShipping=false" in manifest, "legacy fruit content must stay excluded from v1")

print("static release preflight: PASS")
print(f"production DataStore: {production_store}")
print(f"Studio DataStore: {studio_store}")
print("project: Bloom RNG / StreamingEnabled / TextChatService")
print("release manifest: BloomRNG-v1")
