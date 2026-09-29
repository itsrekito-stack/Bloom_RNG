local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")

local A={FolderName="BloomMeshTemplates"}

local TEMPLATE_ALIASES={
 Bee={"Bee"},
 Garden={"Garden"},
 Hive={"Hive"},
 Bench={"Curved Sandstone Benc","Curved Sandstone Bench"},
}

local FALLBACK={
 Bee={Color=Color3.fromRGB(246,190,62),Material=Enum.Material.SmoothPlastic},
 Garden={Color=Color3.fromRGB(143,151,160),Material=Enum.Material.Slate},
 Hive={Color=Color3.fromRGB(225,169,56),Material=Enum.Material.WoodPlanks},
 Bench={Color=Color3.fromRGB(205,181,137),Material=Enum.Material.Sandstone},
}

local function forEachPart(root,fn)
 if root:IsA("BasePart") then fn(root) end
 for _,item in ipairs(root:GetDescendants()) do
  if item:IsA("BasePart") then fn(item) end
 end
end

local function contentPresent(value)
 local s=tostring(value or "")
 return s~="" and s~="rbxassetid://0"
end

local function safeContentProperty(instance,property)
 local ok,value=pcall(function()
  return instance[property]
 end)
 return ok and contentPresent(value)
end

local function hasTexture(part)
 -- SurfaceAppearance map properties require Plugin capability in some Studio
 -- server contexts. Presence of an authored SurfaceAppearance is enough for us:
 -- never inspect its protected maps and never overwrite it with fallback styling.
 if part:FindFirstChildOfClass("SurfaceAppearance") then return true end
 if part:IsA("MeshPart") and safeContentProperty(part,"TextureID") then return true end
 for _,child in ipairs(part:GetChildren()) do
  if (child:IsA("Decal") or child:IsA("Texture")) and safeContentProperty(child,"Texture") then return true end
 end
 local special=part:FindFirstChildOfClass("SpecialMesh")
 if special and safeContentProperty(special,"TextureId") then return true end
 return false
end

local function fallbackStyle(kind,partName,tint)
 local base=FALLBACK[kind] or FALLBACK.Garden
 local lower=string.lower(tostring(partName or ""))
 if kind=="Garden" then
  if string.find(lower,"soil",1,true) or string.find(lower,"dirt",1,true) or string.find(lower,"earth",1,true) then
   return Color3.fromRGB(101,72,50),Enum.Material.Ground
  elseif string.find(lower,"grass",1,true) then
   return Color3.fromRGB(83,143,78),Enum.Material.Grass
  end
 elseif kind=="Hive" then
  if string.find(lower,"entrance",1,true) or string.find(lower,"hole",1,true) then
   return Color3.fromRGB(61,47,37),Enum.Material.SmoothPlastic
  end
 elseif kind=="Bee" then
  if string.find(lower,"wing",1,true) then return Color3.fromRGB(170,225,255),Enum.Material.Glass end
  if string.find(lower,"eye",1,true) or string.find(lower,"stripe",1,true) then return Color3.fromRGB(35,31,34),Enum.Material.SmoothPlastic end
 end
 return tint or base.Color,base.Material
end

function A.ApplyTextureFallback(root,kind,tint)
 local missing=0
 forEachPart(root,function(part)
  if not hasTexture(part) then
   local color,material=fallbackStyle(kind,part.Name,tint)
   part.Color=color
   part.Material=material
   part:SetAttribute("BloomFallbackVisual",true)
   missing+=1
  end
 end)
 return missing
end

function A.Configure(root,anchored,collide)
 forEachPart(root,function(part)
  part.Anchored=anchored==true
  part.CanCollide=collide==true
  part.CanTouch=false
  part.CanQuery=collide==true
 end)
end

function A.Bounds(root)
 if root:IsA("BasePart") then return root.CFrame,root.Size end
 if root:IsA("Model") then
  local ok,cf,size=pcall(function() return root:GetBoundingBox() end)
  if ok then return cf,size end
 end
 return nil,nil
