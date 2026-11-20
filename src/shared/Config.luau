-- Config: every tuning constant of Cheese Tide Rush in one place.
-- Exposes a plain table of numbers, colours and upgrade/rebirth tables; it lives in Shared but today only server modules read it.
-- Holds data only: the formulas and rules that use these values live in the server modules.

local Config = {}

Config.STARTING_CASH = 60
Config.SYNC_INTERVAL = 0.2

-- Harbour layout (studs). Plots sit in two rows facing the market lane at z = 0.
Config.PLOT_COLUMNS_X = { -90, -30, 30, 90 }
Config.PLOT_ROW_Z = 46
Config.PLOT_SIZE = Vector3.new(40, 1.2, 30)
Config.PLOT_COLORS = {
	Color3.fromRGB(255, 70, 180), Color3.fromRGB(60, 220, 255), Color3.fromRGB(255, 200, 40), Color3.fromRGB(130, 255, 90),
	Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 120, 60), Color3.fromRGB(80, 140, 255), Color3.fromRGB(255, 90, 90),
}
Config.BASE_SLOTS = 6
Config.MAX_SLOTS = 10

-- Market conveyor
Config.LANE_START_X = -135
Config.LANE_END_X = 135
Config.LANE_SPEED = 5
Config.SPAWN_INTERVAL = 2.4
Config.BUY_DISTANCE = 11

-- Cheese Tide
Config.TIDE_MIN_GAP = 45
Config.TIDE_MAX_GAP = 60
Config.TIDE_WARNING = 8
Config.TIDE_SPEED = 30
Config.TIDE_START_X = -175
Config.TIDE_END_X = 175
Config.TIDE_HIT_HALF_WIDTH = 6

-- Steal and defend
Config.LOCK_BASE_TIME = 60
Config.LOCK_TIME_STEP = 15
Config.LOCK_COOLDOWN = 30
Config.STEAL_HOLD = 1.2

-- Night Gull Raider
Config.RAIDER_MIN_GAP = 35
Config.RAIDER_MAX_GAP = 55
Config.RAIDER_SPEED = 9
Config.RAIDER_GRAB_TIME = 3
Config.RAIDER_BONK_REWARD_SECONDS = 20

-- Upgrades: cost = base * growth ^ level
Config.UPGRADES = {
	Speed = { label = "Speed", base = 150, growth = 3, max = 5, step = 3 },
	Slots = { label = "Slot", base = 800, growth = 4, max = Config.MAX_SLOTS - Config.BASE_SLOTS },
	LockTime = { label = "Lock Time", base = 400, growth = 3, max = 4 },
}

-- Rebirth
Config.REBIRTH_BASE_COST = 25000
Config.REBIRTH_COST_GROWTH = 8
Config.REBIRTH_INCOME_BONUS = 0.5
Config.REBIRTH_TITLES = { "Dock Rookie", "Brie Baron", "Gouda Guru", "Cheddar Captain", "Tide Tyrant", "Cheese Deity" }

return Config
