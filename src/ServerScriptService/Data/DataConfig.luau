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
-- Operation retries reuse one immutable candidate and id. No unbounded recovery.
DataConfig.PersistenceAttempts = 6
DataConfig.RetryMaxSeconds = 8
DataConfig.OperationWaitSeconds = 20
DataConfig.ShutdownBudgetSeconds = 25
function DataConfig.GetStoreName(): string
if RunService:IsStudio() then
return DataConfig.StudioStoreName
end
return DataConfig.ProductionStoreName
end
return DataConfig

