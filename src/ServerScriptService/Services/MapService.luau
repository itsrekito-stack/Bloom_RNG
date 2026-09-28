local RS=game:GetService("ReplicatedStorage")

local S={Landmarks={},Gates={}}

local function asVerticalCylinder(part,material)
 part.Shape=Enum.PartType.Cylinder
 part.CFrame=CFrame.new(part.Position)*CFrame.Angles(0,0,math.rad(90))
 part.Material=material or Enum.Material.SmoothPlastic
end

function S:Init(x)
 self.X=x
end

function S:Sector(player)
 return "Center"
end

function S:Unlock(player,id)
 return false
end

function S:Build()
 local centerFlower=self.X.FlowerService.Build(
  1,
  require(RS.Config.FlowersConfig).Species.StarBloom,
  self.X.Origin+Vector3.new(0,1,0)
 )
 centerFlower.Name="ServerBloom"
 centerFlower:ScaleTo(1.5)
 centerFlower.Parent=self.X.World

 local tree=self.X:Part(
  self.X.World,
  "AncientTree",
  self.X.Origin+Vector3.new(-12,3,0),
  Vector3.new(6,3,3),
  Color3.fromRGB(110,82,60),
  true
 )
 asVerticalCylinder(tree,Enum.Material.Wood)
 self.X:Prompt(tree,"Season Turn",function(player)
  self.X.SeasonService:Preview(player)
 end)
end

function S:Tick(player)
 local temp=self.X.Temp[player]
 if not temp then return false end
 if temp.Sector=="Center" then return false end
 temp.Sector="Center"
 self.X.GardenSynergyService:Recalculate(player)
 return true
end

return S
