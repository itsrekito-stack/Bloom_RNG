# Migration map — source audit

Own Luau files: 83. Files containing Fruit: 44.
DataStore keys must stay unchanged. DefaultProfile has no explicit SchemaVersion; WorkshopV2.Version=4; Garden.Version=2.

| CURRENT SOURCE OF TRUTH | TARGET | ACTION | DEPENDENCIES / RISK |
|---|---|---|---|
| `src/ReplicatedStorage/Config/FlowersConfig.luau` | FlowersConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/EconomyConfig.luau` | EconomyConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/FruitProgressionConfig.luau` | FlowerProgressionConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/ServerDirectoryConfig.luau` | ServerDirectoryConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/LocationsConfig.luau` | LocationsConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/HiveConfig.luau` | HiveConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/UIAssetsConfig.luau` | UIAssetsConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/LoadingConfig.luau` | LoadingConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/PollinatorConfig.luau` | PollinatorConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/PollinatorProgressionConfig.luau` | PollinatorProgressionConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/GardenConfig.luau` | GardenConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/QuestConfig.luau` | QuestConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/PlayerProgressionConfig.luau` | PlayerProgressionConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/TutorialConfig.luau` | TutorialConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/UIThemeConfig.luau` | UIThemeConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/FruitsConfig.luau` | FlowersConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/ResearchConfig.luau` | WorkshopConfig / InventoryService | DELETE LATER | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/RollPoolConfig.luau` | RollPoolConfig | MODIFY | BeesConfig, FruitsConfig; save / consumer compatibility |
| `src/ReplicatedStorage/Config/WorkshopConfig.luau` | WorkshopConfig | MODIFY | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/BeesConfig.luau` | BeesConfig | KEEP | ; save / consumer compatibility |
| `src/ReplicatedStorage/Config/FruitCombinationConfig.luau` | GardenSynergyConfig | MODIFY | Config, FruitProgressionConfig, FruitsConfig; save / consumer compatibility |
| `src/ReplicatedStorage/Config/PerformanceConfig.luau` | PerformanceConfig | MODIFY | ; save / consumer compatibility |
| `src/ServerScriptService/Data/DataConfig.luau` | DataConfig | KEEP | ; save / consumer compatibility |
| `src/ServerScriptService/Data/ProfileSchema.luau` | ProfileSchema | MODIFY | Config, Data, DefaultProfile, FlowersConfig, GardenConfig; save / consumer compatibility |
| `src/ServerScriptService/Data/DefaultProfile.luau` | DefaultProfile | MODIFY | ; save / consumer compatibility |
| `src/ServerScriptService/Services/InventoryService.luau` | InventoryService | MODIFY | BeesConfig, Config, FruitsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/FruitProgressionService.luau` | FlowerProgressionService | MODIFY | Config, FruitProgressionConfig, FruitsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/PollinatorService.luau` | PollinatorService | MODIFY | BeesConfig, Classes, Config, HiveConfig, Pollinator, PollinatorConfig, PollinatorProgressionConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/WorkshopService.luau` | WorkshopService | MODIFY | Config, FruitsConfig, PollinatorProgressionConfig, Shared, WorkshopConfig, WorkshopMath; save / consumer compatibility |
| `src/ServerScriptService/Services/RemoteService.luau` | RemoteService | MODIFY | ; save / consumer compatibility |
| `src/ServerScriptService/Services/FruitService.luau` | WorkshopConfig / InventoryService | DELETE LATER | Config, FruitsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/GardenPlotService.luau` | GardenPlotService | MODIFY | Config, FlowersConfig, GardenConfig, LocationsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/TutorialService.luau` | TutorialService | MODIFY | ; save / consumer compatibility |
| `src/ServerScriptService/Services/MetaProgressionService.luau` | MetaProgressionService | MODIFY | Config, GardenConfig, HiveConfig, LocationsConfig, QuestConfig, ResearchConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/PlayerService.luau` | PlayerService | MODIFY | ; save / consumer compatibility |
| `src/ServerScriptService/Services/HiveService.luau` | HiveService | MODIFY | Config, HiveConfig, LocationsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/StatsService.luau` | StatsService | MODIFY | BeesConfig, Config, EconomyConfig, FruitCombinationConfig, FruitProgressionConfig, FruitsConfig, PollinatorConfig, PollinatorProgressionConfig, ResearchConfig, Shared, WorkshopMath; save / consumer compatibility |
| `src/ServerScriptService/Services/DataService.luau` | DataService | KEEP | ; save / consumer compatibility |
| `src/ServerScriptService/Services/ServerDirectoryService.luau` | ServerDirectoryService | MODIFY | Config, ServerDirectoryConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/RewardService.luau` | RewardService | MODIFY | Config, EconomyConfig, FlowersConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/MapService.luau` | MapService | MODIFY | Config, LocationsConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/RollService.luau` | RollService | MODIFY | BeesConfig, Config, FruitsConfig, RollPoolConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/FruitCombinationService.luau` | GardenSynergyService | MODIFY | Config, FruitCombinationConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/PollinatorVisualService.luau` | PollinatorVisualService | MODIFY | BeesConfig, Config; save / consumer compatibility |
| `src/ServerScriptService/Services/PlayerProgressionService.luau` | PlayerProgressionService | MODIFY | Config, PlayerProgressionConfig; save / consumer compatibility |
| `src/ServerScriptService/Services/FlowerService.luau` | FlowerService | MODIFY | Config, FlowerMath, FlowersConfig, Shared; save / consumer compatibility |

