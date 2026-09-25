local RS=game:GetService("ReplicatedStorage") local RunService=game:GetService("RunService") local A=require(RS.Config.ActivityConfig) local S={Items={}}
function S:Init(ui)
 self.UI=ui
 local folder=Instance.new("Folder") folder.Name="LocalBloomTokens" folder.Parent=workspace self.Folder=folder
 self.TouchParams=OverlapParams.new() self.TouchParams.FilterType=Enum.RaycastFilterType.Include
 self.TouchConnection=RunService.Heartbeat:Connect(function()
  local player=self.UI and self.UI.Player local character=player and player.Character
  if not character then return end
  self.TouchParams.FilterDescendantsInstances={character}
  for id,item in pairs(self.Items) do
   local part=item.Part
   if part and part.Parent then
    local touching=#workspace:GetPartsInPart(part,self.TouchParams)>0
    if touching and not item.Touching then
     item.Touching=true
     self.UI:Send("Activity",id,item.Index,"Collect")
    elseif not touching then
     item.Touching=false
    end
   end
  end
 end)
end
function S:Update(list)
 local keep={}
 for _,o in ipairs(list) do
  keep[o.Id]=true
  local item=self.Items[o.Id]
  if item and item.Index~=o.Index then item.Part:Destroy() self.Items[o.Id]=nil item=nil end
  if not item then
   local cfg=A.Types[o.Kind] or {} local radius=tonumber(o.Radius) or tonumber(cfg.Radius) or .75
   local part=Instance.new("Part") part.Name=o.Kind part.Shape=Enum.PartType.Ball part.Size=Vector3.new(radius*2,radius*2,radius*2) part.Anchored=true part.CanCollide=false part.CanTouch=true part.CanQuery=true part.Material=Enum.Material.Neon part.Color=Color3.fromRGB(240,220,120) part.Position=o.Position
   if o.Kind=="CrystalResonance" then part.Color=Color3.fromRGB(115,220,255) elseif o.Kind=="NectarBud" then part.Color=Color3.fromRGB(120,230,160) elseif o.Kind=="DewDrop" then part.Color=Color3.fromRGB(150,220,255) elseif o.Kind=="Overcharge" then part.Color=Color3.fromRGB(205,115,250) elseif o.Kind=="FireflyRoute" then part.Color=Color3.fromRGB(220,240,120) end
   if self.UI.State and self.UI.State.Profile.Settings.ReducedEffects then part.Material=Enum.Material.SmoothPlastic end
   part.Parent=self.Folder
   if o.Kind=="NectarBud" or o.Kind=="BloomSurge" then
    local world=workspace:FindFirstChild("BloomWorld") local plot=world and world:FindFirstChild("Garden_"..self.UI.Player.UserId)
    if plot then
     local nearest=nil local distance=math.huge
     for _,model in ipairs(plot:GetDescendants()) do
      if model:IsA("Model") and model.Name:find("FlowerSlot_") and model.PrimaryPart then
       local d=(model.PrimaryPart.Position-o.Position).Magnitude
       if d<distance then distance=d nearest=model end
      end
     end
     if nearest then local highlight=Instance.new("Highlight") highlight.Adornee=nearest highlight.FillColor=part.Color highlight.FillTransparency=self.UI.State and self.UI.State.Profile.Settings.ReducedEffects and .85 or .6 highlight.Parent=part end
    end
   end
   item={Part=part,Index=o.Index,Expires=o.Expires,Touching=false,Sector=o.Sector,Tutorial=o.Tutorial==true} self.Items[o.Id]=item
  else
   item.Part.Position=o.Position
  end
 end
 for id,item in pairs(self.Items) do if not keep[id] then item.Part:Destroy() self.Items[id]=nil end end
end
function S:Others(list)
 if not self.OtherFolder then self.OtherFolder=Instance.new("Folder") self.OtherFolder.Name="OtherBloomTokens" self.OtherFolder.Parent=workspace end
 self.OtherItems=self.OtherItems or {} local keep={}
 if self.UI.State and not self.UI.State.Profile.Settings.HideOtherPlayersTokens then
  for _,o in ipairs(list) do
   if o.Owner~=self.UI.Player.UserId then
    keep[o.Id]=true local part=self.OtherItems[o.Id]
    if not part then part=Instance.new("Part") part.Shape=Enum.PartType.Ball part.Size=Vector3.new(1,1,1) part.Transparency=.6 part.Anchored=true part.CanCollide=false part.CanTouch=false part.CanQuery=false part.Color=Color3.fromRGB(170,200,140) part.Parent=self.OtherFolder self.OtherItems[o.Id]=part end
    part.Position=o.Position
   end
  end
 end
 for id,part in pairs(self.OtherItems) do if not keep[id] then part:Destroy() self.OtherItems[id]=nil end end
end
function S:Target(mode)
 for _,item in pairs(self.Items) do
  if mode=="Tutorial" and item.Tutorial then return item.Part end
  if mode=="Sector" and item.Sector then return item.Part end
  if mode==nil then return item.Part end
 end
end
function S:Cleanup() self:Update({}) end
return S
