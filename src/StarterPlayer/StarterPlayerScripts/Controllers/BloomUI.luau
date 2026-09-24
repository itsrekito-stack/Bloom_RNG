local RS=game:GetService("ReplicatedStorage")
local Players=game:GetService("Players")
local UIS=game:GetService("UserInputService")
local TweenService=game:GetService("TweenService")
local Workspace=game:GetService("Workspace")
local StarterGui=game:GetService("StarterGui")
local RunService=game:GetService("RunService")

local Icons=require(RS.Config.IconsConfig)
local F=require(RS.Config.FlowersConfig)
local B=require(RS.Config.BeesConfig)
local W=require(RS.Config.WorkshopConfig)
local T=require(RS.Config.TutorialConfig)
local Trials=require(RS.Config.BuildTrialConfig)
local R=require(RS.Config.RarityConfig)
local L=require(RS.Config.LocationsConfig)
local Theme=require(RS.Config.UIThemeConfig)
local RollAudio=require(RS.Config.RollAudioConfig)
local NumberFormatter=require(RS.Shared.NumberFormatter)

local C=Theme.Colors
local CLIENT_BUILD="ui-polish-v4-2026-09-24"
local UI={Player=Players.LocalPlayer,Pending=false,Auto=false,NextRoll=0,Menu=nil,State=nil,Connections={},RouletteRunning=false,RouletteLanding=false,RouletteGeneration=0}

local MENU_NAMES={
 SeedSatchel="Сумка семян",
 Workshop="Мастерская",
 FieldGuide="Справочник",
 Map="Карта",
 Trials="Испытания",
 Settings="Настройки",
 Plant="Посадка",
 Season="Смена сезона",
 Replay="Подсказки",
 Cards="Карты сезона",
}
local MENU_HINTS={
 SeedSatchel="Цветы, пчёлы, мастерство и экипировка",
 Workshop="Постоянные улучшения и ветви прогрессии",
 FieldGuide="Коллекция, шансы и открытые синергии",
 Map="Сектора, открытия и переходы",
 Trials="Короткие испытания билда",
 Settings="Эффекты, звук и автоматизация",
 Plant="Выберите семя для свободной клумбы",
 Season="Проверьте изменения перед подтверждением",
 Replay="Повтор обучения без сброса прогресса",
 Cards="Выберите эффект нового сезона",
}
local SETTINGS_NAMES={
 ReducedEffects="Уменьшенные эффекты",
 ShowOtherPollinators="Показывать чужих пчёл",
 HideOtherPlayersTokens="Скрывать чужие активности",
 RareFeed="Показывать редкие находки",
 AutoDissolve="Авторастворение дубликатов",
}
local JOURNEY={
 "Получи первую пчелу","Собери Pollen Spark","Доставка мёда","Сделай roll","Посади цветок","Заполни Bloom Meter","Сделай Bloom Roll","Улей уровня 2","Посети мастерскую","Купи узел Workshop","Создай синергию","Открой второй слот пчелы","Активируй Bee Trait","Посети Sunny Orchard","Пройди Solar Bloom","Открой 6 цветов","Открой Crystal Gate","Пройди испытание","Посети Crystal Greenhouse","Подготовь Season Turn",
}

local function make(class,parent,props)
 local x=Instance.new(class)
 for k,v in pairs(props or {}) do x[k]=v end
 x.Parent=parent
 return x
end

local function corner(x,r)
 return make("UICorner",x,{CornerRadius=UDim.new(0,r or Theme.Radius.Medium)})
end

local function outline(x,color,thickness,transparency)
 return make("UIStroke",x,{Color=color or C.BorderDark,Thickness=thickness or Theme.Stroke.Control,Transparency=transparency or Theme.Stroke.DarkTransparency,ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
end

local function pad(x,l,r,t,b)
 return make("UIPadding",x,{PaddingLeft=UDim.new(0,l or 0),PaddingRight=UDim.new(0,r or l or 0),PaddingTop=UDim.new(0,t or l or 0),PaddingBottom=UDim.new(0,b or t or l or 0)})
end

local function hover(button,base,over)
 button.AutoButtonColor=false
 button.MouseEnter:Connect(function()
  if not button.Parent then return end
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=over}):Play()
 end)
 button.MouseLeave:Connect(function()
  if not button.Parent then return end
  TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=base}):Play()
 end)
end

local function compact(v)
 return NumberFormatter.Compact(tonumber(v) or 0)
end

