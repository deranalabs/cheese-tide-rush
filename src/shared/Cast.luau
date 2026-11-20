-- Cast: the 28 brainrot characters of the harbour, their looks, income and price.

local Rarity = require(script.Parent.Rarity)

local Cast = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- body: Cheese | Ball | Can | Box | Fish | Tall ; hat: None | Crown | Cone | Antenna | Halo | Cheese | Captain | Horns
Cast.CHARACTERS = {
	-- Common
	{ name = "Wobbly Brie Bob", rarity = "Common", body = "Cheese", color = rgb(255, 222, 120), accent = rgb(255, 150, 40), hat = "None", quip = "Has never once stopped wobbling." },
	{ name = "Tuna Tornado", rarity = "Common", body = "Fish", color = rgb(120, 160, 200), accent = rgb(255, 255, 255), hat = "None", quip = "Spins when nervous. Always nervous." },
	{ name = "Mopsy McFlop", rarity = "Common", body = "Ball", color = rgb(230, 140, 170), accent = rgb(120, 60, 90), hat = "Antenna", quip = "Professional floor tester." },
	{ name = "Cracker Goblin", rarity = "Common", body = "Box", color = rgb(220, 170, 100), accent = rgb(140, 90, 40), hat = "Horns", quip = "Crunches menacingly." },
	-- Uncommon
	{ name = "Gouda Goose Deluxe", rarity = "Uncommon", body = "Ball", color = rgb(250, 250, 240), accent = rgb(255, 160, 30), hat = "Cheese", quip = "Honks in three cheeses." },
	{ name = "Pickle Pilot", rarity = "Uncommon", body = "Tall", color = rgb(110, 190, 70), accent = rgb(60, 90, 40), hat = "Captain", quip = "Lost his licence in a jar." },
	{ name = "Bubble Brick", rarity = "Uncommon", body = "Box", color = rgb(120, 220, 255), accent = rgb(255, 255, 255), hat = "Antenna", quip = "Pop at your own risk." },
	{ name = "Sardine Sergeant", rarity = "Uncommon", body = "Fish", color = rgb(170, 190, 210), accent = rgb(60, 90, 60), hat = "Captain", quip = "Packs his troops very tightly." },
	-- Rare
	{ name = "Captain Fondue", rarity = "Rare", body = "Can", color = rgb(255, 200, 60), accent = rgb(40, 60, 120), hat = "Captain", quip = "Dips first, asks questions never." },
	{ name = "Noodle Lighthouse", rarity = "Rare", body = "Tall", color = rgb(255, 235, 170), accent = rgb(255, 60, 60), hat = "Antenna", quip = "Guides ships into soup." },
	{ name = "Squeaky Cheddar Knight", rarity = "Rare", body = "Cheese", color = rgb(255, 160, 40), accent = rgb(180, 180, 200), hat = "Horns", quip = "Armour squeaks louder than he does." },
	{ name = "Disco Barnacle", rarity = "Rare", body = "Ball", color = rgb(150, 90, 255), accent = rgb(255, 80, 220), hat = "Halo", quip = "Clings to the beat." },
	-- Epic
	{ name = "Emperor Mozzarello", rarity = "Epic", body = "Ball", color = rgb(250, 248, 235), accent = rgb(200, 40, 40), hat = "Crown", quip = "Stretches every decree." },
	{ name = "Turbo Toastini", rarity = "Epic", body = "Box", color = rgb(200, 130, 60), accent = rgb(255, 90, 0), hat = "Antenna", quip = "Pops up at 300 km/h." },
	{ name = "Seagull Lawyer", rarity = "Epic", body = "Tall", color = rgb(240, 240, 240), accent = rgb(30, 30, 50), hat = "Captain", quip = "Objection! Also, chips?" },
	{ name = "Jellybean Jetski", rarity = "Epic", body = "Fish", color = rgb(255, 80, 160), accent = rgb(80, 255, 220), hat = "Cone", quip = "Zero brakes, all flavour." },
	-- Legendary
	{ name = "Grand Duke Camembot", rarity = "Legendary", body = "Can", color = rgb(235, 225, 200), accent = rgb(80, 200, 255), hat = "Crown", quip = "Half cheese, half robot, all duke." },
	{ name = "Lasagna Leviathan", rarity = "Legendary", body = "Box", color = rgb(230, 110, 50), accent = rgb(255, 230, 120), hat = "Horns", quip = "Seven layers of pure menace." },
	{ name = "Professor Wheelbarrow", rarity = "Legendary", body = "Cheese", color = rgb(160, 110, 70), accent = rgb(255, 255, 255), hat = "Cone", quip = "Teaches gravity by tipping over." },
	{ name = "Harbour Wizard Glorp", rarity = "Legendary", body = "Tall", color = rgb(80, 60, 200), accent = rgb(255, 230, 60), hat = "Cone", quip = "Casts nets. And spells. Mostly nets." },
	-- Mythic
	{ name = "Parmesan Phantom", rarity = "Mythic", body = "Ball", color = rgb(230, 240, 255), accent = rgb(120, 255, 255), hat = "Halo", quip = "Grated beyond the grave." },
	{ name = "Octo Accountant", rarity = "Mythic", body = "Can", color = rgb(255, 110, 130), accent = rgb(40, 40, 60), hat = "Antenna", quip = "Eight arms, eight spreadsheets." },
	{ name = "Neon Krakenstein", rarity = "Mythic", body = "Fish", color = rgb(60, 255, 160), accent = rgb(255, 40, 140), hat = "Horns", quip = "Assembled from spare calamari." },
	{ name = "Moon Cheese Moai", rarity = "Mythic", body = "Tall", color = rgb(200, 200, 170), accent = rgb(255, 240, 120), hat = "Cheese", quip = "Stares at the tide. The tide blinks first." },
	-- Brainrot God
	{ name = "Supreme Tide Wheel", rarity = "Brainrot God", body = "Cheese", color = rgb(255, 230, 50), accent = rgb(255, 60, 200), hat = "Crown", quip = "The tide answers to it." },
	{ name = "Gigabrie Omega", rarity = "Brainrot God", body = "Ball", color = rgb(255, 250, 220), accent = rgb(80, 255, 255), hat = "Halo", quip = "Ripened for ten thousand years." },
	{ name = "The Final Crouton", rarity = "Brainrot God", body = "Box", color = rgb(220, 160, 70), accent = rgb(255, 255, 255), hat = "Halo", quip = "There will be no more salad." },
	{ name = "Holy Raclette 9000", rarity = "Brainrot God", body = "Can", color = rgb(255, 190, 80), accent = rgb(255, 80, 40), hat = "Crown", quip = "Melts reality onto potatoes." },
}

-- income steps for the four characters of each rarity
local STEP = { 1, 1.4, 1.9, 2.6 }

local byRarity = {}
for index, def in Cast.CHARACTERS do
	byRarity[def.rarity] = byRarity[def.rarity] or {}
	table.insert(byRarity[def.rarity], index)
	def.index = index
	def.step = STEP[#byRarity[def.rarity]] or 1
end

function Cast.get(index: number)
	return Cast.CHARACTERS[index]
end

function Cast.incomeOf(index: number, mutation: string?): number
	local def = Cast.CHARACTERS[index]
	return math.floor(Rarity.INFO[def.rarity].income * def.step * Rarity.mutationMultiplier(mutation))
end

function Cast.priceOf(index: number, mutation: string?): number
	local def = Cast.CHARACTERS[index]
	return math.floor(Cast.incomeOf(index, mutation) * Rarity.INFO[def.rarity].priceFactor)
end

function Cast.displayName(index: number, mutation: string?): string
	local name = Cast.CHARACTERS[index].name
	return if mutation then mutation .. " " .. name else name
end

function Cast.rollIndex(rng: Random): number
	local pool = byRarity[Rarity.rollRarity(rng)]
	return pool[rng:NextInteger(1, #pool)]
end

return Cast
