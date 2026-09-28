#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src: raise AssertionError(f"{label}: missing {text!r}")

pool=read("src/ReplicatedStorage/Config/RollPoolConfig.luau")
roll=read("src/ServerScriptService/Services/RollService.luau")
inventory=read("src/ServerScriptService/Services/InventoryService.luau")
ui=read("src/StarterPlayer/StarterPlayerScripts/Controllers/BloomUI.luau")
remote=read("src/ServerScriptService/Services/RemoteService.luau")

need(pool,'p.RollState.DiscoveryPity+1>=C.DiscoveryThreshold',"pity threshold comes from BloomConfig")
need(pool,'v.Undiscovered and (R.Rank[v.Rarity] or math.huge)<=cap',"pity only guarantees a protected-tier undiscovered result")
need(pool,'if #new>0 then pool=new end',"pity leaves natural pool intact when protected discoveries are exhausted")
need(pool,'if total<=0 then return {},0 end',"empty/zero-weight pool guard")
need(pool,'temp=temp or {}',"roll pool tolerates missing temporary runtime state")
need(roll,'os.clock()-(self.Last[player] or -100)<cd',"server roll cooldown")
need(roll,'local target=rng:NextNumber()*total',"server-side reward selection")
need(roll,'self.X.InventoryService:Grant(player,item.Kind,item.Id)',"server grants authoritative reward")
need(roll,'math.min(C.DiscoveryThreshold,p.RollState.DiscoveryPity+1)',"bounded pity counter")
need(roll,'math.clamp(reserve,0,math.max(0,C.BloomMax-1))',"consumed Bloom roll reserve stays below ready threshold")
need(roll,'IsSpecialRoll=special',"reward payload identifies consumed special roll")
need(inventory,'f.ObtainedFlowers[id]=(f.ObtainedFlowers[id] or 0)+1',"Flower rolls track obtained count")
need(inventory,'self.X.FlowerProgressionService:AddDuplicate(player,id,1)',"Flower duplicates advance species Level")
need(inventory,'pollinators.BeeObtained[id]=(pollinators.BeeObtained[id] or 0)+1',"Bee rolls track obtained count")
need(inventory,'self.X.PollinatorService:AddMastery(player,id,C.BeeDuplicateXP)',"Bee duplicates advance species Mastery")
need(remote,'integer(b,1,2147483647)',"roll request correlation id validated")
need(ui,'local BloomConfig=require(RS.Config.BloomConfig)',"HUD reads roll thresholds from shared config")
need(ui,'tonumber(BloomConfig.BloomMax)',"HUD Bloom meter uses configured max")
if 'DISCOVERY' in ui or 'DiscoveryThreshold' in ui:
    raise AssertionError("Discovery pity must stay hidden from the player-facing Bloom HUD")
need(ui,'self:FindRouletteTarget(payload)',"roulette lands on server result")
need(pool,'function S.FormatOddsNumber(n)',"whole-number player-facing odds formatter")
need(ui,'RollPool.FormatOddsNumber(odds)',"roulette uses shared rounded odds")
need(ui,'function UI:PrepareRouletteLandingTarget(targetIndex,stepCount)',"landing target prepared without reel jump")
need(ui,'self:PrepareRouletteLandingTarget(target,#steps)',"settle sequence prepositions reward")
need(ui,'function UI:StepRoulette(duration,generation)',"roulette step is sequential only")
assert 'self.RouletteCursor=((targetIndex-2)%#pool)+1' not in ui, "roulette must not jump the cursor before landing"
need(ui,'local controlsVisible=rollUnlocked and self.Menu==nil',"menus hide roll controls only")
need(ui,'self.RouletteViewport.Visible=rollUnlocked and',"roulette remains below open menus")
assert 'if payload.Action=="Roll" and self.Auto' not in ui, "server roll rejection must not silently stop auto-roll"
need(ui,'Normal roll rewards are shown only by the roulette itself.',"normal roll has no duplicate RewardReveal")

print("roll / bloom / pity contract: PASS")
print("Server reward selection, pity guarantee, Bloom consumption and roulette landing are correlated.")
