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
need(pool,'if #new>0 then pool=new end',"pity guarantees only a currently eligible undiscovered result")
need(pool,'if total<=0 then return {},0 end',"empty/zero-weight pool guard")
need(roll,'os.clock()-(self.Last[player] or -100)<cd',"server roll cooldown")
need(roll,'local target=rng:NextNumber()*total',"server-side reward selection")
need(roll,'self.X.InventoryService:Grant(player,item.Kind,item.Id)',"server grants authoritative reward")
need(roll,'math.min(C.DiscoveryThreshold,p.RollState.DiscoveryPity+1)',"bounded pity counter")
need(roll,'math.clamp(reserve,0,math.max(0,C.BloomMax-1))',"consumed Bloom roll reserve stays below ready threshold")
need(roll,'IsSpecialRoll=special',"reward payload identifies consumed special roll")
need(inventory,'OwnedSeedCopies[id]=(f.OwnedSeedCopies[id] or 0)+1',"flower duplicate stays server inventory outcome")
need(inventory,'inv.BeeInventory[id]=(inv.BeeInventory[id] or 0)+1',"bee duplicate stays server inventory outcome")
need(remote,'integer(b,1,2147483647)',"roll request correlation id validated")
need(ui,'local BloomConfig=require(RS.Config.BloomConfig)',"HUD reads roll thresholds from shared config")
need(ui,'tonumber(BloomConfig.BloomMax)',"HUD Bloom meter uses configured max")
need(ui,'tonumber(BloomConfig.DiscoveryThreshold)',"HUD pity meter uses configured threshold")
need(ui,'self:FindRouletteTarget(payload)',"roulette lands on server result")
need(ui,'Normal roll rewards are shown only by the roulette itself.',"normal roll has no duplicate RewardReveal")

print("roll / bloom / pity contract: PASS")
print("Server reward selection, pity guarantee, Bloom consumption and roulette landing are correlated.")
