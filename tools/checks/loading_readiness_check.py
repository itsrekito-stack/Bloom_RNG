#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]

def read(path):
    return (ROOT/path).read_text(encoding="utf-8")

def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

loading=read("src/ReplicatedFirst/LoadingScreen.client.luau")
bootstrap=read("src/StarterPlayer/StarterPlayerScripts/ClientBootstrap.client.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")

# Loading must be readiness-driven, never time-driven.
assert 'os.clock()-start<30' not in loading, "legacy 30-second loading bypass returned"
assert '"CONTINUING…"' not in loading, "loading screen may not continue into an unready game"
need(loading,'ContentProvider:PreloadAsync',"critical asset preload")
need(loading,'while gui.Parent and not ready do',"readiness gate loop")
need(loading,'player:GetAttribute("BloomProfileState")',"profile readiness gate")
need(loading,'player:GetAttribute("BloomGameplayReady")==true',"server gameplay readiness gate")
need(loading,'player:GetAttribute("BloomClientReady")==true',"client controller readiness gate")
need(loading,'player:GetAttribute("BloomStateReady")==true',"authoritative state/render readiness gate")
need(loading,'player:SetAttribute("BloomAssetsReady",true)',"asset readiness marker")
need(loading,'player:SetAttribute("BloomGameReady",true)',"final game readiness marker")
need(loading,'ContextActionService:BindActionAtPriority',"movement blocked while loading")
need(loading,'ContextActionService:UnbindAction(BLOCK_ACTION)',"movement restored after readiness")
need(loading,'stablePasses<2',"runtime asset discovery stabilization")
need(loading,'collectAssets(workspace,batch)',"loaded world assets included")
need(loading,'collectAssets(playerGui,batch)',"rendered UI assets included")
need(loading,'bootState=="Failed"',"client startup failure remains behind loading screen")
need(loading,'profileState=="RecoveryFailed"',"persistence failure remains behind loading screen")

# Client readiness distinguishes controller wiring from first real state/render.
need(bootstrap,'player:SetAttribute("BloomClientBootState","Starting")',"client boot start marker")
need(bootstrap,'player:SetAttribute("BloomClientBootState","Failed")',"client boot failure marker")
need(ui,'self.Player:SetAttribute("BloomStateReady",false)',"state starts unready")
need(ui,'self.Player:SetAttribute("BloomFirstRenderRevision",tonumber(payload.Revision) or 0)',"first render revision marker")
need(ui,'self.Player:SetAttribute("BloomStateReady",true)',"first authoritative render marker")
need(player,'player:SetAttribute("BloomGameplayReady",false)',"server gameplay starts unready")
need(player,'player:SetAttribute("BloomGameplayReady",true)',"server gameplay readiness marker")

print("loading readiness contract: PASS")
print("Loading stays up until profile, server runtime, client controllers, authoritative render and critical assets are ready.")