## EquippedFruitIds
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:260`
- `src/ServerScriptService/Data/DefaultProfile.luau:14`
- `src/ServerScriptService/Services/InventoryService.luau:33`
- `src/ServerScriptService/Services/InventoryService.luau:34`
- `src/ServerScriptService/Services/FruitProgressionService.luau:17`
- `src/ServerScriptService/Services/FruitService.luau:17`
- `src/ServerScriptService/Services/FruitService.luau:26`
- `src/ServerScriptService/Services/FruitService.luau:41`
- `src/ServerScriptService/Services/FruitService.luau:42`
- `src/ServerScriptService/Services/FruitService.luau:43`
- `src/ServerScriptService/Services/FruitService.luau:47`
- `src/ServerScriptService/Services/FruitService.luau:48`
- `src/ServerScriptService/Services/FruitService.luau:55`
- `src/ServerScriptService/Services/FruitService.luau:58`
- `src/ServerScriptService/Services/StatsService.luau:54`
- `src/ServerScriptService/Services/FruitCombinationService.luau:45`
- `src/ServerScriptService/Services/FruitCombinationService.luau:72`
- `src/ServerScriptService/Services/FruitCombinationService.luau:163`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/Inventory.luau:79`

## FruitDust
- `src/ReplicatedFirst/LoadingScreen.client.luau:212`
- `src/ReplicatedStorage/Shared/WorkshopMath.luau:35`
- `src/ReplicatedStorage/Shared/WorkshopMath.luau:40`
- `src/ReplicatedStorage/Shared/WorkshopMath.luau:43`
- `src/ReplicatedStorage/Shared/WorkshopMath.luau:62`
- `src/ReplicatedStorage/Config/FruitProgressionConfig.luau:12`
- `src/ReplicatedStorage/Config/FruitProgressionConfig.luau:13`
- `src/ReplicatedStorage/Config/FruitProgressionConfig.luau:14`
- `src/ReplicatedStorage/Config/UIAssetsConfig.luau:13`
- `src/ReplicatedStorage/Config/UIAssetsConfig.luau:45`
- `src/ReplicatedStorage/Config/QuestConfig.luau:11`
- `src/ReplicatedStorage/Config/QuestConfig.luau:12`
- `src/ReplicatedStorage/Config/QuestConfig.luau:13`
- `src/ReplicatedStorage/Config/QuestConfig.luau:14`
- `src/ReplicatedStorage/Config/QuestConfig.luau:15`
- `src/ReplicatedStorage/Config/QuestConfig.luau:16`
- `src/ReplicatedStorage/Config/QuestConfig.luau:17`
- `src/ReplicatedStorage/Config/QuestConfig.luau:18`
- `src/ReplicatedStorage/Config/QuestConfig.luau:19`
- `src/ReplicatedStorage/Config/QuestConfig.luau:20`
- `src/ReplicatedStorage/Config/QuestConfig.luau:21`
- `src/ReplicatedStorage/Config/QuestConfig.luau:22`
- `src/ReplicatedStorage/Config/QuestConfig.luau:23`
- `src/ReplicatedStorage/Config/QuestConfig.luau:24`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:6`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:7`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:8`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:9`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:10`
- `src/ReplicatedStorage/Config/ResearchConfig.luau:11`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:12`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:35`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:57`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:60`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:61`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:73`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:74`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:76`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:95`
- `src/ReplicatedStorage/Config/WorkshopConfig.luau:96`
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:73`
- `src/ServerScriptService/Data/ProfileSchema.luau:139`
- `src/ServerScriptService/Data/DefaultProfile.luau:5`
- `src/ServerScriptService/Services/FruitProgressionService.luau:32`
- `src/ServerScriptService/Services/FruitProgressionService.luau:35`
- `src/ServerScriptService/Services/FruitProgressionService.luau:36`
- `src/ServerScriptService/Services/FruitProgressionService.luau:41`
- `src/ServerScriptService/Services/WorkshopService.luau:55`
- `src/ServerScriptService/Services/WorkshopService.luau:92`
- `src/ServerScriptService/Services/WorkshopService.luau:93`
- `src/ServerScriptService/Services/WorkshopService.luau:95`
- `src/ServerScriptService/Services/FruitService.luau:19`
- `src/ServerScriptService/Services/FruitService.luau:58`
- `src/ServerScriptService/Services/PlayerService.luau:136`
- `src/ServerScriptService/Services/PlayerService.luau:154`
- `src/ServerScriptService/Services/StatsService.luau:120`
- `src/ServerScriptService/Services/RewardService.luau:9`
- `src/ServerScriptService/Services/RewardService.luau:11`
- `src/ServerScriptService/Services/RollService.luau:78`
- `src/StarterPlayer/StarterPlayerScripts/QuestTracker.client.luau:25`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/Inventory.luau:108`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/FruitIndex.luau:32`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:25`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:26`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:166`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:220`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:278`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:281`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/CurrencyHUD.luau:284`
- `src/StarterPlayer/StarterPlayerScripts/UI/Hooks/useRoll.luau:167`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopFrontend.luau:15`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopBackend.luau:28`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopBackend.luau:55`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopBackend.luau:84`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopBackend.luau:87`
- `src/StarterPlayer/StarterPlayerScripts/UI/Workshop/WorkshopBackend.luau:89`

## FruitMastery
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:192`
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:193`
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:220`
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:223`
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:235`
- `src/ServerScriptService/Data/DefaultProfile.luau:16`
- `src/ServerScriptService/Services/FruitProgressionService.luau:11`
- `src/ServerScriptService/Services/FruitProgressionService.luau:14`
- `src/ServerScriptService/Services/FruitProgressionService.luau:20`
- `src/ServerScriptService/Services/FruitProgressionService.luau:31`
- `src/ServerScriptService/Services/FruitService.luau:30`
- `src/ServerScriptService/Services/StatsService.luau:20`
- `src/ServerScriptService/Services/RollService.luau:79`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/Inventory.luau:36`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/Inventory.luau:41`
- `src/StarterPlayer/StarterPlayerScripts/UI/Components/FruitIndex.luau:81`

