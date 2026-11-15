# Requirements Document

## Introduction

This document specifies the requirements for WF_Bot.lua, a unified AI bot system for the Violence District Roblox game. The system integrates all existing modules from the ai/modules/ folder into a single, cohesive OOP-based AI bot that operates on Android mobile devices using the Delta executor. The bot implements priority-based decision making for survivor gameplay, including flee behavior, generator repair with skillcheck automation, teammate healing, and escape mechanics.

## Glossary

- **WF_Bot**: The main unified AI bot class that orchestrates all controllers and systems
- **Delta_Executor**: The Roblox executor for Android mobile devices
- **Violence_District**: The target Roblox game (Dead by Daylight inspired)
- **Survivor**: A player on the Survivors team attempting to repair generators and escape
- **Killer**: A player on the Killer team attempting to catch survivors
- **Generator**: Interactive map object that survivors must repair to open exit gates
- **Skillcheck**: A timed button press event during generator repair that tests player reaction
- **Pallet**: A defensive map object that survivors can drop to stun the killer
- **Exit_Gate**: A map object that allows survivors to escape once all generators are repaired
- **Module**: A Lua file in ai/modules/ that provides specific functionality
- **Controller**: A module that handles a specific aspect of bot behavior (Movement, Combat, etc.)
- **System**: A module that provides environmental awareness (Vision, Sensor, etc.)
- **Config**: A module that stores configuration parameters
- **OOP**: Object-oriented programming paradigm using Lua metatables
- **HTTP_Loader**: A method to load and execute the bot script via loadstring from GitHub
- **_G**: The global Lua table used for cross-script communication

## Requirements

### Requirement 1: Module Integration Architecture

**User Story:** As a developer, I want the bot to use all existing modules from ai/modules/, so that the codebase is maintainable and follows established patterns.

#### Acceptance Criteria

1. WHEN WF_Bot.lua executes, THE Bot_Class SHALL load all configuration modules (AIConfig, GameConfig, InputConfig)
2. WHEN WF_Bot.lua initializes, THE Bot_Class SHALL instantiate all controller modules (MovementController, CombatController)
3. WHEN WF_Bot.lua initializes, THE Bot_Class SHALL instantiate all core modules (ObjectDetector, TeamManager)
4. WHEN WF_Bot.lua initializes, THE Bot_Class SHALL instantiate all system modules (VisionSystem, SensorSystem)
5. WHEN any module is unavailable, THE Bot_Class SHALL log an error message and continue with degraded functionality
6. THE Bot_Class SHALL use OOP architecture with metatables for class instantiation
7. THE Bot_Class SHALL pass appropriate dependencies between modules during initialization

### Requirement 2: Priority-Based Decision Making

**User Story:** As a survivor bot, I want to make intelligent decisions based on situational priorities, so that I can survive and help my team effectively.

#### Acceptance Criteria

1. WHEN a killer is detected within 70 studs, THE Bot_Class SHALL set current priority to FLEE with priority value 100
2. WHEN the bot is injured and no killer is nearby, THE Bot_Class SHALL set current priority to HEAL_SELF with priority value 90
3. WHEN a teammate needs healing and no killer is nearby, THE Bot_Class SHALL set current priority to HEAL_TEAMMATE with priority value 85
4. WHEN generators are incomplete and no threats are present, THE Bot_Class SHALL set current priority to REPAIR_GENERATOR with priority value 70
5. WHEN all generators are complete, THE Bot_Class SHALL set current priority to ESCAPE with priority value 95
6. WHEN no higher priority actions are available, THE Bot_Class SHALL set current priority to PATROL with priority value 40
7. THE Bot_Class SHALL evaluate priorities every 2 seconds using the decision update rate
8. WHEN multiple priorities apply, THE Bot_Class SHALL execute the action with the highest priority value

### Requirement 3: Killer Detection and Evasion

**User Story:** As a survivor bot, I want to detect and flee from killers, so that I can avoid being caught.

#### Acceptance Criteria

1. WHEN SensorSystem scans for enemies, THE SensorSystem SHALL detect all killer players within 100 studs
2. WHEN a killer is detected within 70 studs, THE MovementController SHALL calculate a flee position 50 studs away from the killer
3. WHEN fleeing, THE MovementController SHALL set walk speed to 20 (sprint speed)
4. WHEN fleeing, THE Bot_Class SHALL use pathfinding to reach the flee position
5. WHEN the killer distance exceeds 70 studs, THE Bot_Class SHALL resume normal behavior and set walk speed to 16
6. WHEN fleeing near a pallet, THE Interaction_Controller SHALL drop the pallet to stun the killer
7. WHEN fleeing near a window, THE Interaction_Controller SHALL vault the window to escape

### Requirement 4: Generator Repair System

**User Story:** As a survivor bot, I want to repair generators automatically, so that I can progress the game objective.

#### Acceptance Criteria

