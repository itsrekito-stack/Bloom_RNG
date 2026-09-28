#!/usr/bin/env python3
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]
def read(path): return (ROOT/path).read_text(encoding="utf-8")
def need(src,text,label):
    if text not in src:
        raise AssertionError(f"{label}: missing {text!r}")

cfg=read("src/ReplicatedStorage/Config/SeasonConfig.luau")
plan=read("src/ReplicatedStorage/Shared/SeasonPlan.luau")
service=read("src/ServerScriptService/Services/SeasonService.luau")
player=read("src/ServerScriptService/Services/PlayerService.luau")
bees=read("src/ReplicatedStorage/Config/BeesConfig.luau")

need(cfg,'Hive=8',"Season Hive threshold")
need(cfg,'Flowers=8',"Season flower threshold")
need(cfg,'Bees=5',"Season bee threshold")
need(cfg,'Trials=3',"Season trial threshold")
need(cfg,'TrialIds={"MeadowCircuit","SwiftRoute","CrystalTriangle"}',"Season base trials")

# Eligibility is fully server-derived.
need(service,'p.Hive.Level>=C.Hive',"Hive eligibility")
need(service,'completed>=C.Trials',"trial eligibility")
need(service,'self.X.U.Count(p.FlowerCollection.DiscoveredFlowers)>=C.Flowers',"flower eligibility")
need(service,'self.X.U.Count(p.Pollinators.DiscoveredBees)>=C.Bees',"bee eligibility")
need(service,'string.format("Season: Hive %d, %d key trials, %d flowers, %d bees",C.Hive,C.Trials,C.Flowers,C.Bees)',"config-driven requirement copy")
for stale in ("SunnyOrchard","CrystalGreenhouse","TwilightGrove"):
    if stale in service:
        raise AssertionError(f"Season eligibility still requires removed location: {stale}")

# Preview/confirm is a revision-bound two-step transaction.
need(service,'local token=Http:GenerateGUID(false)',"preview token")
need(service,'Revision=self.X.Revisions[player]',"preview revision")
need(service,'Expires=os.clock()+30',"preview expiry")
need(service,'Before=self.X.U.Copy(p)',"preview baseline")
need(service,'if not q or q.Token~=token or os.clock()>q.Expires then return false,"INVALID_VALUE" end',"confirm token/expiry")
need(service,'if q.Revision~=self.X.Revisions[player] or not self.X.U.Equal(q.Before,p) then',"stale preview detection")
need(service,'if q.Confirm==0 then q.Confirm=1 self.X:Send(player,"SeasonConfirm",token) return true end',"second confirmation")
need(service,'local result=self.X.DataService:CommitProfile(player,plan.After,token)',"transactional persistence")
need(service,'if result.Code~="SUCCESS" then',"commit failure handling")
need(player,'if self.SeasonService.Pending[player] and action~="SeasonConfirm" and action~="Menu" and action~="Ready" then return false,"SEASON_PREVIEW_OPEN" end',"preview mutation lock")

# Season reset remains immediately plantable while respecting the seven-slot cap.
need(plan,'UnlockedSlots=1',"Season reset preserves one usable Garden slot")
need(plan,'for i=1,C.MaxFlowerSlots do',"configured max Garden slots")
need(plan,'after.Garden.UnlockedSlots=math.max(after.Garden.UnlockedSlots,2)',"second Flower keepsake expands reset capacity safely")
need(plan,'after.Currencies.Coins=0',"Coin reset")
need(plan,'after.Currencies.AncientNectar=after.Currencies.AncientNectar+C.SeasonReward+E.Value(profile,"LEGACY_6","SeasonNectar",0)',"Ancient Nectar reward")
need(plan,'Level=1',"Hive level reset")
need(plan,'Honey=0',"Hive Honey reset")
need(plan,'TotalHoney=profile.Hive.TotalHoney',"lifetime Honey retained")
need(plan,'after.World.UnlockedSectors={Center=true}',"sector reset")
need(plan,'after.Season.Count=profile.Season.Count+1',"Season increment")
need(plan,'after.RollState.BloomCharge=0',"Bloom charge reset")
need(plan,'after.RollState.SpecialRollReady=false',"special roll reset")

# Workshop/Legacy behavior stays explicit and config-driven.
need(plan,'if not after.WorkshopV5.LegacyNodes[id] then',"permanent Legacy retention")
need(plan,'after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)',"non-permanent point refund")
need(plan,'after.Season.ActiveCard=profile.WorkshopV5.Nodes.LEGACY_1 and profile.Season.ActiveCard or ""',"Season card memory")
need(plan,'local memory=E.Value(profile,"LEGACY_2","MemoryMastery",0)',"Bee memory amount")
need(plan,'B.GetMasteryState(current+memory).TotalXP',"Bee memory cap")
need(bees,"function C.GetMasteryState(totalXP:number?):any","shared Bee Mastery cap")
need(plan,'Mutation=profile.WorkshopV5.Nodes.LEGACY_3 and profile.Season.Keepsakes.Flower and "Memory" or ""',"memory mutation")
need(plan,'if profile.WorkshopV5.Nodes.LEGACY_5 and profile.Season.Keepsakes.Flower2 then',"third memory gate")
need(plan,'E.Value(profile,"LEGACY_6","SeasonNectar",0)',"Season Scholar reward")

# Runtime cleanup cannot leak a previous Season's transient systems.
need(service,'self.X.GardenActivityService:CancelGarden(player)',"activity cleanup")
need(service,'self.X.BuildTrialService:Remove(player)',"trial cleanup")
need(service,'self.X.PollinatorService:Remove(player)',"pollinator runtime cleanup")
need(service,'self.X.GardenPlotService:Build(player)',"new Season garden rebuild")

# Retained cards are not followed by a fake choose-card ceremony.
need(service,'if plan.After.Season.ActiveCard=="" then',"card offer only when empty")
need(service,'self.X:Send(player,"Cards",self:Offers(plan.After))',"new card offers")
need(service,'self.X:Send(player,"Message","Season card retained: "..plan.After.Season.ActiveCard)',"retained-card feedback")
need(service,'if p.Season.Count<1 or p.Season.ActiveCard~="" or not table.find(self:Offers(p),id) then return false,"INVALID_ITEM" end',"card selection validation")

# Keepsakes are ownership/discovery-gated and the third memory requires its node.
need(service,'if kind=="Flower2" then if not p.WorkshopV5.Nodes.LEGACY_5 then return false,"LOCKED" end',"third keepsake gate")
need(service,'if not p.FlowerCollection.DiscoveredFlowers[id] then return false,"NOT_DISCOVERED" end',"flower keepsake validation")
need(service,'kind=="Bee" and p.Pollinators.DiscoveredBees[id]',"bee keepsake validation")

print("season / legacy contract: PASS")
print("Preview transaction, reset/retention semantics, Legacy memories, transient cleanup and card selection are server-authoritative.")