end

local function pivot(root,cf)
 if root:IsA("BasePart") then root.CFrame=cf return true end
 if root:IsA("Model") then root:PivotTo(cf) return true end
 return false
end

local function currentPivot(root)
 if root:IsA("BasePart") then return root.CFrame end
 if root:IsA("Model") then return root:GetPivot() end
 return nil
end

local function hideAuthoringSource(root)
 root:SetAttribute("BloomAuthoringSource",true)
 forEachPart(root,function(part)
  part.Transparency=1
  part.CanCollide=false
  part.CanTouch=false
  part.CanQuery=false
  part.CastShadow=false
 end)
 for _,item in ipairs(root:GetDescendants()) do
  if item:IsA("Decal") or item:IsA("Texture") then
   item.Transparency=1
  elseif item:IsA("ParticleEmitter") or item:IsA("Trail") or item:IsA("Beam") then
   item.Enabled=false
  elseif item:IsA("Light") then
   item.Enabled=false
  elseif item:IsA("BillboardGui") or item:IsA("SurfaceGui") then
   item.Enabled=false
  end
 end
end

local function scale(root,factor)
 factor=math.clamp(tonumber(factor) or 1,.02,50)
 if root:IsA("BasePart") then
  root.Size=root.Size*factor
  return true
 elseif root:IsA("Model") then
  root:ScaleTo(root:GetScale()*factor)
  return true
 end
 return false
end

function A.ScaleToFootprint(root,target)
 local _,size=A.Bounds(root)
 if not size then return false end
 local footprint=math.max(size.X,size.Z)
 if footprint<=.001 then return false end
 return scale(root,(tonumber(target) or footprint)/footprint)
end

function A.ScaleToMaxDimension(root,target)
 local _,size=A.Bounds(root)
 if not size then return false end
 local maximum=math.max(size.X,size.Y,size.Z)
 if maximum<=.001 then return false end
 return scale(root,(tonumber(target) or maximum)/maximum)
end

function A.CenterAt(root,position)
 local bounds=A.Bounds(root)
 if not bounds then return false end
 local cf=select(1,A.Bounds(root))
 local p=currentPivot(root)
 if not cf or not p then return false end
 return pivot(root,p+(position-cf.Position))
end

function A.PlaceTop(root,position,topY)
 local cf,size=A.Bounds(root)
 local p=currentPivot(root)
 if not cf or not size or not p then return false end
 local desired=Vector3.new(position.X,(tonumber(topY) or position.Y)-size.Y*.5,position.Z)
 return pivot(root,p+(desired-cf.Position))
end

function A.PlaceBottom(root,position,bottomY)
 local cf,size=A.Bounds(root)
 local p=currentPivot(root)
 if not cf or not size or not p then return false end
 local desired=Vector3.new(position.X,(tonumber(bottomY) or position.Y)+size.Y*.5,position.Z)
 return pivot(root,p+(desired-cf.Position))
end

function A.FaceAt(root,target,yawOffset)
 local p=currentPivot(root)
 if not p then return false end
 local position=p.Position
 local flatTarget=Vector3.new(target.X,position.Y,target.Z)
 if (flatTarget-position).Magnitude<.001 then return false end
 local cf=CFrame.lookAt(position,flatTarget)*CFrame.Angles(0,tonumber(yawOffset) or 0,0)
 return pivot(root,cf)
end

function A.AuthoredRelative(key,anchorKey,targetAnchorFootprint)
 local source=A.Template(key)
 local anchor=A.Template(anchorKey)
 if not source or not anchor then return nil end
 local sourcePivot=source:GetAttribute("BloomSourcePivot")
 local anchorPivot=anchor:GetAttribute("BloomSourcePivot")
 local anchorSize=anchor:GetAttribute("BloomSourceBoundsSize")
 if typeof(sourcePivot)~="CFrame" or typeof(anchorPivot)~="CFrame" or typeof(anchorSize)~="Vector3" then return nil end
 local sourceFootprint=math.max(anchorSize.X,anchorSize.Z)
 if sourceFootprint<=.001 then return nil end
 local factor=(tonumber(targetAnchorFootprint) or sourceFootprint)/sourceFootprint
 local relative=anchorPivot:ToObjectSpace(sourcePivot)
 local rotation=relative-relative.Position
 return CFrame.new(relative.Position*factor)*rotation
