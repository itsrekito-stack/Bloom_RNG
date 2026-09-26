from pathlib import Path
import json

ROOT=Path(__file__).resolve().parents[2]
html=(ROOT/"tools/roflow/web/index.html").read_text(encoding="utf-8")
app=(ROOT/"tools/roflow/web/app.js").read_text(encoding="utf-8")
planner=json.loads((ROOT/"tools/roflow/planner-defaults.json").read_text(encoding="utf-8"))

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

for element_id in ("releaseGate","releaseGateState","releaseGateDetail","releaseGateBar"):
    need(html,f'id="{element_id}"',f"release gate {element_id}")

need(app,"const RELEASE_MANUAL_GATE_IDS=[","manual release prerequisite registry")
manual_ids=[
    "release-bug-zero",
    "release-publish-config",
    "release-store-page",
    "release-private-alpha",
    "release-rc-fixes",
]
for task_id in manual_ids:
    need(app,f'"{task_id}"',f"manual release prerequisite {task_id}")

for field in ("coreReady","persistenceReady","baselineReady","onboardingReady","multiplayerReady","soakReady"):
    need(app,f"runtime.{field}===true",f"runtime release prerequisite {field}")

need(app,"state.runtimeGate={coreReady,persistenceReady,baselineReady,onboardingReady,multiplayerReady,soakReady};","runtime evidence handoff")
need(app,'stateNode.textContent=ready?"READY FOR FINAL CHECKPOINT":"BLOCKED";',"release gate verdict")
need(app,"manualTasks.length===RELEASE_MANUAL_GATE_IDS.length","missing manual task fail-closed guard")

start=app.index("function renderReleaseGate(){")
end=app.index("function renderRuntimeProbe(report){",start)
gate_body=app[start:end]
if "planner_set_done" in gate_body:
    raise AssertionError("release gate must never auto-complete Planner tasks")

roadmap={task["id"]:task for task in planner["roadmap"]}
for task_id in manual_ids:
    if task_id not in roadmap:
        raise AssertionError(f"Planner is missing release prerequisite {task_id}")
    if roadmap[task_id].get("done") is not False:
        raise AssertionError(f"default Planner must keep manual prerequisite open: {task_id}")

print("PASS RoFlow final release gate is fail-closed and evidence-driven")
print("PASS release gate never auto-completes manual roadmap tasks")