## DiscoveredFruits
- `src/ServerScriptService/Data/DefaultProfile.luau:13`
- `src/ServerScriptService/Services/InventoryService.luau:30`
- `src/ServerScriptService/Services/InventoryService.luau:31`
- `src/ServerScriptService/Services/InventoryService.luau:63`
- `src/ServerScriptService/Services/InventoryService.luau:65`
- `src/ServerScriptService/Services/InventoryService.luau:90`
- `src/ServerScriptService/Services/FruitProgressionService.luau:11`
- `src/ServerScriptService/Services/FruitProgressionService.luau:45`
- `src/ServerScriptService/Services/FruitProgressionService.luau:55`
- `src/ServerScriptService/Services/WorkshopService.luau:19`
- `src/ServerScriptService/Services/MetaProgressionService.luau:89`
- `src/ServerScriptService/Services/RollService.luau:41`

## FruitCombos
- `src/ReplicatedStorage/Config/FruitCombinationConfig.luau:198`
- `src/ServerScriptService/Data/ProfileSchema.luau:125`
- `src/ServerScriptService/Data/ProfileSchema.luau:126`
- `src/ServerScriptService/Data/ProfileSchema.luau:128`
- `src/ServerScriptService/Data/ProfileSchema.luau:129`
- `src/ServerScriptService/Data/ProfileSchema.luau:130`
- `src/ServerScriptService/Data/DefaultProfile.luau:17`
- `src/ServerScriptService/Services/StatsService.luau:12`
- `src/ServerScriptService/Services/StatsService.luau:75`
- `src/ServerScriptService/Services/StatsService.luau:137`
- `src/ServerScriptService/Services/FruitCombinationService.luau:13`
- `src/ServerScriptService/Services/FruitCombinationService.luau:14`
- `src/ServerScriptService/Services/FruitCombinationService.luau:16`
- `src/ServerScriptService/Services/FruitCombinationService.luau:82`

