local RS=game:GetService("ReplicatedStorage")
local TweenService=game:GetService("TweenService")
local Cfg=require(RS.Config.RewardPresentationConfig)
local Icons=require(RS.Config.IconsConfig)
local R=require(RS.Config.RarityConfig)
local Theme=require(RS.Config.UIThemeConfig)

local S={Queue={},Busy=false,Generation=0}

function S:Init(ui)
 self.UI=ui
end

function S:ShowCard(r)
 local ui=self.UI
 local rarityColor=R.Colors[r.Rarity] or Theme.Colors.Blue
 ui.Reveal.Visible=true
 ui.Reveal.BackgroundColor3=Theme.Colors.Panel
 ui.RewardStripe.BackgroundColor3=rarityColor
 ui.RewardStroke.Color=Theme.Colors.BorderDark
 ui.RewardTitle.Text=(r.IsSpecialRoll and "BLOOM ROLL  •  " or "")..tostring(r.DisplayName or "Reward")
 ui.RewardTitle.TextColor3=Theme.Colors.Text
 local meta=tostring(r.Rarity or "Common")
 if not r.Ceremony then meta=meta..string.format("   •   %.5f%%",(tonumber(r.Chance) or 0)*100) end
 if r.IsNew then meta=meta.."   •   NEW" end
 ui.RewardMeta.Text=meta
 ui.RewardMeta.TextColor3=rarityColor
 ui.RewardHint.Text=r.Ceremony and "" or "click to speed up"
 ui.RewardIcon.Image=r.Ceremony and Icons.Get("System",r.Ceremony=="Hive" and "Hive" or "Flower") or Icons.GetRewardIcon(r.Kind,r.Id)
 ui.RewardIcon.Rotation=0
 ui.RevealScale.Scale=.9
 TweenService:Create(ui.RevealScale,TweenInfo.new(.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
end

function S:Enqueue(reward)
 table.insert(self.Queue,reward)
 if self.Busy then return end
 self.Busy=true
 task.spawn(function()
  while #self.Queue>0 do
   while self.UI and self.UI.IsWorkshopExclusive and self.UI:IsWorkshopExclusive() do
    if self.UI.Reveal then self.UI.Reveal.Visible=false end
    task.wait(.05)
   end
   local r=table.remove(self.Queue,1)
   local tier=Cfg[r.Rarity] or Cfg.Common
   local began=os.clock()
   self.Skip=false
   self:ShowCard(r)

   local reduced=self.UI.State.Profile.Settings.ReducedEffects

   local cam=workspace.CurrentCamera
   local originalFOV=cam and cam.FieldOfView
   local pulse=nil
   local emitter=nil
   if not reduced and (R.Rank[r.Rarity] or 1)>=5 then
    local root=self.UI.Player.Character and self.UI.Player.Character:FindFirstChild("HumanoidRootPart")
    if root then
     emitter=Instance.new("ParticleEmitter")
     emitter.Rate=0
     emitter.Lifetime=NumberRange.new(.4,.9)
     emitter.Speed=NumberRange.new(3,7)
     emitter.Color=ColorSequence.new(R.Colors[r.Rarity] or Theme.Colors.Blue)
     emitter.Parent=root
     emitter:Emit(r.Rarity=="Celestial" and 32 or r.Rarity=="Mythic" and 20 or 10)
    end
    if cam then
     pulse=TweenService:Create(cam,TweenInfo.new(.3,Enum.EasingStyle.Sine,Enum.EasingDirection.Out,0,true),{FieldOfView=originalFOV+4})
     pulse:Play()
    end
   end

   local duration=reduced and math.min(.6,tier.Duration) or tier.Duration*(self.UI.State.Profile.WorkshopV5.Nodes.ROLL_3 and .75 or 1)
   repeat task.wait(.03) until os.clock()-began>=duration or (self.Skip and os.clock()-began>=tier.Min)
   if pulse then pulse:Cancel() pulse:Destroy() end
   if cam and originalFOV then cam.FieldOfView=originalFOV end
   if emitter then emitter:Destroy() end
   self.UI.Reveal.Visible=false
  end
  self.Busy=false
 end)
end

function S:SkipCurrent()
 self.Skip=true
end

return S
