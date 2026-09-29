#!/usr/bin/env python3
from pathlib import Path
import re

ROOT=Path(__file__).resolve().parents[2]
workshop=(ROOT/"src/ReplicatedStorage/Config/WorkshopConfig.luau").read_text(encoding="utf-8")
validation=(ROOT/"src/ServerScriptService/Tests/ConfigValidation.luau").read_text(encoding="utf-8")

assert "NodesPerBranch=6" in workshop
assert "Workshop must contain 43 nodes" not in validation
assert "expectedWorkshopCount=1+#W.Branches*W.NodesPerBranch" in validation
assert "branchCounts[branch]==W.NodesPerBranch" in validation

m=re.search(r"Branches=\{(.*?)\n \},\n Tree=", workshop, re.S)
assert m, "Workshop branch list not found"
branches=re.findall(r'"([A-Z]+)"',m.group(1))
assert len(branches)==27, f"Expected 27 Workshop branches, found {len(branches)}"
assert 1+len(branches)*6==163
print("Workshop ConfigValidation contract: PASS (27 branches x 6 + CORE = 163)")