## ResearchNodes
- `src/ServerScriptService/Data/DefaultProfile.luau:44`
- `src/ServerScriptService/Services/MetaProgressionService.luau:38`
- `src/ServerScriptService/Services/MetaProgressionService.luau:39`
- `src/ServerScriptService/Services/MetaProgressionService.luau:97`
- `src/ServerScriptService/Services/MetaProgressionService.luau:248`
- `src/ServerScriptService/Services/MetaProgressionService.luau:259`
- `src/ServerScriptService/Services/MetaProgressionService.luau:332`
- `src/ServerScriptService/Services/MetaProgressionService.luau:337`
- `src/ServerScriptService/Services/MetaProgressionService.luau:362`
- `src/ServerScriptService/Services/StatsService.luau:48`

## ResearchEffects
- `src/ServerScriptService/Services/StatsService.luau:113`

## ResearchPurchaseRequest
- `src/ServerScriptService/Services/RemoteService.luau:31`
- `src/ServerScriptService/Services/MetaProgressionService.luau:419`

## ActiveLocationTheme
- `src/ServerScriptService/Data/DefaultProfile.luau:55`
- `src/ServerScriptService/Services/GardenPlotService.luau:586`
- `src/ServerScriptService/Services/MetaProgressionService.luau:69`
- `src/ServerScriptService/Services/MetaProgressionService.luau:70`
- `src/ServerScriptService/Services/MetaProgressionService.luau:300`
- `src/ServerScriptService/Services/ServerDirectoryService.luau:20`
- `src/ServerScriptService/Services/MapService.luau:86`
- `src/ServerScriptService/Services/MapService.luau:108`
- `src/ServerScriptService/Services/MapService.luau:144`
- `src/ServerScriptService/Services/FlowerService.luau:61`

## Confirmed inconsistencies
- InventoryService:AddFruit sets count=1; GardenPlotService checks OwnedFlowerTypes, never reserved copies.
- FruitsConfig infers rarity using odds bands; BeesConfig declares eight names; FlowersConfig declares seven-tier subset.
- RollService payload uses base-pool odds although luck changes selection weights.
- GardenConfig, PollinatorConfig, WorkshopConfig, HiveConfig and LocationsConfig independently own gates/capacities.
- ResearchPurchaseRequest and fruit inventory/mastery/equip remotes need removal only after consumers migrate.
- Require graph uses dynamic WaitForChild: static dependency scan is not proof of runtime cycle freedom. No Studio execution has been performed.