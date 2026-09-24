local RS=game:GetService("ReplicatedStorage") local B=require(RS.Config.BeesConfig) local Tween=game:GetService("TweenService") local S={Models={}}
function S:Init(ui) self.UI=ui local f=Instance.new("Folder") f.Name="LocalBees" f.Parent=workspace self.Folder=f end
function S:Update(frames)
 local keep={} for _,v in ipairs(frames) do if v.Owner==self.UI.Player.UserId or self.UI.State and self.UI.State.Profile.Settings.ShowOtherPollinators then
  local key=v.Owner.."_"..v.Index keep[key]=true local item=self.Models[key]
  if not item then local part=Instance.new("Part") part.Name=v.Id part.Size=Vector3.new(1.4,.8,1) part.Anchored=true part.CanCollide=false part.CanTouch=false part.Color=B.Get(v.Id).Color part.Parent=self.Folder item={Part=part} self.Models[key]=item end
  local phase=v.Phase local pos=phase<.25 and v.From:Lerp(v.To,phase*4) or phase<.7 and v.To or v.To:Lerp(v.From,(phase-.7)/.3)
  if item.Tween then item.Tween:Cancel() end item.Tween=Tween:Create(item.Part,TweenInfo.new(1,Enum.EasingStyle.Linear),{Position=pos+Vector3.new(0,4,0)}) item.Tween:Play()
 end end
 for key,item in pairs(self.Models) do if not keep[key] then if item.Tween then item.Tween:Cancel() end item.Part:Destroy() self.Models[key]=nil end end
end
return S