end

function A.PlaceRelative(root,anchorRoot,relative)
 local anchorPivot=currentPivot(anchorRoot)
 if not anchorPivot or typeof(relative)~="CFrame" then return false end
 return pivot(root,anchorPivot*relative)
end

function A.PlaceAtAnchor(root,anchorCFrame,alignBottom)
 if typeof(anchorCFrame)~="CFrame" then return false end
 local boundsCF,size=A.Bounds(root)
 local p=currentPivot(root)
 if not boundsCF or not size or not p then return false end
 local pivotToBounds=p:ToObjectSpace(boundsCF)
 local targetPosition=anchorCFrame.Position
 if alignBottom then
  targetPosition+=anchorCFrame.UpVector*(size.Y*.5)
 end
 local targetBounds=CFrame.new(targetPosition)*(anchorCFrame-anchorCFrame.Position)
 return pivot(root,targetBounds*pivotToBounds:Inverse())
end

local function candidateFor(key,instance)
 if not (instance:IsA("BasePart") or instance:IsA("Model")) then return false end
 if key=="Garden" and instance:FindFirstChild("GardenCenter",true) then return false end
 return true
end

local function findSource(key)
 for _,alias in ipairs(TEMPLATE_ALIASES[key] or {}) do
  for _,child in ipairs(workspace:GetChildren()) do
   if child.Name==alias and candidateFor(key,child) then return child end
  end
 end
 if key=="Bench" then
  for _,child in ipairs(workspace:GetChildren()) do
   if string.find(string.lower(child.Name),"curved sandstone",1,true)==1 and candidateFor(key,child) then return child end
  end
 end
 return nil
end

function A.CaptureWorkspace()
 if not RunService:IsServer() then return RS:FindFirstChild(A.FolderName) end
 local folder=RS:FindFirstChild(A.FolderName)
 if not folder then
  folder=Instance.new("Folder")
  folder.Name=A.FolderName
  folder.Parent=RS
 end
 if folder:GetAttribute("Captured") then return folder end

 for key in pairs(TEMPLATE_ALIASES) do
  local source=findSource(key)
  if source then
   local old=folder:FindFirstChild(key)
   if old then old:Destroy() end

   local sourcePivot=currentPivot(source)
   local sourceBoundsCF,sourceBoundsSize=A.Bounds(source)
   local clone=source:Clone()
   clone.Name=key
   clone:SetAttribute("BloomAuthoredMeshTemplate",true)
   clone:SetAttribute("BloomWorkspaceAuthored",true)
   if sourcePivot then clone:SetAttribute("BloomSourcePivot",sourcePivot) end
   if sourceBoundsCF then clone:SetAttribute("BloomSourceBoundsCFrame",sourceBoundsCF) end
   if sourceBoundsSize then clone:SetAttribute("BloomSourceBoundsSize",sourceBoundsSize) end
   clone.Parent=folder

   local missing=A.ApplyTextureFallback(clone,key)
   source:SetAttribute("BloomLayoutRole",key)
   hideAuthoringSource(source)
   print(string.format(
    "[Bloom][MESH] captured %s from Workspace in-place (%d untextured part%s fallback-styled)",
    key,missing,missing==1 and "" or "s"
   ))
  else
   warn("[Bloom][MESH] authored "..key.." source not found in Workspace; runtime fallback will be used")
  end
 end
 folder:SetAttribute("Captured",true)
 return folder
end

function A.Template(key)
 local folder=RS:FindFirstChild(A.FolderName)
 return folder and folder:FindFirstChild(key) or nil
end

function A.Clone(key)
 local template=A.Template(key)
 return template and template:Clone() or nil
end

return A
