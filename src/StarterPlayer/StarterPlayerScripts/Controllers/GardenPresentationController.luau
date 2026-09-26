local RunService=game:GetService("RunService")

local FLOWER_DETAIL_DISTANCE=24
local FLOWER_REFRESH_SECONDS=.18

local S={FlowerAccumulator=0,FocusedFlowerInfo=nil}

local function flowerInfoPosition(info)
 local parent=info and info.Parent
 return parent and parent:IsA("BasePart") and parent.Position or nil
end

function S:Init(ui)
 self.UI=ui
 self.FlowerConnection=RunService.RenderStepped:Connect(function(dt)
  self.FlowerAccumulator+=dt
  if self.FlowerAccumulator<FLOWER_REFRESH_SECONDS then return end
  self.FlowerAccumulator=0
  self:RefreshFlowerFocus()
 end)
end

function S:RefreshFlowerFocus()
 local ui=self.UI
 local player=ui and ui.Player
 local character=player and player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local world=workspace:FindFirstChild("BloomWorld")
 local allowDetail=root~=nil and world~=nil and ui.Menu==nil and not ui:IsWorkshopExclusive()

 local nearest=nil
 local nearestDistance=FLOWER_DETAIL_DISTANCE
 local infos={}
 if world then
  for _,descendant in ipairs(world:GetDescendants()) do
   if descendant:IsA("BillboardGui") and descendant.Name=="FlowerInfo" then
    table.insert(infos,descendant)
    if allowDetail then
     local position=flowerInfoPosition(descendant)
     if position then
      local distance=(root.Position-position).Magnitude
      if distance<nearestDistance then
       nearestDistance=distance
       nearest=descendant
      end
     end
    end
   end
  end
 end

 for _,info in ipairs(infos) do info.Enabled=info==nearest end
 self.FocusedFlowerInfo=nearest
end

function S:Update()
 -- Garden synergies remain server-authoritative, but alpha no longer draws
 -- the persistent beam web between slots. The garden itself carries the layout.
end

return S
