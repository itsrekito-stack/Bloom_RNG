local RS=game:GetService("ReplicatedStorage")
local Schema=require(script.Parent.Parent.Data.ProfileSchema)
local U=require(RS.Shared.BloomUtil)
local Pool=require(RS.Config.RollPoolConfig)
local S={}
function S.Run()
 assert(require(script.Parent.ConfigValidation).Run())
 local p=Schema.CreateDefault() assert(Schema.Prepare(p))
 local legacy={Inventory={Apple=2,Unknown=1},Currencies={FruitDust=10}}
 assert(Schema.Prepare(legacy)) local dust=legacy.Currencies.PetalDust local copies=legacy.FlowerCollection.OwnedSeedCopies.Daisy
 assert(Schema.Prepare(legacy)) assert(legacy.Currencies.PetalDust==dust and legacy.FlowerCollection.OwnedSeedCopies.Daisy==copies)
 local plan=require(RS.Shared.SeasonPlan).BuildSeasonTurnPlan(p) assert(p.Season.Count==0 and plan.After.Season.Count==1)
 local pool,total=Pool.Build(p,1,{}) local sum=0 for _,v in ipairs(pool) do sum=sum+v.Chance end assert(math.abs(sum-1)<1e-9)
 local rng=Random.new(42) for _=1,10000 do local value=rng:NextNumber()*total local found=false for _,v in ipairs(pool) do value=value-v.Weight if value<=0 then assert(v.Kind=="FlowerSeed" or v.Kind=="Bee") found=true break end end assert(found) end
 print("[Bloom] native smoke tests passed: config, migration, season plan, 10k pool samples") return true
end
return S
