local RS=game:GetService("ReplicatedStorage")
local T=require(RS.Config.TutorialConfig)

local S={}

function S:Init(ui,visualGuide)
 self.UI=ui
 self.Visual=visualGuide
end

function S:IsSolarBloomStep()
 local ui=self.UI
 local p=ui and ui.State and ui.State.Profile
 return p
  and not ui.ReplayIndex
  and p.Tutorial.Step>#T.Steps
  and (p.Quests.JourneyStep or 1)==15
end

function S:SolarBloomTarget()
 local activities=self.UI and self.UI.Activities
 if not activities or not activities.TargetKind then return nil,nil,nil end
 return activities:TargetKind("SolarBloom")
end

function S:RenderObjective()
 if not self:IsSolarBloomStep() then return false end
 local ui=self.UI
 local _,index,count=self:SolarBloomTarget()
 if index and count then
  ui.ObjectiveText.Text=string.format("Solar Bloom  •  Touch sphere %d/%d",index,count)
  ui.ObjectiveProgress.Visible=true
  ui.ObjectiveProgressFill.Size=UDim2.fromScale(math.clamp((index-1)/math.max(1,count),0,1),1)
 else
  ui.ObjectiveText.Text="Activate Solar Bloom in Sunny Orchard"
  ui.ObjectiveProgress.Visible=false
 end
 return true
end

function S:Update()
 if not self:IsSolarBloomStep() then return false end
 local ui=self.UI
 local visual=self.Visual
 if not visual then return false end

 local token,index,count=self:SolarBloomTarget()
 if token then
  visual:SetWorldTarget(
   token,
   string.format("SOLAR BLOOM  %d/%d",index or 1,count or 3),
   string.format("Touch the glowing sphere • %d/%d",index or 1,count or 3)
  )
  return true
 end

 local world=workspace:FindFirstChild("BloomWorld")
 if not world then
  ui.Guide.Text="Sunny Orchard is loading. The guide will reconnect automatically."
  ui.Guide.Visible=true
  return true
 end

 local root=ui.Player.Character and ui.Player.Character:FindFirstChild("HumanoidRootPart")
 local orchard=world:FindFirstChild("SunnyOrchard")
 local gate=world:FindFirstChild("SunnyOrchardGate")
 local landmark=world:FindFirstChild("SunnyOrchard_1")
 local inOrchard=root and orchard and (root.Position-orchard.Position).Magnitude<62

 if inOrchard and landmark then
  visual:SetWorldTarget(
   landmark,
   "SOLAR BLOOM ACTIVITY",
   "Interact with the highlighted activity marker, then touch all 3 glowing spheres."
  )
 elseif gate then
  visual:SetWorldTarget(
   gate,
   "SUNNY ORCHARD",
   "Return to Sunny Orchard. Solar Bloom is an activity inside this area."
  )
 elseif landmark then
  visual:SetWorldTarget(
   landmark,
   "SOLAR BLOOM ACTIVITY",
   "Find the highlighted activity marker in Sunny Orchard."
  )
 else
  ui.Guide.Text="Go to Sunny Orchard and use a Discover location / activity marker to start Solar Bloom."
  ui.Guide.Visible=true
 end
 return true
end

return S
