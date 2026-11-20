-- Format: turns big numbers into short money strings such as $12.5K.

local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi" }

function Format.short(n: number): string
	n = math.floor(n)
	local tier = 1
	local value = n
	while math.abs(value) >= 1000 and tier < #SUFFIXES do
		value /= 1000
		tier += 1
	end
	if tier == 1 then
		return tostring(n)
	end
	local text = if value >= 100 then string.format("%d", value) else string.format("%.1f", value)
	return (text:gsub("%.0$", "")) .. SUFFIXES[tier]
end

function Format.money(n: number): string
	return "$" .. Format.short(n)
end

function Format.rate(n: number): string
	return "$" .. Format.short(n) .. "/s"
end

return Format