function UI:Text(parent,text,size,props)
 props=props or {}
 local label=make("TextLabel",parent,{
  Size=size or UDim2.new(1,0,0,24),
  Position=props.Position or UDim2.new(),
  AnchorPoint=props.AnchorPoint or Vector2.new(),
  BackgroundTransparency=props.BackgroundTransparency==nil and 1 or props.BackgroundTransparency,
  BackgroundColor3=props.BackgroundColor3 or C.Panel,
  BorderSizePixel=0,
  Text=text or "",
  TextColor3=props.TextColor3 or C.Text,
  TextSize=props.TextSize or 14,
  TextWrapped=props.TextWrapped~=false,
  TextXAlignment=props.TextXAlignment or Enum.TextXAlignment.Left,
  TextYAlignment=props.TextYAlignment or Enum.TextYAlignment.Center,
  Font=props.Font or Enum.Font.Gotham,
  ZIndex=props.ZIndex or ((parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1),
  Visible=props.Visible==nil and true or props.Visible,
 })
 if props.Name then label.Name=props.Name end
 if props.AutomaticSize then label.AutomaticSize=props.AutomaticSize end
 return label
end

function UI:Label(parent,text,height)
 local template=self.Templates and self.Templates:FindFirstChild("LabelTemplate")
 local label
 if template and template:IsA("TextLabel") then
  label=template:Clone()
  label.Name="Label"
  label.Visible=true
  label.Parent=parent
  label.Text=text or ""
  label.Size=UDim2.new(1,0,0,height or 30)
  label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 else
  label=self:Text(parent,text,UDim2.new(1,0,0,height or 30),{BackgroundTransparency=.32,BackgroundColor3=C.PanelSoft,TextColor3=C.Muted,TextSize=11,TextWrapped=true})
  corner(label,Theme.Radius.Medium)
  outline(label,C.BorderSoft,1,.46)
  pad(label,10,10,4,4)
 end
 return label
end

function UI:Section(parent,text)
 local template=self.Templates and self.Templates:FindFirstChild("SectionTemplate")
 local label
 if template and template:IsA("TextLabel") then
  label=template:Clone()
  label.Name="Section"
  label.Visible=true
  label.Parent=parent
  label.Text=string.upper(text or "")
  label.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
 else
  label=self:Text(parent,string.upper(text or ""),UDim2.new(1,0,0,18),{TextColor3=C.Blue,TextSize=10,Font=Enum.Font.GothamBold})
  pad(label,2,2,0,0)
 end
 return label
end

function UI:Button(parent,text,fn,icon)
 local template=self.Templates and self.Templates:FindFirstChild("ButtonTemplate")
 local b
 if template and template:IsA("TextButton") then
  b=template:Clone()
  b.Name="Button"
  b.Visible=true
  b.Parent=parent
  b.Text=text or ""
  b.ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1
  local img=b:FindFirstChild("Icon")
  local padding=b:FindFirstChild("Padding") or b:FindFirstChildOfClass("UIPadding")
  if img and img:IsA("ImageLabel") then
   img.Visible=icon~=nil and icon~=""
   img.Image=icon or ""
   img.ZIndex=b.ZIndex+1
  end
  b.TextXAlignment=(icon and icon~="") and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center
  if padding then padding.PaddingLeft=UDim.new(0,(icon and icon~="") and 36 or 10) end
 else
  local base=C.PanelRaised
  b=make("TextButton",parent,{Size=UDim2.new(1,0,0,34),BackgroundColor3=base,BorderSizePixel=0,Text=text,TextColor3=C.Text,TextSize=12,TextWrapped=true,TextXAlignment=icon and icon~="" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Center,Font=Enum.Font.GothamMedium,ZIndex=(parent and parent:IsA("GuiObject")) and parent.ZIndex+1 or 1})
  corner(b,Theme.Radius.Medium)
  outline(b,C.BorderDark,Theme.Stroke.Control,.12)
  if icon and icon~="" then make("ImageLabel",b,{Name="Icon",Size=UDim2.fromOffset(22,22),Position=UDim2.fromOffset(8,6),BackgroundTransparency=1,Image=icon,ScaleType=Enum.ScaleType.Fit,ZIndex=b.ZIndex+1}) pad(b,36,10,0,0) else pad(b,10,10,0,0) end
 end
 hover(b,C.PanelRaised,C.PanelHover)
 b.Activated:Connect(fn)
 return b
end

function UI:Send(action,a,b,c)
 self.Request:FireServer(action,a,b,c)
end

function UI:Toast(text)
 self.ToastLabel.Text=tostring(text or "")
 self.ToastRoot.Visible=true
 self.ToastUntil=os.clock()+4
 if self.ToastScale then
  self.ToastScale.Scale=.94
  TweenService:Create(self.ToastScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
end

function UI:ClearPanel()
 for _,x in ipairs(self.Content:GetChildren()) do
  if not x:IsA("UIListLayout") and not x:IsA("UIPadding") then x:Destroy() end
 end
end

function UI:SetPanelVisible(visible)
 self.Panel.Visible=visible
 self.ModalShade.Visible=visible
 if visible then
  self.PanelScale.Scale=.96
  TweenService:Create(self.PanelScale,TweenInfo.new(Theme.Motion.Normal,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1}):Play()
 end
end

function UI:Close()
 self.ReplayIndex=nil
 if self.Menu=="Season" then self:Send("SeasonCancel") end
 self.Menu=nil
 self:SetPanelVisible(false)
 self:Send("Menu",false)
end

function UI:Open(name,arg)
 if self.Menu==name and arg==nil then self:Close() return end
 if not self.State then return end
 if name~="Settings" and name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" and not self.State.Profile.Tutorial.FeatureUnlocks[name] then return end
 self.Menu=name
 self.MenuArg=arg
 self:SetPanelVisible(true)
 if name~="Plant" and name~="Season" and name~="Cards" and name~="Replay" then self:Send("Menu",name) end
 self:RenderMenu()
end

function UI:RenderMenu()
 if not self.Menu or not self.State then return end
 local p=self.State.Profile
 local name=self.Menu
 self:ClearPanel()
 self.PanelTitle.Text=MENU_NAMES[name] or name
 self.PanelSubtitle.Text=MENU_HINTS[name] or ""
 if self.PanelHeaderIcon then
  local headerImage=Icons.Get("Menus",name)
  if headerImage=="" then
   if name=="Plant" then headerImage=Icons.Get("System","Garden")
   elseif name=="Season" or name=="Cards" then headerImage=Icons.Get("System","Flower")
   elseif name=="Replay" then headerImage=Icons.Get("System","Tutorial")
   else headerImage=Icons.Get("System","Info") end
  end
  self.PanelHeaderIcon.Image=headerImage
 end
 self.Content.CanvasPosition=Vector2.new()

 if name=="Plant" then
  local slot=self.MenuArg
  self:Section(self.Content,"Клумба "..slot)
  self:Label(self.Content,"Выберите свободное семя. Уже посаженные копии автоматически вычитаются из доступного количества.",32)
  if p.WorkshopV5.Nodes.GARDEN_3 and self.LastSeed then
   self:Button(self.Content,"Повторить посадку • "..self.LastSeed,function() self:Send("Plant",slot,self.LastSeed) self:Close() end,Icons.GetRewardIcon("FlowerSeed",self.LastSeed))
  end
  local available={}
  for id,f in pairs(F.Species) do
   local owned=p.FlowerCollection.OwnedSeedCopies[id] or 0
   local planted=0
   for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then planted=planted+1 end end
   local count=math.max(0,owned-planted)
   if count>0 then table.insert(available,{Id=id,Flower=f,Count=count,Owned=owned}) end
  end
  table.sort(available,function(a,b)
   local ar=R.Rank[a.Flower.Rarity] or 1 local br=R.Rank[b.Flower.Rarity] or 1
   if ar==br then return a.Flower.DisplayName<b.Flower.DisplayName end
   return ar<br
  end)
  if #available==0 then
   self:Label(self.Content,"Нет свободных семян. Получи семя из рулетки или выкопай уже посаженный цветок — после награды инвентарь обновляется автоматически.",52)
  else
   for _,entry in ipairs(available) do
    local id=entry.Id local f=entry.Flower local count=entry.Count
    self:Button(self.Content,f.DisplayName.."  •  свободно "..count.." / всего "..entry.Owned,function() self.LastSeed=id self:Send("Plant",slot,id) self:Close() end,Icons.GetRewardIcon("FlowerSeed",id))
   end
  end
  self:Button(self.Content,"Выкопать цветок • семя сохранится",function() self:Send("Plant",slot,"") self:Close() end,Icons.Get("System","Minus"))

 elseif name=="SeedSatchel" then
  self:Section(self.Content,"Семена и цветы")
  self:Label(self.Content,"Слева все семена квадратами, справа выбранный цветок и быстрые действия. Посадка выполняется через клумбу.",36)
  local items={}
  for id,count in pairs(p.FlowerCollection.OwnedSeedCopies) do
   local f=F.Species[id]
   if f and count>0 then
    local planted=0
    for _,s in ipairs(p.Garden.Slots) do if s.SpeciesId==id then planted=planted+1 end end
    local mastery=p.FlowerCollection.FlowerMastery[id] or {Level=1,XP=0}
    table.insert(items,{Id=id,Flower=f,Count=count,Planted=planted,Free=math.max(0,count-planted),Mastery=mastery})
   end
  end
  table.sort(items,function(a,b)
   local ar=R.Rank[a.Flower.Rarity] or 1 local br=R.Rank[b.Flower.Rarity] or 1
   if ar==br then return a.Flower.DisplayName<b.Flower.DisplayName end
   return ar<br
  end)
  if #items==0 then
   self:Label(self.Content,"Нет семян. Сделай roll и получи семя, после чего инвентарь заполнится автоматически.",38)
  else
   local selected=self.SelectedSatchelItem
   local active=items[1]
   for _,entry in ipairs(items) do if entry.Id==selected then active=entry break end end
   self.SelectedSatchelItem=active.Id

   local split=make("Frame",self.Content,{Size=UDim2.new(1,0,0,286),BackgroundTransparency=1,BorderSizePixel=0,ZIndex=self.Content.ZIndex+1})
   local left=make("ScrollingFrame",split,{Name="InventoryGrid",Size=UDim2.new(0,228,1,0),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundColor3=C.Panel,BackgroundTransparency=.12,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ZIndex=split.ZIndex+1})
   corner(left,Theme.Radius.Large)
   outline(left,C.BorderSoft,1,.4)
   pad(left,12,12,12,12)
   local grid=make("UIGridLayout",left,{CellSize=UDim2.fromOffset(64,64),CellPadding=UDim2.fromOffset(7,7),SortOrder=Enum.SortOrder.LayoutOrder})

   local right=make("Frame",split,{Name="SelectedDetails",Size=UDim2.new(1,-240,1,0),Position=UDim2.fromOffset(240,0),BackgroundColor3=C.Panel,BackgroundTransparency=.08,BorderSizePixel=0,ZIndex=split.ZIndex+1})
   corner(right,Theme.Radius.Large)
   outline(right,C.BorderDark,Theme.Stroke.Panel,.08)
   local info=make("Frame",right,{Name="Info",Size=UDim2.new(1,-16,0,98),Position=UDim2.fromOffset(8,8),BackgroundColor3=C.PanelSoft,BackgroundTransparency=.18,BorderSizePixel=0,ZIndex=right.ZIndex+1})
   corner(info,Theme.Radius.Medium)
   outline(info,C.BorderSoft,1,.45)

   local iconWrap=make("Frame",info,{Size=UDim2.fromOffset(64,64),Position=UDim2.fromOffset(10,10),BackgroundColor3=C.PanelRaised,BorderSizePixel=0,ZIndex=info.ZIndex+1})
   corner(iconWrap,Theme.Radius.Large)
   outline(iconWrap,C.BorderDark,Theme.Stroke.Control,.12)
   local infoIcon=make("ImageLabel",iconWrap,{Name="Icon",Size=UDim2.fromOffset(44,44),Position=UDim2.fromOffset(10,10),BackgroundTransparency=1,ScaleType=Enum.ScaleType.Fit,Image=Icons.GetRewardIcon("FlowerSeed",active.Id),ZIndex=iconWrap.ZIndex+1})
   local title=self:Text(info,active.Flower.DisplayName,UDim2.new(1,-94,0,22),{Position=UDim2.fromOffset(84,8),TextSize=16,Font=Enum.Font.GothamBold,ZIndex=info.ZIndex+1})
   local rarity=self:Text(info,active.Flower.Rarity.."   •   copies "..active.Count,UDim2.new(1,-94,0,15),{Position=UDim2.fromOffset(84,30),TextSize=10,TextColor3=C.Gold,ZIndex=info.ZIndex+1})
   local meta=self:Text(info,"Mastery "..active.Mastery.Level.."   •   XP "..active.Mastery.XP.."/"..(active.Mastery.Level*25).."   •   свободно "..active.Free.." / всего "..active.Count,UDim2.new(1,-94,0,28),{Position=UDim2.fromOffset(84,46),TextSize=10,TextColor3=C.Muted,TextWrapped=true,ZIndex=info.ZIndex+1})
   local hint=self:Text(info,"Защищай любимые цветы и растворяй только свободные дубликаты.",UDim2.new(1,-20,0,12),{Position=UDim2.fromOffset(10,80),TextSize=9,TextColor3=C.Muted,ZIndex=info.ZIndex+1})

   local actions=make("ScrollingFrame",right,{Name="Actions",Size=UDim2.new(1,-16,1,-114),Position=UDim2.fromOffset(8,106),CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ZIndex=right.ZIndex+1})
   local actionsLayout=make("UIListLayout",actions,{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})

   local function addAction(text,fn,icon)
    local btn=self:Button(actions,text,fn,icon)
    btn.Size=UDim2.new(1,0,0,32)
    btn.TextSize=12
    return btn
   end

   addAction((p.FlowerCollection.LockedFlowers[active.Id] and "Снять защиту" or "Защитить").." • "..active.Flower.DisplayName,function() self:Send("Flag",active.Id,"LockedFlowers") end,Icons.GetRewardIcon("FlowerSeed",active.Id))
   addAction(p.FlowerCollection.FavoriteFlowers[active.Id] and "Убрать из избранного" or "Добавить в избранное",function() self:Send("Flag",active.Id,"FavoriteFlowers") end,Icons.Get("System","Confirm"))
   addAction("Растворить 1 свободный дубликат",function() self:Send("Dissolve",active.Id,1) end,Icons.Get("WorkshopHex","Duplicate"))
   addAction("Mastery +XP  •  "..(active.Mastery.Level*5).." Petal Dust",function() self:Send("FlowerUpgrade",active.Id) end,Icons.GetCurrencyIcon("PetalDust"))
   addAction("Flower Memory",function() self:Send("Keepsake","Flower",active.Id) end,Icons.Get("System","Flower"))
   if p.WorkshopV5.Nodes.LEGACY_5 then addAction("Third Memory Slot",function() self:Send("Keepsake","Flower2",active.Id) end,Icons.Get("System","Flower")) end

   for index,entry in ipairs(items) do
    local tileTemplate=self.Templates and self.Templates:FindFirstChild("InventoryTileTemplate")
    local tile
    if tileTemplate and tileTemplate:IsA("ImageButton") then
     tile=tileTemplate:Clone()
     tile.Name="Tile_"..entry.Id
     tile.Visible=true
     tile.Parent=left
     tile.LayoutOrder=index
     tile.ZIndex=left.ZIndex+1
     tile.BackgroundColor3=entry.Id==active.Id and C.BlueDeep or C.PanelRaised
    else
     tile=make("ImageButton",left,{Name="Tile_"..entry.Id,BackgroundColor3=entry.Id==active.Id and C.BlueDeep or C.PanelRaised,BorderSizePixel=0,AutoButtonColor=false,Image="",LayoutOrder=index,ZIndex=left.ZIndex+1})
     corner(tile,Theme.Radius.Medium)
     outline(tile,C.BorderDark,Theme.Stroke.Control,.14)
    end
    local tileStroke=tile:FindFirstChildOfClass("UIStroke")
    if tileStroke then tileStroke.Color=entry.Id==active.Id and C.Gold or C.BorderDark tileStroke.Thickness=entry.Id==active.Id and 2 or Theme.Stroke.Control tileStroke.Transparency=entry.Id==active.Id and .05 or .14 end
    local img=tile:FindFirstChild("Icon")
    local countLabel=tile:FindFirstChild("Count")
    local nameLabel=tile:FindFirstChild("Name")
    local flagsLabel=tile:FindFirstChild("Flags")
    if img and img:IsA("ImageLabel") then img.Image=Icons.GetRewardIcon("FlowerSeed",entry.Id) img.ZIndex=tile.ZIndex+1 end
    if countLabel and countLabel:IsA("TextLabel") then countLabel.Text="x"..entry.Count countLabel.ZIndex=tile.ZIndex+2 end
    if nameLabel and nameLabel:IsA("TextLabel") then nameLabel.Text=entry.Flower.DisplayName nameLabel.ZIndex=tile.ZIndex+1 end
    if flagsLabel and flagsLabel:IsA("TextLabel") then flagsLabel.Text=(p.FlowerCollection.LockedFlowers[entry.Id] and "◆" or (p.FlowerCollection.FavoriteFlowers[entry.Id] and "★" or "")) flagsLabel.ZIndex=tile.ZIndex+2 end
    tile.MouseEnter:Connect(function() if entry.Id~=self.SelectedSatchelItem then TweenService:Create(tile,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play() end end)
    tile.MouseLeave:Connect(function() if entry.Id~=self.SelectedSatchelItem then TweenService:Create(tile,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelRaised}):Play() end end)
    tile.Activated:Connect(function() self.SelectedSatchelItem=entry.Id self:RenderMenu() end)
   end

   self:Section(self.Content,"Пчёлы • слотов "..self.State.BeeCapacity)
   for id,count in pairs(p.Pollinators.BeeInventory) do
    local bee=B.Get(id)
    if bee then
     self:Label(self.Content,bee.DisplayName.."  ×"..count.."   •   "..table.concat(bee.Traits,", "),34)
    end
   end
  end

 elseif name=="Workshop" then
  self:Section(self.Content,"Workshop Tree")
  self:Label(self.Content,"Points "..p.WorkshopV5.Points.."   •   Coins "..compact(p.Currencies.Coins).."   •   Petal Dust "..compact(p.Currencies.PetalDust),36)
  self:Button(self.Content,"Alpha respec • вернуть стоимость обычных узлов",function() self:Send("Respec") end,Icons.Get("System","Warning"))
  local canvas=make("ScrollingFrame",self.Content,{Size=UDim2.new(1,0,0,320),CanvasSize=UDim2.fromOffset(1440,1300),BackgroundColor3=C.Background,BackgroundTransparency=.12,BorderSizePixel=0,ScrollBarThickness=6,ScrollBarImageColor3=C.Blue,ScrollingDirection=Enum.ScrollingDirection.XY})
  corner(canvas,Theme.Radius.Large)
  outline(canvas,C.BorderDark,Theme.Stroke.Panel,.08)
  local center=Vector2.new(720,650)
  for id,n in pairs(W.Nodes) do
   local pos=id=="CORE" and center or center+Vector2.new(math.cos(n.Angle),math.sin(n.Angle))*n.Radius
   if n.Parent then
    local prev=W.Nodes[n.Parent]
    local from=n.Parent=="CORE" and center or center+Vector2.new(math.cos(prev.Angle),math.sin(prev.Angle))*prev.Radius
    local d=pos-from
    make("Frame",canvas,{Size=UDim2.fromOffset(d.Magnitude,3),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset((pos.X+from.X)/2,(pos.Y+from.Y)/2),Rotation=math.deg(math.atan2(d.Y,d.X)),BackgroundColor3=p.WorkshopV5.Nodes[n.Parent] and C.GreenDeep or C.BorderSoft,BorderSizePixel=0,ZIndex=1})
   end
   local b=make("TextButton",canvas,{Size=UDim2.fromOffset(94,84),Position=UDim2.fromOffset(pos.X-47,pos.Y-42),BackgroundTransparency=1,Text="",ZIndex=2})
   local selected=self.SelectedNode==id
   local owned=p.WorkshopV5.Nodes[id]
   local icon=make("ImageLabel",b,{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,Image=Icons.GetWorkshopHexIcon(owned and "Core" or "Locked"),ImageColor3=owned and C.Green or C.White,ScaleType=Enum.ScaleType.Fit,ZIndex=2})
   if selected then icon.ImageColor3=C.Gold end
   make("TextLabel",b,{Size=UDim2.new(1,-12,1,-16),Position=UDim2.fromOffset(6,8),BackgroundTransparency=1,Text=n.Name,TextColor3=C.Text,TextStrokeColor3=C.Black,TextStrokeTransparency=.55,TextSize=11,Font=Enum.Font.GothamBold,TextWrapped=true,ZIndex=3})
   b.Activated:Connect(function() if id~="CORE" then self.SelectedNode=id self:RenderMenu() end end)
  end
  canvas.CanvasPosition=Vector2.new(480,410)
  local n=W.Nodes[self.SelectedNode]
  if n then
   local rules=require(RS.Config.WorkshopEffectsConfig)[n.Id] or {}
   local descriptions={}
   for key,value in pairs(rules) do table.insert(descriptions,key..": "..tostring(value)) end
   self:Section(self.Content,"Выбранный узел")
   self:Label(self.Content,n.Name.."   •   Hive "..n.Hive.."   •   "..n.Cost.." point   •   "..n.Coins.." coins   •   "..n.Dust.." dust   •   "..n.Nectar.." nectar",56)
   if #descriptions>0 then self:Label(self.Content,table.concat(descriptions,"  •  "),52) end
   self:Button(self.Content,p.WorkshopV5.Nodes[n.Id] and "Куплено" or "Купить узел",function() self:Send("WorkshopBuy",n.Id) end,Icons.Get("System",p.WorkshopV5.Nodes[n.Id] and "Confirm" or "Upgrade"))
  end

 elseif name=="FieldGuide" then
  self:Section(self.Content,"Коллекция и реальные шансы")
  self:Label(self.Content,"Шансы учитывают текущие модификаторы и гарантию нового открытия.",48)
  for _,item in ipairs(self.State.Odds) do
   self:Label(self.Content,item.DisplayName.."   •   "..item.Rarity..string.format("   •   %.6f%%",item.Chance*100)..(item.Undiscovered and "   •   НЕ ОТКРЫТ" or "   •   открыт"),38)
  end
  self:Section(self.Content,"Синергии")
  self:Label(self.Content,"Пары: Daisy + Tulip; Sunflower + Clover.",36)
  if p.WorkshopV5.Nodes.GARDEN_5 then self:Label(self.Content,"Crystal triangle: 1, 2, 6; Meadow line: 1, 2, 3; opposite: 1, 15.",48) end
  for id in pairs(p.GardenSynergies.Discovered) do self:Label(self.Content,id.."   •   mastery "..(p.GardenSynergies.Mastery[id] or 0),34) end

 elseif name=="Map" then
  self:Section(self.Content,"Мир Bloom RNG")
  if p.WorkshopV5.Nodes.EXPLORATION_1 and self.State.Pulse then self:Label(self.Content,"Biome Pulse  •  "..self.State.Pulse.Sector,36) end
  for _,id in ipairs(L.Order) do self:Label(self.Content,L.Sectors[id].Name.."   •   "..(p.World.UnlockedSectors[id] and "ОТКРЫТО" or "требуется Hive "..L.Sectors[id].Hive),36) end
  self:Section(self.Content,"Landmarks")
  local any=false
  for id in pairs(p.World.LandmarkDiscoveries) do any=true self:Label(self.Content,"✓  "..id,32) end
  if not any then self:Label(self.Content,"Пока ничего не найдено.",32) end
  self:Button(self.Content,"Открыть Build Trials",function() self:Open("Trials") end,Icons.Get("System","Quests"))

 elseif name=="Trials" then
  self:Section(self.Content,"Build Trials")
  for id,t in pairs(Trials) do
   self:Button(self.Content,(p.Quests.Trials[id] and "✓  " or "")..t.Name.."   •   "..t.Sector,function() self:Send("Trial",id) end,Icons.Get("System","Quests"))
  end

 elseif name=="Settings" then
  self:Section(self.Content,"Интерфейс и эффекты")
  for _,id in ipairs({"ReducedEffects","ShowOtherPollinators","HideOtherPlayersTokens","RareFeed","AutoDissolve"}) do
   local on=p.Settings[id]==true
   self:Button(self.Content,(SETTINGS_NAMES[id] or id).."   •   "..(on and "ВКЛ" or "ВЫКЛ"),function() self:Send("Setting",id,not on) end,Icons.Get("System",on and "Confirm" or "Minus"))
  end
  self:Button(self.Content,"Громкость активностей   •   "..math.floor((p.Settings.TokenSoundVolume or 0)*100).."%",function() self:Send("Setting","TokenSoundVolume",(p.Settings.TokenSoundVolume+.25)%1.25) end,Icons.Get("System","Info"))
  if p.WorkshopV5.Nodes.ECONOMY_2 then
   self:Section(self.Content,"Фильтр авторастворения")
   for _,rarity in ipairs(R.Order) do
    local on=p.Settings.DissolveRarities[rarity]==true
    self:Button(self.Content,"Dissolve "..rarity.."   •   "..(on and "ВКЛ" or "ВЫКЛ"),function() self:Send("DissolveFilter",rarity) end,Icons.Get("WorkshopHex","Duplicate"))
   end
  end
  self:Section(self.Content,"Обучение")
  self:Button(self.Content,"Пропустить обучение",function() self:Send("Skip") end,Icons.Get("System","Warning"))
  self:Button(self.Content,"Повторить подсказки",function() self:Send("Replay") end,Icons.Get("System","Tutorial"))

 elseif name=="Season" then
  local preview=self.MenuArg
  self:Section(self.Content,"Что сохранится")
  self:Label(self.Content,table.concat(preview.Keep,", "),38)
  self:Section(self.Content,"Изменения")
  for _,diff in ipairs(preview.Diff) do self:Label(self.Content,diff.Path..":  "..tostring(diff.Before).."  →  "..tostring(diff.After),38) end
  self:Button(self.Content,self.SeasonSecond and "ПОДТВЕРДИТЬ СБРОС СЕЗОНА" or "Продолжить",function() self:Send("SeasonConfirm",preview.Token) end,Icons.Get("System",self.SeasonSecond and "Warning" or "Confirm"))

 elseif name=="Replay" then
  local i=self.ReplayIndex or 1
  self.ReplayIndex=i
  self:Section(self.Content,"Шаг "..i.." из "..#T.Steps)
  self:Label(self.Content,T.Steps[i].Text,38)
  self:Button(self.Content,"Следующий шаг",function() self.ReplayIndex=i%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowRight"))
  self:Button(self.Content,"Предыдущий шаг",function() self.ReplayIndex=(i-2)%#T.Steps+1 self:RenderMenu() end,Icons.Get("System","ArrowLeft"))

 elseif name=="Cards" then
  self:Section(self.Content,"Выбор карты")
  for _,id in ipairs(self.State.Cards) do self:Button(self.Content,id,function() self:Send("Card",id) self:Close() end,Icons.Get("System","Confirm")) end
 end
end

function UI:ApplySafeArea()
 if not self.Gui or not self.SafeRoot then return end
 self.SafeRoot.Position=UDim2.fromScale(0,0)
 self.SafeRoot.Size=UDim2.fromScale(1,1)
 local size=self.SafeRoot.AbsoluteSize
 local camera=Workspace.CurrentCamera
 local viewport=camera and camera.ViewportSize or Vector2.new(1366,768)
 local safeW=size.X>100 and size.X or viewport.X
 local safeH=size.Y>100 and size.Y or viewport.Y
 self:ApplyResponsiveLayout(math.max(320,safeW),math.max(360,safeH))
end

function UI:ApplyResponsiveLayout(width,height)
 -- Desktop layout is authored in StarterGui. Do not overwrite positions/sizes here,
 -- so designers can move every HUD block directly in Studio.
 self.IsMobileLayout=width<700
 if width>=700 then return end

 -- Small-screen safety only. These adjustments intentionally touch as little as possible.
 self.ObjectiveCard.Size=UDim2.fromOffset(math.max(280,width-24),66)
 self.CurrencyHUD.Position=UDim2.fromOffset(10,208)
 self.Dock.AnchorPoint=Vector2.new(1,.5)
 self.Dock.Position=UDim2.new(1,-10,.56,0)
 self.Guide.Size=UDim2.fromOffset(math.max(260,width-24),38)
 self.RollHUD.Size=UDim2.fromOffset(math.min(300,width-18),38)
 self.RollHUD.AnchorPoint=Vector2.new(.5,1)
 self.RollHUD.Position=UDim2.new(.5,0,1,-62)
 self.Roll.AnchorPoint=Vector2.new(.5,1)
 self.Roll.Position=UDim2.new(.5,0,1,-10)
 self.RouletteViewport.AnchorPoint=Vector2.new(.5,0)
 self.RouletteViewport.Position=UDim2.new(.5,0,0,78)
 self.ToastRoot.Size=UDim2.fromOffset(math.max(260,width-24),36)
 self.Panel.Size=UDim2.fromOffset(math.max(300,width-16),math.max(300,height-108))
 self.Panel.Position=UDim2.new(.5,0,.52,0)
 self.Reveal.Size=UDim2.fromOffset(math.max(280,width-24),100)
end

function UI:Render()
 self.ObjectiveCard.Visible=true
 self.CurrencyHUD.Visible=true
 local p=self.State.Profile
 local step=T.Steps[p.Tutorial.Step]
 if step then
  self.ObjectiveTitle.Text="ОБУЧЕНИЕ  •  "..p.Tutorial.Step.."/"..#T.Steps
  self.ObjectiveText.Text=step.Text
  self.ObjectiveProgressFill.Size=UDim2.fromScale(math.clamp((p.Tutorial.Step-1)/#T.Steps,0,1),1)
  self.ObjectiveProgress.Visible=true
 else
  self.ObjectiveTitle.Text="JOURNEY  •  ШАГ "..tostring(p.Quests.JourneyStep or 1)
  self.ObjectiveText.Text=JOURNEY[p.Quests.JourneyStep] or "Продолжай развивать сад"
  self.ObjectiveProgress.Visible=false
 end

 self.CurrencyRows.Coins.Value.Text=compact(p.Currencies.Coins)
 self.CurrencyRows.Honey.Value.Text=compact(p.Hive.Honey)
 self.CurrencyRows.Hive.Value.Text="Уровень "..tostring(p.Hive.Level)
 self.CurrencyRows.PetalDust.Value.Text=compact(p.Currencies.PetalDust)
 self.CurrencyRows.PetalDust.Root.Visible=p.Tutorial.FeatureUnlocks.SeedSatchel==true
 self.CurrencyRows.AncientNectar.Value.Text=compact(p.Currencies.AncientNectar)
 self.CurrencyRows.AncientNectar.Root.Visible=(p.Season.Count or 0)>0 or (p.Currencies.AncientNectar or 0)>0

 local rollUnlocked=p.Tutorial.FeatureUnlocks.Roll==true
 self.RollHUD.Visible=rollUnlocked
 self.Roll.Visible=rollUnlocked
 self.RouletteViewport.Visible=rollUnlocked
 if not rollUnlocked and self.Auto then
  self.Auto=false
  self:StopRouletteAnimation()
 end

 local special=p.RollState.SpecialRollReady==true
 if self.Auto then
  self.Roll.Text=""
  self.Roll.BackgroundTransparency=1
  self.RollStroke.Color=C.Green
  self.RollIcon.Image=Icons.GetActionIcon("AutoRoll")
 else
  self.Roll.Text=""
  self.Roll.BackgroundTransparency=1
  self.RollStroke.Color=special and C.Gold or C.Blue
  self.RollIcon.Image=Icons.GetActionIcon("Roll")
 end
 self.RollIcon.ImageColor3=C.White
 if self.RollStatusDot then
  self.RollStatusDot.BackgroundColor3=self.Auto and C.Green or C.Faint
 end
 if self.Auto and not self.RouletteRunning and not self.RouletteLanding then self:StartRouletteAnimation() end

 local charge=math.clamp(tonumber(p.RollState.BloomCharge) or 0,0,100)
 local pity=math.min(30,tonumber(p.RollState.DiscoveryPity) or 0)
 self.MeterLabel.Text=string.format("BLOOM  %.0f%%     •     DISCOVERY  %d/30",charge,pity)..(p.WorkshopV5.Nodes.ROLL_4 and pity>=29 and "  •  NEW GUARANTEED" or "")
 self.BloomFill.Size=UDim2.fromScale(charge/100,1)
 self.MeterArea.Visible=rollUnlocked and (p.Tutorial.Step>=10 or p.Tutorial.Skipped)

 for name,b in pairs(self.DockButtons) do b.Visible=name=="Settings" or p.Tutorial.FeatureUnlocks[name]==true end
 self.GuideController:Update()
 self.GardenPresentation:Update()
end

function UI:RollNow(automatic)
 if self.Pending or self.RouletteLanding or (self.Rewards and self.Rewards.Busy) or os.clock()<self.NextRoll or not self.State then return end
 self.Pending=true
 self.PendingAt=os.clock()
 self:Send("Roll",automatic==true)
end

function UI:BuildRouletteVisualPool(preserveCursor)
 local previous=nil
 if preserveCursor and self.RouletteVisualPool and self.RouletteCursor then
  previous=self.RouletteVisualPool[self.RouletteCursor]
 end
 local pool={}
 local serverPool=self.State and self.State.Odds
 if type(serverPool)=="table" and #serverPool>0 then
  for _,item in ipairs(serverPool) do
   local icon=item.Kind=="Bee" and Icons.GetBeeIcon(item.Id or "") or Icons.GetFlowerIcon(item.Id or "")
   if icon=="" then icon=Icons.Get("System",item.Kind=="Bee" and "Bee" or "Flower") end
   table.insert(pool,{
    Id=item.Id,Kind=item.Kind,DisplayName=item.DisplayName or item.Id,Rarity=item.Rarity or "Common",
    Icon=icon,Weight=item.Weight,Odds=item.Odds,Chance=item.Chance,
   })
  end
 else
  local totalWeight=0
  for id,data in pairs(F.Species) do
   local icon=Icons.GetFlowerIcon(id) if icon=="" then icon=Icons.Get("System","Flower") end
   local weight=math.max(0,tonumber(data.DropWeight) or 0) totalWeight=totalWeight+weight
   table.insert(pool,{Id=id,Kind="FlowerSeed",DisplayName=data.DisplayName or id,Rarity=data.Rarity or "Common",Icon=icon,Weight=weight})
  end
  for id,data in pairs(B.Bees) do
   local weight=math.max(0,tonumber(data.DropWeight) or 0) totalWeight=totalWeight+weight
   table.insert(pool,{Id=id,Kind="Bee",DisplayName=data.DisplayName or id,Rarity=data.Rarity or "Common",Icon=Icons.GetBeeIcon(id),Weight=weight})
  end
  for _,item in ipairs(pool) do item.Odds=item.Weight>0 and totalWeight/item.Weight or math.huge end
 end
 table.sort(pool,function(a,b)
  local ar=R.Rank[a.Rarity] or 1 local br=R.Rank[b.Rarity] or 1
  if ar==br then return tostring(a.DisplayName)<tostring(b.DisplayName) end
  return ar<br
 end)
 self.RouletteVisualPool=pool
 local cursor=1
 if previous then
  for i,item in ipairs(pool) do if item.Kind==previous.Kind and item.Id==previous.Id then cursor=i break end end
 end
 self.RouletteCursor=math.clamp(cursor,1,math.max(1,#pool))
 self:RefreshRouletteSlots()
end

function UI:SetRouletteSlot(slot,data,role)
 if not slot or not data then return end
 local icon=slot:FindFirstChild("Icon")
 local name=slot:FindFirstChild("Name")
 local chance=slot:FindFirstChild("Chance")
 local color=R.Colors[data.Rarity] or C.Muted
 local current=role=="Current"
 local faint=role=="Buffer" and .55 or current and 0 or .32
 local marker=slot:FindFirstChild("CurrentMarker") or slot:FindFirstChild("SelectionMarker")
 if marker and marker:IsA("GuiObject") then marker.Visible=current end
 if icon and icon:IsA("ImageLabel") then
  icon.Image=data.Icon or ""
  icon.ImageTransparency=faint
 end
 if name and name:IsA("TextLabel") then
  name.Text=data.DisplayName or data.Id or "?"
  name.TextTransparency=faint
  name.TextSize=current and 13 or 12
  name.TextColor3=current and C.Text or Color3.new(.86,.9,.95)
 end
 if chance and chance:IsA("TextLabel") then
  local odds=tonumber(data.Odds)
  chance.Text=odds and odds<math.huge and ("1 / "..compact(math.max(1,math.floor(odds+.5)))) or "1 / ∞"
  chance.TextColor3=current and C.Gold or color
  chance.TextTransparency=faint
  chance.TextSize=current and 10 or 9
 end
 local scale=slot:FindFirstChild("SlotScale")
 if not scale then
  scale=Instance.new("UIScale")
  scale.Name="SlotScale"
  scale.Parent=slot
 end
 scale.Scale=current and 1.04 or .92
end

function UI:RouletteIndex(offset)
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 then return 1 end
 return ((self.RouletteCursor-1+offset)%#pool)+1
end

function UI:EnsureRouletteRuntimeBuffer()
 if self.RouletteBuffer and self.RouletteBuffer.Parent==self.RouletteStrip then return self.RouletteBuffer end
 if not self.RouletteStrip or not self.RouletteSlots or not self.RouletteSlots.Next then return nil end
 local stale=self.RouletteStrip:FindFirstChild("Buffer") or self.RouletteStrip:FindFirstChild("_RuntimeBuffer")
 if stale then stale:Destroy() end
 local source=self.RouletteSlots.Next
 local buffer=source:Clone()
 buffer.Name="_RuntimeBuffer"
 buffer.Position=UDim2.new(source.Position.X.Scale,source.Position.X.Offset,source.Position.Y.Scale,source.Position.Y.Offset-(RollAudio.StepPixels or 48))
 buffer.Visible=true
 buffer.Parent=self.RouletteStrip
 self.RouletteBuffer=buffer
 return buffer
end

function UI:RefreshRouletteSlots()
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 or not self.RouletteSlots then return end
 local buffer=self:EnsureRouletteRuntimeBuffer()
 if buffer then self:SetRouletteSlot(buffer,pool[self:RouletteIndex(2)],"Buffer") end
 self:SetRouletteSlot(self.RouletteSlots.Next,pool[self:RouletteIndex(1)],"Next")
 self:SetRouletteSlot(self.RouletteSlots.Current,pool[self:RouletteIndex(0)],"Current")
 self:SetRouletteSlot(self.RouletteSlots.Previous,pool[self:RouletteIndex(-1)],"Previous")
end

function UI:PlayRouletteTick()
 local s=self.RouletteSpinSound
 if not s then return end
 s:Stop() s.TimePosition=0
 local master=self.State and self.State.Profile.Settings.TokenSoundVolume or .5
 s.Volume=RollAudio.SpinVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.SpinPlaybackSpeed+Random.new():NextNumber(-.06,.06)
 s:Play()
end

function UI:PlayRouletteRewardSound()
 local s=self.RouletteRewardSound
 if not s then return end
 s:Stop() s.TimePosition=0
 local master=self.State and self.State.Profile.Settings.TokenSoundVolume or .5
 s.Volume=RollAudio.RewardVolume*math.clamp(master*2,0,1)
 s.PlaybackSpeed=RollAudio.RewardPlaybackSpeed s:Play()
end

function UI:StepRoulette(duration,targetIndex,generation)
 local pool=self.RouletteVisualPool
 if not pool or #pool==0 or not self.RouletteStrip then return false end
 if targetIndex then
  self.RouletteCursor=((targetIndex-2)%#pool)+1
  self:RefreshRouletteSlots()
 end
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 local tween=TweenService:Create(self.RouletteStrip,TweenInfo.new(duration,Enum.EasingStyle.Linear),{Position=UDim2.fromOffset(0,RollAudio.StepPixels)})
 self.RouletteTween=tween self:PlayRouletteTick() tween:Play() tween.Completed:Wait()
 if generation and generation~=self.RouletteGeneration then return false end
 if self.RouletteTween==tween then self.RouletteTween=nil end
 if targetIndex then self.RouletteCursor=targetIndex else self.RouletteCursor=(self.RouletteCursor%#pool)+1 end
 self.RouletteStrip.Position=UDim2.fromOffset(0,0)
 self:RefreshRouletteSlots()
 return true
end

function UI:StartRouletteAnimation()
 if self.RouletteRunning or self.RouletteLanding or not self.RouletteStrip then return end
 self.RouletteRunning=true self.RouletteGeneration=self.RouletteGeneration+1
 local generation=self.RouletteGeneration
 task.spawn(function()
  while self.RouletteRunning and not self.RouletteLanding and generation==self.RouletteGeneration and self.Gui and self.Gui.Parent do
   if not self:StepRoulette(RollAudio.CruiseStep,nil,generation) then break end
  end
  if generation==self.RouletteGeneration and self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
  if generation==self.RouletteGeneration then self.RouletteTween=nil end
 end)
end

function UI:StopRouletteAnimation()
 self.RouletteRunning=false self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 if self.RouletteStrip then self.RouletteStrip.Position=UDim2.fromOffset(0,0) end
 self:RefreshRouletteSlots()
end

function UI:SetAutoRolling(enabled)
 if enabled and (not self.State or self.State.Profile.Tutorial.FeatureUnlocks.Roll~=true) then return end
 self.Auto=enabled==true
 if self.Auto then
  if not self.RouletteLanding then self:StartRouletteAnimation() end
  task.defer(function() self:RollNow(true) end)
 else
  if not self.RouletteLanding then self:StopRouletteAnimation() else self.RouletteRunning=false end
 end
 if self.State then self:Render() end
end

function UI:FindRouletteTarget(payload)
 local pool=self.RouletteVisualPool or {}
 for i,item in ipairs(pool) do if item.Kind==payload.Kind and item.Id==payload.Id then return i end end
 local icon=payload.Kind=="Bee" and Icons.GetBeeIcon(payload.Id or "") or Icons.GetFlowerIcon(payload.Id or "")
 if icon=="" then icon=Icons.Get("System",payload.Kind=="Bee" and "Bee" or "Flower") end
 table.insert(pool,{Id=payload.Id,Kind=payload.Kind,DisplayName=payload.DisplayName or payload.Id or "Reward",Rarity=payload.Rarity or "Common",Icon=icon,Odds=payload.Odds,Chance=payload.Chance})
 self.RouletteVisualPool=pool return #pool
end

function UI:AnimateRouletteResult()
 local slot=self.RouletteSlots and self.RouletteSlots.Current if not slot then return end
 local scale=slot:FindFirstChild("SlotScale")
 local icon=slot:FindFirstChild("Icon")
 if scale then
  scale.Scale=1.04
  local pop=TweenService:Create(scale,TweenInfo.new(.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Scale=1.18}) pop:Play() pop.Completed:Wait()
  TweenService:Create(scale,TweenInfo.new(.20,Enum.EasingStyle.Sine,Enum.EasingDirection.Out),{Scale=1.04}):Play()
 end
 if icon and icon:IsA("ImageLabel") then
  icon.Rotation=-7
  local swing=TweenService:Create(icon,TweenInfo.new(.16,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut,1,true),{Rotation=7}) swing:Play() swing.Completed:Wait() icon.Rotation=0
 end
end

function UI:ResolveRouletteReward(payload)
 if type(payload)~="table" or self.RouletteLanding then return end
 self.RouletteLanding=true self.RouletteRunning=false self.RouletteGeneration=self.RouletteGeneration+1
 if self.RouletteTween then self.RouletteTween:Cancel() self.RouletteTween=nil end
 local generation=self.RouletteGeneration
 task.spawn(function()
  local visualStart=os.clock()
  local target=self:FindRouletteTarget(payload)
  local steps=RollAudio.SettleSteps
  for i,duration in ipairs(steps) do
   if generation~=self.RouletteGeneration then break end
   local final=i==#steps
   if not self:StepRoulette(duration,final and target or nil,nil) then break end
  end
  if generation==self.RouletteGeneration then
   local remaining=math.max(0,(RollAudio.MinimumVisualSpin or 0)-(os.clock()-visualStart))
   if remaining>0 then task.wait(remaining) end
   self:PlayRouletteRewardSound()
   self:AnimateRouletteResult()
   task.wait(RollAudio.ResultHold)
  end
  self.RouletteLanding=false
  if self.Rewards then self.Rewards:Enqueue(payload) end
  if self.Auto then self:StartRouletteAnimation() end
 end)
end

function UI:BindStaticUI()
 local root=self.SafeRoot
 self.ObjectiveCard=root:WaitForChild("ObjectiveCard")
 self.ObjectiveTitle=self.ObjectiveCard:WaitForChild("ObjectiveTitle")
 self.ObjectiveText=self.ObjectiveCard:WaitForChild("ObjectiveText")
 self.ObjectiveProgress=self.ObjectiveCard:WaitForChild("ObjectiveProgress")
 self.ObjectiveProgressFill=self.ObjectiveProgress:WaitForChild("ObjectiveProgressFill")

 self.CurrencyHUD=root:WaitForChild("CurrencyHUD")
 self.CurrencyLayout=self.CurrencyHUD:FindFirstChildOfClass("UIListLayout")
 self.CurrencyRows={}
 local currencyColors={Coins=C.Gold,Honey=C.Honey,Hive=C.Green,PetalDust=C.Dust,AncientNectar=C.Nectar}
 local currencyIcons={Coins=Icons.GetCurrencyIcon("Coins"),Honey=Icons.Get("System","Hive"),Hive=Icons.Get("System","Hive"),PetalDust=Icons.GetCurrencyIcon("PetalDust"),AncientNectar=Icons.Get("System","Flower")}
 for _,key in ipairs({"Coins","Honey","Hive","PetalDust","AncientNectar"}) do
  local row=self.CurrencyHUD:WaitForChild(key)
  local iconRoot=row:FindFirstChild("IconBg")
  local icon=iconRoot and iconRoot:FindFirstChild("Icon") or row:FindFirstChild("Icon")
  if icon and icon:IsA("ImageLabel") then icon.Image=currencyIcons[key] or "" end
  local accent=row:FindFirstChild("Accent")
  if accent and accent:IsA("Frame") then accent.BackgroundColor3=currencyColors[key] end
  self.CurrencyRows[key]={Root=row,Title=row:WaitForChild("Title"),Value=row:WaitForChild("Value"),Icon=icon,Color=currencyColors[key]}
 end

 self.Dock=root:WaitForChild("MenuDock")
 self.DockLayout=self.Dock:FindFirstChildOfClass("UIListLayout")
 self.DockButtons={}
 self.DockTooltips={}
 for _,name in ipairs({"SeedSatchel","Workshop","FieldGuide","Map","Trials","Settings"}) do
  local button=self.Dock:WaitForChild("Dock_"..name)
  local tip=button:WaitForChild("Tooltip")
  tip.Text=MENU_NAMES[name] or name
  local icon=button:FindFirstChild("Icon")
  local image=Icons.Get("Menus",name)
  if image=="" and name=="Map" then image=Icons.Get("System","Garden") end
  if icon and icon:IsA("ImageLabel") then icon.Image=image end
  button.MouseEnter:Connect(function() tip.Visible=true TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelHover}):Play() end)
  button.MouseLeave:Connect(function() tip.Visible=false TweenService:Create(button,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Panel}):Play() end)
  button.Activated:Connect(function() self:Open(name) end)
  self.DockButtons[name]=button
  self.DockTooltips[name]=tip
 end

 self.RollHUD=root:WaitForChild("RollHUD")
 self.RouletteViewport=root:WaitForChild("VerticalRoulette")
 self.RouletteClip=self.RouletteViewport:FindFirstChild("RouletteClip")
 self.RouletteStrip=self.RouletteClip and self.RouletteClip:WaitForChild("ReelStrip") or self.RouletteViewport:WaitForChild("ReelStrip")
 self.RouletteSlots={
  Next=self.RouletteStrip:WaitForChild("Next"),
  Current=self.RouletteStrip:WaitForChild("Current"),
  Previous=self.RouletteStrip:WaitForChild("Previous"),
 }
 local staleBuffer=self.RouletteStrip:FindFirstChild("Buffer") or self.RouletteStrip:FindFirstChild("_RuntimeBuffer")
 if staleBuffer then staleBuffer:Destroy() end
 self.RouletteBuffer=nil
 self:EnsureRouletteRuntimeBuffer()
 self.RouletteSpinSound=Instance.new("Sound") self.RouletteSpinSound.Name="SpinSound" self.RouletteSpinSound.SoundId=RollAudio.SpinSound self.RouletteSpinSound.Volume=RollAudio.SpinVolume self.RouletteSpinSound.Parent=self.RouletteViewport
 self.RouletteRewardSound=Instance.new("Sound") self.RouletteRewardSound.Name="RewardSound" self.RouletteRewardSound.SoundId=RollAudio.RewardSound self.RouletteRewardSound.Volume=RollAudio.RewardVolume self.RouletteRewardSound.Parent=self.RouletteViewport
 self.MeterArea=self.RollHUD:WaitForChild("MeterArea")
 self.MeterLabel=self.MeterArea:WaitForChild("MeterLabel")
 self.BloomTrack=self.MeterArea:WaitForChild("BloomTrack")
 self.BloomFill=self.BloomTrack:WaitForChild("BloomFill")
 self.Roll=root:FindFirstChild("RollButton") or root:WaitForChild("TutorialRollButton")
 self.RollStroke=self.Roll:FindFirstChildOfClass("UIStroke")
 self.RollIcon=self.Roll:WaitForChild("Icon")
 self.RollStatusDot=self.Roll:FindFirstChild("StatusDot")
 self.Roll.Activated:Connect(function() self:SetAutoRolling(not self.Auto) end)
 self.Roll.MouseEnter:Connect(function()
  if not self.Roll.Visible then return end
  local target=self.Auto and C.Green or (self.State and self.State.Profile.RollState.SpecialRollReady and C.Green or C.Blue)
  TweenService:Create(self.Roll,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=target}):Play()
 end)
 self.Roll.MouseLeave:Connect(function() if self.State then self:Render() end end)

 self.Guide=root:WaitForChild("TutorialGuideBanner")
 self.ToastRoot=root:WaitForChild("Toast")
 self.ToastScale=self.ToastRoot:FindFirstChild("ToastScale") or self.ToastRoot:FindFirstChildOfClass("UIScale")
 self.ToastLabel=self.ToastRoot:WaitForChild("ToastLabel")

 self.ModalShade=root:WaitForChild("ModalShade")
 self.Panel=root:WaitForChild("MainPanel")
 self.PanelScale=self.Panel:FindFirstChild("PanelScale") or self.Panel:FindFirstChildOfClass("UIScale")
 local header=self.Panel:WaitForChild("Header")
 self.PanelHeaderIcon=header:FindFirstChild("HeaderIcon")
 self.PanelTitle=header:WaitForChild("PanelTitle")
 self.PanelSubtitle=header:WaitForChild("PanelSubtitle")
 local close=header:WaitForChild("Close")
 close.Activated:Connect(function() self:Close() end)
 close.MouseEnter:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.Danger}):Play() end)
 close.MouseLeave:Connect(function() TweenService:Create(close,TweenInfo.new(Theme.Motion.Fast),{BackgroundColor3=C.PanelRaised}):Play() end)
 self.Content=self.Panel:WaitForChild("Content")
 self.ContentLayout=self.Content:FindFirstChildOfClass("UIListLayout")
 self.Templates=self.Panel:FindFirstChild("Templates")

 self.Reveal=root:WaitForChild("RewardReveal")
 self.RewardStroke=self.Reveal:FindFirstChildOfClass("UIStroke")
 self.RevealScale=self.Reveal:FindFirstChild("RevealScale") or self.Reveal:FindFirstChildOfClass("UIScale")
 self.RewardStripe=self.Reveal:WaitForChild("RewardStripe")
 self.RewardIcon=self.Reveal:WaitForChild("RewardIcon")
 self.RewardTitle=self.Reveal:WaitForChild("RewardTitle")
 self.RewardMeta=self.Reveal:WaitForChild("RewardMeta")
 self.RewardHint=self.Reveal:WaitForChild("RewardHint")
 self.Reveal.Activated:Connect(function() if self.Rewards then self.Rewards:SkipCurrent() end end)

 self:BuildRouletteVisualPool()
 self:RefreshRouletteSlots()
end

function UI:ResolveBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")

 local function collect()
  local found={}
  for _,child in ipairs(playerGui:GetChildren()) do
   if child.Name=="BloomUI" and child:IsA("ScreenGui") then
    table.insert(found,child)
   end
  end
  return found
 end

 local function keepSingle(preferred)
  for _,gui in ipairs(collect()) do
   if gui~=preferred then
    warn("[BloomUI] Removing duplicate PlayerGui/BloomUI:",gui:GetFullName())
    gui:Destroy()
   end
  end
  return preferred
 end

 -- Prefer Roblox's normal StarterGui -> PlayerGui clone. This preserves the
 -- exact authored StarterGui tree and avoids creating a second HUD in Studio.
 local existingList=collect()
 if #existingList>0 then
  local existing=existingList[#existingList]
  print("[BloomUI] Using existing PlayerGui/BloomUI; copies:",#existingList)
  return keepSingle(existing)
 end

 -- Give Roblox a short window to perform its normal clone before falling back.
 local deadline=os.clock()+1.5
 repeat
  task.wait(.05)
  existingList=collect()
  if #existingList>0 then
   local existing=existingList[#existingList]
   print("[BloomUI] PlayerGui/BloomUI appeared after wait; copies:",#existingList)
   return keepSingle(existing)
  end
 until os.clock()>=deadline

 -- Rojo live-sync can add BloomUI to StarterGui after the player spawned. In
 -- that one case Roblox will not back-fill PlayerGui, so clone exactly once.
 local template=StarterGui:FindFirstChild("BloomUI") or StarterGui:WaitForChild("BloomUI",8)
 if template and template:IsA("ScreenGui") then
  -- Re-check immediately before cloning in case the engine won the race.
  existingList=collect()
  if #existingList>0 then
   local existing=existingList[#existingList]
   return keepSingle(existing)
  end
  local clone=template:Clone()
  clone.Name="BloomUI"
  clone:SetAttribute("BloomRuntimeClone",true)
  clone.Parent=playerGui
  print("[BloomUI] Created one fallback PlayerGui/BloomUI from StarterGui")
  return keepSingle(clone)
 end

 error("[BloomUI] BloomUI is missing from both PlayerGui and StarterGui")
end

function UI:GuardBloomGui()
 local playerGui=self.Player:WaitForChild("PlayerGui")
 self.Gui:SetAttribute("BloomAuthoritative",true)
 local function removeDuplicate(child)
  if child~=self.Gui and child:IsA("ScreenGui") and child.Name=="BloomUI" then
   warn("[BloomUI] Destroying late duplicate HUD:",child:GetFullName())
   child:Destroy()
  end
 end
 for _,child in ipairs(playerGui:GetChildren()) do removeDuplicate(child) end
 self.GuiGuardConnection=playerGui.ChildAdded:Connect(function(child)
  if child.Name~="BloomUI" or not child:IsA("ScreenGui") then return end
  task.defer(function()
   if child.Parent==playerGui and self.Gui and self.Gui.Parent==playerGui then removeDuplicate(child) end
  end)
 end)
end

function UI:ApplyState(payload,source)
 if type(payload)~="table" or type(payload.Profile)~="table" then
  warn("[BloomUI] Ignoring invalid state payload from",source or "unknown")
  return false
 end
 local firstState=self.State==nil
 self.State=payload
 if firstState then
  self.ObjectiveCard.Visible=true
  self.CurrencyHUD.Visible=true
  self.Dock.Visible=true
 end
 if not self.RouletteLanding then self:BuildRouletteVisualPool(true) end
 self:Render()
 if firstState then print("[BloomUI] State applied:",source or "Event") end
 return true
end

function UI:Start()
 print("[BloomUI] Starting client build:",CLIENT_BUILD)
 self.Player:SetAttribute("BloomClientReady",false)
 self.Player:GetAttributeChangedSignal("BloomProfileState"):Connect(function()
  local status=self.Player:GetAttribute("BloomProfileState")
  if status then print("[BloomUI] Profile state attribute:",status) end
 end)
 local remotes=RS:WaitForChild("BloomRemotes")
 self.Request=remotes:WaitForChild("Request")
 self.StateRequest=remotes:WaitForChild("StateRequest")
 local event=remotes:WaitForChild("Event")
 self.Gui=self:ResolveBloomGui()
 self:GuardBloomGui()
 self.SafeRoot=self.Gui:WaitForChild("SafeRoot",10)
 if not self.SafeRoot then error("[BloomUI] BloomUI exists, but SafeRoot is missing") end
 self:BindStaticUI()

 self.Rewards=require(script.Parent.RewardPresentationController)
 self.Rewards:Init(self)
 self.Activities=require(script.Parent.ActivityController)
 self.Activities:Init(self)
 self.Bees=require(script.Parent.PollinatorController)
 self.Bees:Init(self)
 self.GuideController=require(script.Parent.TutorialGuideController)
 self.GuideController:Init(self)
 self.GardenPresentation=require(script.Parent.GardenPresentationController)
 self.GardenPresentation:Init(self)

 event.OnClientEvent:Connect(function(kind,payload)
  if kind=="State" then
   self:ApplyState(payload,"Event")
  elseif kind=="Ack" then
   if payload.Action=="Roll" then
    self.Pending=false
    self.NextRoll=math.max(self.NextRoll,os.clock()+.2)
    if self.State then self:Render() end
   end
   if not payload.OK then
    if payload.Action=="Roll" and self.Auto then self:SetAutoRolling(false) end
    if not (payload.Action=="Ready" and payload.Reason=="PROFILE_LOADING") then
     self:Toast(payload.Reason or "Действие пока недоступно")
    end
   end
   if self.Menu and payload.Action~="Menu" and payload.Action~="Roll" and payload.Action~="Ready" then task.defer(function() self:RenderMenu() end) end
  elseif kind=="TokenCollected" then
   if self.State then
    local volume=self.State.Profile.Settings.TokenSoundVolume
    if volume>0 then
     local sound=Instance.new("Sound")
     sound.SoundId=require(RS.Config.ActivityConfig).TokenSound
     sound.Volume=volume*(self.State.Profile.Settings.ReducedEffects and .5 or 1)
     sound.Parent=self.Gui
     sound:Play()
     game:GetService("Debris"):AddItem(sound,3)
    end
   end
  elseif kind=="Reward" then
   self.NextRoll=os.clock()+payload.Cooldown
   self:ResolveRouletteReward(payload)
  elseif kind=="PlantPicker" then self:Open("Plant",payload)
  elseif kind=="Activities" then self.Activities:Update(payload)
  elseif kind=="OtherTokens" then self.Activities:Others(payload)
  elseif kind=="Bees" then self.Bees:Update(payload)
  elseif kind=="Message" then self:Toast(payload)
  elseif kind=="Open" then task.defer(function() self:Open(payload) end)
  elseif kind=="Trials" then self:Open("Trials",payload)
  elseif kind=="RareFeed" then if self.State and self.State.Profile.Settings.RareFeed then self:Toast(payload.Player.." • "..payload.Name) end
  elseif kind=="Ceremony" then
   if self.State then self.Rewards:Enqueue({Kind="Ceremony",Ceremony=payload.Kind,DisplayName=payload.Text,Rarity=payload.Kind=="Season" and "Mythic" or "Epic",Chance=1}) end
   self:Toast(payload.Text)
   if payload.Kind=="Season" then self:Close() end
  elseif kind=="SeasonPreview" then self.SeasonSecond=false self:Open("Season",payload)
  elseif kind=="SeasonConfirm" then self.SeasonSecond=true self:RenderMenu()
  elseif kind=="Cards" then task.defer(function() self:Open("Cards") end)
  elseif kind=="Replay" then self.ReplayIndex=1 self:Open("Replay") end
 end)
 self.Player:SetAttribute("BloomClientReady",true)
 print("[BloomUI] Client listener ready:",CLIENT_BUILD)

 UIS.InputBegan:Connect(function(input,processed)
  if processed then return end
  if input.KeyCode==Enum.KeyCode.M then self.Dock.Visible=not self.Dock.Visible
  elseif input.KeyCode==Enum.KeyCode.Escape and self.Menu then self:Close() end
 end)

 local cameraConnection=nil
 local function bindCamera()
  if cameraConnection then cameraConnection:Disconnect() cameraConnection=nil end
  local camera=Workspace.CurrentCamera
  if camera then cameraConnection=camera:GetPropertyChangedSignal("ViewportSize"):Connect(function() self:ApplySafeArea() end) end
  task.defer(function() self:ApplySafeArea() end)
 end
 Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(bindCamera)
 self.SafeRoot:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
  local size=self.SafeRoot.AbsoluteSize
  if size.X>100 and size.Y>100 then self:ApplyResponsiveLayout(size.X,size.Y) end
 end)
 bindCamera()

 task.spawn(function()
  local started=os.clock()
  local lastStatus=nil
  local attempts=0
  while self.Gui.Parent and not self.State do
   attempts=attempts+1
   local ok,payload,reason=pcall(function() return self.StateRequest:InvokeServer() end)
   if ok and payload then
    if self:ApplyState(payload,"StateRequest") then
     self:Send("Ready")
     break
    end
   elseif not ok then
    if attempts==1 or attempts%8==0 then warn("[BloomUI] StateRequest failed:",payload) end
   elseif reason and reason~="PROFILE_LOADING" then
    warn("[BloomUI] StateRequest rejected:",reason)
   end
   self:Send("Ready")
   local status=self.Player:GetAttribute("BloomProfileState")
   if status~=lastStatus then
    lastStatus=status
    if status then print("[BloomUI] Profile state:",status) end
    if status=="Active" and self.ObjectiveTitle and self.ObjectiveText then
     self.ObjectiveTitle.Text="СИНХРОНИЗАЦИЯ"
     self.ObjectiveText.Text="Профиль загружен. Получаем состояние игры…"
    end
   end
   if os.clock()-started>20 then
    local profileError=self.Player:GetAttribute("BloomProfileError")
    warn("[BloomUI] Still waiting for authoritative state",status,profileError)
    self:Toast(profileError and ("Профиль: "..tostring(profileError)) or "Состояние профиля всё ещё синхронизируется…")
    started=os.clock()+9999
   end
   task.wait(.75)
  end
 end)
 task.spawn(function()
  while self.Gui.Parent do
   task.wait(.1)
   for id,item in pairs(self.Activities.Items) do
    if workspace:GetServerTimeNow()>item.Expires then item.Part:Destroy() self.Activities.Items[id]=nil end
   end
   if self.Auto and not self.Pending and not self.RouletteLanding then self:RollNow(true) end
   if self.Pending and os.clock()-self.PendingAt>15 then
    self.Pending=false
    self.Auto=false
    self:StopRouletteAnimation()
    self:Toast("Ответ сервера задержался. Auto выключен.")
    if self.State then self:Render() end
   end
   if self.State then self.GuideController:Update() end
   if self.ToastUntil and os.clock()>self.ToastUntil then self.ToastRoot.Visible=false self.ToastUntil=nil end
  end
 end)
end

return UI