1. WHEN SensorSystem scans for generators, THE ObjectDetector SHALL detect all incomplete generators within 100 studs
2. WHEN the bot decides to repair, THE MovementController SHALL navigate to the nearest incomplete generator
3. WHEN the bot is within 5 studs of a generator, THE Survival_Controller SHALL initiate the repair interaction
4. WHEN repairing a generator, THE Survival_Controller SHALL monitor for skillcheck events
5. WHEN a skillcheck event occurs, THE Survival_Controller SHALL execute the skillcheck response based on the configured mode
6. WHERE skillcheck mode is Legit, THE Survival_Controller SHALL simulate human-like timing with 50-150ms reaction delay
7. WHERE skillcheck mode is Instant, THE Survival_Controller SHALL respond immediately to skillcheck events
8. WHEN generator progress reaches 100 percent, THE Bot_Class SHALL select a new objective

### Requirement 5: Skillcheck Automation System

**User Story:** As a bot user, I want configurable skillcheck automation, so that the bot can repair generators with different levels of detection avoidance.

#### Acceptance Criteria

1. THE Survival_Controller SHALL support two skillcheck modes: Legit and Instant
2. WHEN Legit mode is active, THE Survival_Controller SHALL add random reaction delay between 50 and 150 milliseconds
3. WHEN Instant mode is active, THE Survival_Controller SHALL respond within 10 milliseconds
4. WHEN a skillcheck success zone is detected, THE Survival_Controller SHALL trigger the interact input at the calculated timing
5. WHEN a skillcheck is missed, THE Survival_Controller SHALL continue repair after the penalty period
6. THE Survival_Controller SHALL track skillcheck success rate for debugging purposes
7. THE Survival_Controller SHALL be configurable via _G.BotConfig.SkillcheckMode

### Requirement 6: Teammate Detection and Healing

**User Story:** As a survivor bot, I want to help injured teammates, so that the team has better chances of survival.

#### Acceptance Criteria

1. WHEN SensorSystem scans for allies, THE SensorSystem SHALL detect all survivor teammates within 80 studs
2. WHEN a teammate has health below 50 percent, THE SensorSystem SHALL mark them as needing help
3. WHEN a teammate needs healing and no killer is nearby, THE MovementController SHALL navigate to the teammate position
4. WHEN the bot is within 5 studs of an injured teammate, THE Survival_Controller SHALL initiate the heal interaction
5. WHEN healing is complete, THE Bot_Class SHALL resume other objectives
6. THE SensorSystem SHALL prioritize teammates by lowest health percentage

### Requirement 7: Movement and Pathfinding

**User Story:** As a bot, I want robust movement with pathfinding, so that I can navigate the map without getting stuck.

#### Acceptance Criteria

1. THE MovementController SHALL use PathfindingService for navigation to all objectives
2. THE MovementController SHALL create paths with AgentCanJump set to false (Violence District has no jump mechanic)
3. WHEN following a path, THE MovementController SHALL call Humanoid:MoveTo with the current waypoint position every frame
4. WHEN a waypoint is reached (within 5 studs), THE MovementController SHALL advance to the next waypoint
5. WHEN a path completes, THE MovementController SHALL clear the current path and notify the Bot_Class
6. WHEN pathfinding fails, THE MovementController SHALL fall back to direct movement using Humanoid:MoveTo
7. WHEN the bot is stuck for 3 seconds, THE MovementController SHALL attempt to jump and recalculate the path
8. THE MovementController SHALL refresh paths every 3 seconds when moving to dynamic targets

### Requirement 8: Pallet and Window Interaction

**User Story:** As a survivor bot being chased, I want to use pallets and windows, so that I can escape the killer.

#### Acceptance Criteria

1. WHEN fleeing from a killer, THE ObjectDetector SHALL detect pallets within 15 studs
2. WHEN the bot is within 5 studs of a pallet and killer is within 10 studs, THE Interaction_Controller SHALL drop the pallet
3. WHEN fleeing from a killer, THE ObjectDetector SHALL detect windows within 15 studs
4. WHEN the bot is within 5 studs of a window, THE Interaction_Controller SHALL vault the window
5. THE Interaction_Controller SHALL simulate the interact input to trigger pallet drop
6. THE Interaction_Controller SHALL simulate the interact input to trigger window vault
7. WHEN a pallet is dropped or window is vaulted, THE Bot_Class SHALL continue fleeing behavior

### Requirement 9: Exit Gate Escape System

**User Story:** As a survivor bot, I want to escape through exit gates when generators are complete, so that I can win the game.

#### Acceptance Criteria

1. WHEN all generators reach 100 percent progress, THE Bot_Class SHALL transition to ESCAPE state
2. WHEN in ESCAPE state, THE ObjectDetector SHALL detect all exit gates on the map
3. WHEN exit gates are detected, THE MovementController SHALL navigate to the nearest exit gate
4. WHEN the bot is within 5 studs of an exit gate, THE Survival_Controller SHALL open the gate
5. WHEN an exit gate is fully open, THE MovementController SHALL move through the gate to escape
6. WHEN the bot escapes successfully, THE Bot_Class SHALL stop execution and log success message

