-- Rarity: the seven-step rarity ladder and the four mutations, with their colours and multipliers.

local Rarity = {}

Rarity.ORDER = { "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Brainrot God" }

Rarity.INFO = {
	Common = { rank = 1, color = Color3.fromRGB(215, 215, 215), weight = 50, income = 2, priceFactor = 12, scale = 1.0 },
	Uncommon = { rank = 2, color = Color3.fromRGB(90, 235, 110), weight = 26, income = 15, priceFactor = 16, scale = 1.1 },
	Rare = { rank = 3, color = Color3.fromRGB(70, 165, 255), weight = 13, income = 120, priceFactor = 20, scale = 1.2 },
	Epic = { rank = 4, color = Color3.fromRGB(200, 95, 255), weight = 6.5, income = 1000, priceFactor = 25, scale = 1.3 },
	Legendary = { rank = 5, color = Color3.fromRGB(255, 190, 40), weight = 3, income = 9000, priceFactor = 30, scale = 1.4 },
	Mythic = { rank = 6, color = Color3.fromRGB(255, 60, 95), weight = 1.2, income = 80000, priceFactor = 35, scale = 1.5 },
	["Brainrot God"] = { rank = 7, color = Color3.fromRGB(255, 255, 140), weight = 0.3, income = 750000, priceFactor = 40, scale = 1.65 },
}

Rarity.MUTATIONS = {
	{ name = "Gold", chance = 0.08, mult = 2, color = Color3.fromRGB(255, 200, 40), material = Enum.Material.Metal },
	{ name = "Diamond", chance = 0.04, mult = 3, color = Color3.fromRGB(160, 245, 255), material = Enum.Material.Glass },
	{ name = "Toxic", chance = 0.03, mult = 4, color = Color3.fromRGB(120, 255, 40), material = Enum.Material.Neon },
	{ name = "Rainbow", chance = 0.015, mult = 5, color = Color3.fromRGB(255, 80, 200), material = Enum.Material.Neon },
}

function Rarity.mutationInfo(name: string?)
	if not name then
		return nil
	end
	for _, info in Rarity.MUTATIONS do
		if info.name == name then
			return info
		end
	end
	return nil
end

function Rarity.mutationMultiplier(name: string?): number
	local info = Rarity.mutationInfo(name)
	return if info then info.mult else 1
end

function Rarity.rollRarity(rng: Random): string
	local total = 0
	for _, name in Rarity.ORDER do
		total += Rarity.INFO[name].weight
	end
	local roll = rng:NextNumber() * total
	for _, name in Rarity.ORDER do
		roll -= Rarity.INFO[name].weight
		if roll <= 0 then
			return name
		end
	end
	return "Common"
end

function Rarity.rollMutation(rng: Random): string?
	local roll = rng:NextNumber()
	for _, info in Rarity.MUTATIONS do
		if roll < info.chance then
			return info.name
		end
		roll -= info.chance
	end
	return nil
end

return Rarity
