local RS=game:GetService("ReplicatedStorage")
local RunService=game:GetService("RunService")
local ServerStorage=game:GetService("ServerStorage")

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

 local sources=ServerStorage:FindFirstChild("BloomMeshTemplateSources")
 if not sources then
  sources=Instance.new("Folder")
  sources.Name="BloomMeshTemplateSources"
  sources.Parent=ServerStorage
 end

 for key in pairs(TEMPLATE_ALIASES) do
  local source=findSource(key)
  if source then
   local old=folder:FindFirstChild(key)
   if old then old:Destroy() end
   local clone=source:Clone()
   clone.Name=key
   clone:SetAttribute("BloomAuthoredMeshTemplate",true)
   clone.Parent=folder
   local missing=A.ApplyTextureFallback(clone,key)
   source.Name="_BloomSource_"..key
   source.Parent=sources
   print(string.format("[Bloom][MESH] captured %s template (%d untextured part%s fallback-styled)",key,missing,missing==1 and "" or "s"))
  else
   warn("[Bloom][MESH] authored "..key.." template not found in Workspace; runtime fallback will be used")
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
