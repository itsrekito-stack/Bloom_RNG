local RS=game:GetService("ReplicatedStorage")
local F=require(RS.Config.FlowersConfig)
local B=require(RS.Config.BeesConfig)
local Q=require(RS.Config.QuestConfig)
local R=require(RS.Config.RarityConfig)
local W=require(RS.Config.WorkshopConfig)
local WE=require(RS.Config.WorkshopEffectsConfig)
local G=require(RS.Config.GardenSynergyConfig)
local Default=require(game:GetService("ServerScriptService").Data.DefaultProfile)
local S={}

local function count(map)
 local n=0
 for _ in pairs(map) do n+=1 end
 return n
end

function S.Run()
 assert(RS.Config:FindFirstChild("BuildTrialConfig")==nil,"Retired Trials config must stay removed")
 assert(Default.Quests.Trials==nil and Default.Season.CompletedGoals==nil,"Retired Trials state must not be seeded")
 local seen={} for _,id in ipairs(R.Order) do assert(not seen[id],"Duplicate rarity") seen[id]=true end

 assert(count(F.Species)==27,"Release must contain 27 Flowers")
 assert(count(B.Bees)==28,"Release must contain 28 Bees")
 for id,item in pairs(F.Species) do
  assert(item.Id==id and R.Rank[item.Rarity],"Invalid Flower "..id)
  assert(item.DropWeight==item.DropWeight and item.DropWeight>=0 and item.DropWeight<math.huge,"Invalid Flower weight "..id)
  local buff=F.GetLevelBuff(id,1)
  assert(buff and type(buff.Multiplier)=="number" and buff.Multiplier>0,"Missing Flower passive "..id)
 end
 for id,item in pairs(B.Bees) do
  assert(item.Id==id and R.Rank[item.Rarity],"Invalid Bee "..id)
  assert(item.DropWeight==item.DropWeight and item.DropWeight>=0 and item.DropWeight<math.huge,"Invalid Bee weight "..id)
  assert(type(item.Passive)=="table" and (tonumber(item.Passive.LuckMultiplier) or 0)>1,"Every Bee must buff Luck: "..id)
  assert(type(item.Ability)=="table" and type(item.Ability.Id)=="string","Missing Bee ability "..id)
 end

 local workshopCount=0
 for id,n in pairs(W.Nodes) do
  workshopCount+=1
  if n.Parent then assert(W.Nodes[n.Parent],"Broken Workshop prerequisite") end
  if id~="CORE" then
   local effect=WE[id] assert(effect,"Missing Workshop effect "..id)
   for key,value in pairs(effect) do
    assert(type(key)=="string","Invalid Workshop effect key")
    assert(type(value)=="number" or type(value)=="string","Invalid Workshop effect value "..id.."."..key)
    if type(value)=="number" then assert(value==value and value>-math.huge and value<math.huge,"Invalid Workshop effect number "..id.."."..key) end
   end
  end
 end
 assert(workshopCount==43,"Workshop must contain 43 nodes")

 local recipeIds={}
 assert(#G.Recipes==32,"Release must contain 32 Garden Synergies")
 for _,recipe in ipairs(G.Recipes) do
  assert(type(recipe.Id)=="string" and not recipeIds[recipe.Id],"Duplicate Garden Synergy")
  recipeIds[recipe.Id]=true
  assert(#(recipe.Species or {})>=2 and #(recipe.Species or {})<=7,"Invalid Garden Synergy size "..recipe.Id)
  for _,id in ipairs(recipe.Species or {}) do assert(F.Species[id],"Broken recipe "..recipe.Id.." -> "..tostring(id)) end
  for _,i in ipairs(recipe.Slots or {}) do assert(i>=1 and i<=15 and i%1==0,"Invalid slot") end
 end

 assert(#Q.Order==25,"Release must contain 25 Quests")
 local questIds={}
 for index,id in ipairs(Q.Order) do
  assert(type(id)=="string" and not questIds[id],"Duplicate Quest id")
  questIds[id]=true
  local quest=Q.Get(id)
  assert(quest and (tonumber(quest.Target) or 0)>0,"Invalid Quest "..tostring(id))
  assert(type(quest.Title)=="string" and type(quest.Text)=="string","Missing Quest text "..tostring(id))
  assert(index==1 or Q.Get(Q.Order[index-1]),"Broken Quest order")
 end
 return true
end
return S
