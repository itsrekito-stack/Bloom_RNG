from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
path=ROOT/"src/ServerScriptService/PersistenceProbe.server.luau"
text=path.read_text()

required=[
    'RunService:IsStudio()',
    '[PersistenceProbe] JOIN',
    '[PersistenceProbe] LEAVE',
    'BloomPersistenceDigest',
    'Data:GetProfile(player)',
    'Data:GetPersistenceStatus(player)',
]
for token in required:
    assert token in text, f"persistence probe missing {token!r}"

for forbidden in ('DataStoreService','UpdateAsync','SetAsync','IncrementAsync','RemoveAsync'):
    assert forbidden not in text, f"Studio probe must not write DataStore directly: {forbidden}"

assert text.index('if not RunService:IsStudio() then return end') < text.index('local Players='), "Studio gate must run before player wiring"
print("PASS Studio persistence probe is read-only, Studio-gated, and emits join/leave digests")
