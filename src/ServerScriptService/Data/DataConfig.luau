--!strict
local RunService =
game:GetService("RunService")
local DataConfig = {}
DataConfig.ProductionStoreName =
"FruitRNG_PlayerProfiles_v1"
DataConfig.StudioStoreName =
"FruitRNG_PlayerProfiles_TEST_v1"
DataConfig.KeyPrefix =
"Player_"
DataConfig.SessionLeaseSeconds =
180
DataConfig.AutosaveMinSeconds =
60
DataConfig.AutosaveMaxSeconds =
90
DataConfig.MaxRetries =
3
DataConfig.RetryBaseSeconds =
1
function DataConfig.GetStoreName(): string
if RunService:IsStudio() then
return DataConfig.StudioStoreName
end
return DataConfig.ProductionStoreName
end
return DataConfig
