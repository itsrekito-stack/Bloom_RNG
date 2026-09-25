local C=require(game:GetService("ReplicatedStorage").Config.BloomConfig) local S={}
function S:Init(x) self.X=x end
function S:Interact(player)
 local p=self.X:Profile(player) if not p then return false end
 if not p.StarterBeeGranted then p.StarterBeeGranted=true self.X.InventoryService:Grant(player,"Bee","WorkerBee") p.Pollinators.EquippedBeeSlots[1]="WorkerBee" self.X:Emit(player,"StarterBee",1) return true end
 local cost=C.HiveCosts[p.Hive.Level+1] if not cost then return false end
 if p.Hive.Honey<cost then self.X:Send(player,"Message","Honey required: "..cost) return false end
 p.Hive.Honey=p.Hive.Honey-cost p.Hive.Level=p.Hive.Level+1
 self.X.WorkshopService:Point(player,"Hive_"..p.Season.Count.."_"..p.Hive.Level,2)
 self.X.GardenPlotService:RefreshCapacity(player) self.X:Emit(player,"HiveUpgrade",1) self.X:Send(player,"Ceremony",{Kind="Hive",Text="Hive level "..p.Hive.Level}) return true
end
return S
