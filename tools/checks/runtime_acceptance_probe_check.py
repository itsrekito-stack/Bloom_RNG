from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
server=(ROOT/"src/ServerScriptService/RuntimeAcceptanceProbe.server.luau").read_text(encoding="utf-8")
client=(ROOT/"src/StarterPlayer/StarterPlayerScripts/RuntimeAcceptanceProbe.client.luau").read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

for src,label in ((server,"server"),(client,"client")):
    need(src,'if not RunService:IsStudio() then return end',f"{label} Studio gate")
    need(src,'REPORT_CHECKPOINTS={60,600,900,1800,3600}',f"{label} checkpoint schedule")
need(server,'#session.SecondFrameMs>3600',"server bounded sample history")
need(client,'#secondFrameMs>3600',"client bounded sample history")

need(server,'Data:GetProfile(player)',"authoritative profile observation")
need(server,'Data:GetPersistenceStatus(player)',"persistence observation")
need(server,'MILESTONE_ORDER={"Profile","Roll","FlowerReward","Garden","Bee","Hive","Workshop"}',"core-loop milestones")
need(server,'[RuntimeProbe][Server] MILESTONE',"server milestone output")
need(server,'frame_p95=',"server frame percentile")
need(server,'memory=%.1fMB',"server memory output")

need(client,'RunService.RenderStepped:Connect',"client render sampling")
need(client,'Stats:GetTotalMemoryUsageMb()',"client total memory")
need(client,'ui_instances=%d',"client UI instance count")
need(client,'DataReceiveKbps',"client receive metric")
need(client,'DataSendKbps',"client send metric")
need(client,'input=k%d/m%d/t%d/w%d',"client input counters")

for forbidden in (
    'DataStoreService','UpdateAsync','SetAsync','IncrementAsync','RemoveAsync',
    ':Send("',':FireServer(',':InvokeServer('
):
    if forbidden in server or forbidden in client:
        raise AssertionError(f"runtime probe must remain read-only: {forbidden}")

print("PASS Studio runtime acceptance probes are Studio-gated, bounded and read-only")
print("Covered evidence: core-loop milestones, frame time, memory, UI instance count, network counters and input activity.")
