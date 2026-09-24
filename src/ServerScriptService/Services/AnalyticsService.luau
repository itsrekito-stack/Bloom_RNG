local RS=game:GetService("ReplicatedStorage") local C=require(RS.Config.AnalyticsConfig) local Analytics=game:GetService("AnalyticsService") local S={}
function S:Init(x) self.X=x end
function S:Event(player,event,n)
 local p=self.X:Profile(player) if not p then return end local t=p.Telemetry t.Counters[event]=(t.Counters[event] or 0)+n local name=C.Events[event]
 if name and not t.Once[name] then t.Once[name]=true if C.Enabled then task.spawn(function() pcall(function() Analytics:LogCustomEvent(player,name,1) end) end) end end
end
function S:Flush(player)
 local metrics=self:Snapshot(player) if not C.Enabled then return end
 task.spawn(function() for _,name in ipairs({"active_world_seconds","menu_open_seconds","idle_seconds","rolls_per_minute","auto_roll_share","activity_engagement","bloom_roll_frequency","garden_diversity","synergy_diversity","average_event_distance"}) do pcall(function() Analytics:LogCustomEvent(player,name,metrics[name] or 0) end) end end)
end
function S:Tick(player,dt)
 local p=self.X:Profile(player) local t=self.X.Temp[player] local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart") local moving=root and root.AssemblyLinearVelocity.Magnitude>1
 if os.clock()>=(t.NextFlush or 0) then t.NextFlush=os.clock()+C.FlushSeconds self:Flush(player) end
 local zone=self.X.MapService:Sector(player)
 if zone~="Center" and not p.Telemetry.Counters["time_to_"..zone] then p.Telemetry.Counters["time_to_"..zone]=(p.Telemetry.Counters.active_world_seconds or 0)+(p.Telemetry.Counters.idle_seconds or 0)+(p.Telemetry.Counters.menu_open_seconds or 0) end
 if self.X.SeasonService:Eligible(p) and not p.Telemetry.Counters.season_eligibility_time then p.Telemetry.Counters.season_eligibility_time=(p.Telemetry.Counters.active_world_seconds or 0)+(p.Telemetry.Counters.idle_seconds or 0)+(p.Telemetry.Counters.menu_open_seconds or 0) end
 local key=t.MenuOpen and "menu_open_seconds" or moving and "active_world_seconds" or "idle_seconds" p.Telemetry.Counters[key]=(p.Telemetry.Counters[key] or 0)+dt
 local hive=self.X.GardenPlotService:HivePosition(player) local counters=p.Telemetry.Counters
 if root and hive and self.X.SocialService.Pulse then counters.event_distance_sum=(counters.event_distance_sum or 0)+(root.Position-hive).Magnitude counters.event_distance_samples=(counters.event_distance_samples or 0)+1 end
 if root and hive and (root.Position-hive).Magnitude>35 then p.Telemetry.Counters.outside_plot_seconds=(p.Telemetry.Counters.outside_plot_seconds or 0)+dt end
end
function S:Snapshot(player)
 local p=self.X:Profile(player) if not p then return {} end local c=self.X.U.Copy(p.Telemetry.Counters) local seconds=(c.active_world_seconds or 0)+(c.menu_open_seconds or 0)+(c.idle_seconds or 0)
 c.rolls_per_minute=(c.Roll or 0)*60/math.max(1,seconds) c.auto_roll_share=(c.AutoRoll or 0)/math.max(1,c.Roll or 0) c.activity_engagement=(c.ActivityEngaged or 0)/math.max(1,c.ActivityOffered or 0) c.bloom_roll_frequency=(c.BloomRoll or 0)*60/math.max(1,seconds)
 c.average_event_distance=(c.event_distance_sum or 0)/math.max(1,c.event_distance_samples or 0)
 local species={} for _,slot in ipairs(p.Garden.Slots) do if slot.SpeciesId then species[slot.SpeciesId]=true end end c.garden_diversity=self.X.U.Count(species) c.synergy_diversity=self.X.U.Count(self.X.GardenSynergyService.Active[player])
 local traits=require(RS.Config.BeesConfig).GetTraitCounts(p.Pollinators.EquippedBeeSlots) traits._total=nil c.bee_trait_diversity=self.X.U.Count(traits)
 return c
end
return S
