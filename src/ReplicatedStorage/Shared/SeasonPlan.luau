local RS=game:GetService("ReplicatedStorage")
local U=require(RS.Shared.BloomUtil)
local C=require(RS.Config.BloomConfig)
local W=require(RS.Config.WorkshopConfig)
local B=require(RS.Config.BeesConfig)
local E=require(RS.Shared.WorkshopEffects)

local S={}

function S.BuildSeasonTurnPlan(profile)
 local before=U.Copy(profile)
 local after=U.Copy(profile)

 after.Currencies.Coins=0
 local seasonNectar=C.SeasonReward+E.Value(profile,"LEGACY_6","SeasonNectar",0)
 seasonNectar=math.max(1,math.floor(seasonNectar*E.BranchProduct(profile,"SEASON","SeasonRewardMultiplier",1)+.5))
 after.Currencies.AncientNectar=after.Currencies.AncientNectar+seasonNectar

 after.Hive={
  Level=1,
  Honey=0,
  TotalHoney=profile.Hive.TotalHoney,
 }

 after.Garden={
  UnlockedSlots=1,
  Slots={},
  Revision=profile.Garden.Revision+1,
 }
 for i=1,C.MaxFlowerSlots do
  after.Garden.Slots[i]={}
 end

 local flower=profile.Season.Keepsakes.Flower or "Daisy"
 after.FlowerCollection.OwnedSeedCopies[flower]=math.max(1,after.FlowerCollection.OwnedSeedCopies[flower] or 0)
 after.Garden.Slots[1]={
  SpeciesId=flower,
  Mutation=profile.WorkshopV5.Nodes.LEGACY_3 and profile.Season.Keepsakes.Flower and "Memory" or "",
  TotalPollination=0,
 }

 after.World.UnlockedSectors={Center=true}
 after.Season.Count=profile.Season.Count+1
 after.Season.ActiveCard=profile.WorkshopV5.Nodes.LEGACY_1 and profile.Season.ActiveCard or ""
 after.Season.CompletedGoals={}

 after.RollState.BloomCharge=0
 after.RollState.SpecialRollReady=false

 for id in pairs(after.WorkshopV5.Nodes) do
  if not after.WorkshopV5.LegacyNodes[id] then
   local node=W.Nodes[id]
   after.WorkshopV5.Nodes[id]=nil
   after.WorkshopV5.Points=after.WorkshopV5.Points+(node and node.Cost or 0)
  end
 end

 local bee=profile.Season.Keepsakes.Bee or "WorkerBee"
 after.Pollinators.BeeInventory[bee]=math.max(1,after.Pollinators.BeeInventory[bee] or 0)
 after.Pollinators.EquippedBeeSlots={bee}

 if profile.WorkshopV5.Nodes.LEGACY_2 and profile.Season.Keepsakes.Bee then
  local current=tonumber(after.Pollinators.BeeMastery[bee]) or 0
  local memory=E.Value(profile,"LEGACY_2","MemoryMastery",0)
  after.Pollinators.BeeMastery[bee]=B.GetMasteryState(current+memory).TotalXP
 end

 if profile.WorkshopV5.Nodes.LEGACY_5 and profile.Season.Keepsakes.Flower2 then
  local id=profile.Season.Keepsakes.Flower2
  after.FlowerCollection.OwnedSeedCopies[id]=math.max(id==flower and 2 or 1,after.FlowerCollection.OwnedSeedCopies[id] or 0)
  after.Garden.Slots[2]={
   SpeciesId=id,
   Mutation="Memory",
   TotalPollination=0,
  }
  after.Garden.UnlockedSlots=math.max(after.Garden.UnlockedSlots,2)
 end

 after.StarterBeeGranted=true

 local diff={}
 local function walk(a,b,path)
  if type(a)=="table" and type(b)=="table" then
   local keys={}
   for k in pairs(a) do keys[k]=true end
   for k in pairs(b) do keys[k]=true end
   local ordered={}
   for k in pairs(keys) do table.insert(ordered,k) end
   table.sort(ordered,function(x,y) return tostring(x)<tostring(y) end)
   for _,k in ipairs(ordered) do
    walk(a[k],b[k],path.."."..tostring(k))
   end
  elseif a~=b then
   table.insert(diff,{Path=path,Before=U.Copy(a),After=U.Copy(b)})
  end
 end

 walk(before,after,"Profile")
 return {Before=before,After=after,Diff=diff}
end

return S