### Requirement 10: Configuration System

**User Story:** As a bot user, I want to configure bot behavior at runtime, so that I can adjust settings without editing the script.

#### Acceptance Criteria

1. THE Bot_Class SHALL expose configuration via _G.BotConfig global table
2. THE Bot_Class SHALL load default values from AIConfig, GameConfig, and InputConfig modules
3. WHEN _G.BotConfig.WalkSpeed is changed, THE MovementController SHALL update the humanoid walk speed
4. WHEN _G.BotConfig.DebugMode is true, THE Bot_Class SHALL log decision-making and state changes
5. WHEN _G.BotConfig.SkillcheckMode is changed, THE Survival_Controller SHALL update skillcheck behavior
6. THE Bot_Class SHALL support runtime changes to detection ranges and priority values
7. THE Bot_Class SHALL validate configuration changes and use safe defaults for invalid values

### Requirement 11: Character State Management

**User Story:** As a bot, I want to handle character respawn and death, so that I can continue operating across multiple lives.

#### Acceptance Criteria

1. WHEN LocalPlayer.Character becomes nil, THE Bot_Class SHALL pause execution
2. WHEN LocalPlayer.CharacterAdded fires, THE Bot_Class SHALL reinitialize character references
3. WHEN the character respawns, THE Bot_Class SHALL reinitialize all modules with the new character instance
4. WHEN Humanoid.Health reaches 0, THE Bot_Class SHALL pause execution until respawn
5. WHEN character respawns, THE Bot_Class SHALL resume from IDLE state and begin decision-making
6. THE Bot_Class SHALL maintain configuration settings across character respawns

### Requirement 12: HTTP Loader Compatibility

**User Story:** As a bot user, I want to load the bot via HTTP loadstring, so that I can execute it without local file access.

#### Acceptance Criteria

1. THE WF_Bot.lua SHALL be executable as a single file via loadstring
2. THE WF_Bot.lua SHALL inline all module code from ai/modules/ into the main file
3. WHEN loaded via loadstring, THE Bot_Class SHALL initialize automatically after a 1 second delay
4. THE WF_Bot.lua SHALL expose _G.StartBot, _G.StopBot, and _G.CleanupBot functions
5. WHEN _G.CleanupBot is called, THE Bot_Class SHALL disconnect all RunService connections
6. WHEN _G.CleanupBot is called, THE Bot_Class SHALL clear all _G variables created by the bot
7. THE WF_Bot.lua SHALL handle missing services gracefully for executor compatibility

### Requirement 13: Mobile Input Compatibility

**User Story:** As an Android user, I want the bot to work with mobile controls, so that I can use it on Delta executor.

#### Acceptance Criteria

1. THE InputConfig SHALL detect mobile platform using UserInputService.TouchEnabled
2. WHEN on mobile, THE Interaction_Controller SHALL use mobile button references for interactions
3. WHEN on desktop, THE Interaction_Controller SHALL use keyboard key codes for interactions
4. THE MovementController SHALL use Humanoid:MoveTo for cross-platform compatibility
5. THE Interaction_Controller SHALL simulate virtual button presses for mobile interact actions
6. THE Bot_Class SHALL work without requiring keyboard or mouse input

### Requirement 14: Debug and Status Reporting

**User Story:** As a bot user, I want to see bot status and debug information, so that I can verify the bot is working correctly.

#### Acceptance Criteria

1. WHEN _G.BotStatus is called, THE Bot_Class SHALL print current state, nearby threats, and objectives
2. WHEN debug mode is enabled, THE Bot_Class SHALL log state transitions to the console
3. WHEN debug mode is enabled, THE SensorSystem SHALL log detected objects count
4. WHEN debug mode is enabled, THE MovementController SHALL log pathfinding success and failures
5. THE Bot_Class SHALL report current priority and selected action in status output
6. THE Bot_Class SHALL report distance to current objective in status output
7. THE Survival_Controller SHALL report skillcheck success rate in status output

### Requirement 15: Error Handling and Resilience

**User Story:** As a bot user, I want the bot to handle errors gracefully, so that temporary issues don't crash the bot.

#### Acceptance Criteria

1. WHEN any module function throws an error, THE Bot_Class SHALL catch the error with pcall and log it
2. WHEN ObjectDetector fails to find map objects, THE Bot_Class SHALL retry on next scan cycle
3. WHEN PathfindingService fails to compute a path, THE MovementController SHALL use direct movement
4. WHEN a module is missing, THE Bot_Class SHALL continue with degraded functionality
5. WHEN game services are unavailable, THE Bot_Class SHALL wait and retry initialization
6. WHEN VisionSystem raycast fails, THE VisionSystem SHALL return false for line of sight check
7. THE Bot_Class SHALL prevent infinite loops with maximum iteration counters

