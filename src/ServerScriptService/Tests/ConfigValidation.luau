local RS=game:GetService("ReplicatedStorage") local F=require(RS.Config.FlowersConfig) local B=require(RS.Config.BeesConfig) local R=require(RS.Config.RarityConfig) local W=require(RS.Config.WorkshopConfig) local L=require(RS.Config.LocationsConfig) local G=require(RS.Config.GardenSynergyConfig) local S={}
function S.Run()
 local seen={} for _,id in ipairs(R.Order) do assert(not seen[id],"Duplicate rarity") seen[id]=true end
 for _,registry in ipairs({F.Species,B.Bees}) do for id,item in pairs(registry) do assert(item.Id==id and R.Rank[item.Rarity],"Invalid registry item "..id) assert(item.DropWeight==item.DropWeight and item.DropWeight>=0 and item.DropWeight<math.huge,"Invalid weight") if item.AllowedBiomes then for biome in pairs(item.AllowedBiomes) do assert(L.Sectors[biome],"Unknown biome") end end end end
 local count=0 for id,n in pairs(W.Nodes) do count=count+1 if n.Parent then assert(W.Nodes[n.Parent],"Broken Workshop prerequisite") end end assert(count==43,"Workshop must contain 43 nodes")
 for _,recipe in ipairs(G.Recipes) do for _,id in ipairs(recipe.Species or {}) do assert(F.Species[id],"Broken recipe") end for _,i in ipairs(recipe.Slots or {}) do assert(i>=1 and i<=15 and i%1==0,"Invalid slot") end end
 return true
end return S
