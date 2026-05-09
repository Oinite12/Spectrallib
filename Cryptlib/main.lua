-- unused by Spectrallib
Cryptid_config = {}
function cry_format(...)
    return ...
end
Spectrallib.aliases = {}
Spectrallib.pointerblist = {}
Spectrallib.pointerblistrarity = {}
Spectrallib.rarity_table = {}

-- used by gamesets
Spectrallib.mod_gameset_whitelist = {}
-- used by Spectrallib.is_card_big()
Spectrallib.mod_whitelist = {}

--Ascension numbers for Vanilla hands
---@param x integer
---@return fun(): integer|nil
local function tether_check(x)
    return function()
        return Spectrallib.has_tether() and x or nil
    end
end
local function straight_flush()
	return (
		next(SMODS.find_card("j_four_fingers"))
		and Spectrallib.gameset() ~= "modest"
		and 4
		or 5
	)
end
---@type { [string]: integer | fun():(integer|nil) }
Spectrallib.ascension_numbers = {
	["High Card"]       = tether_check(1),
	["Pair"]            = tether_check(2),
	["Three of a Kind"] = tether_check(3),
	["Four of a Kind"]  = tether_check(4),
	["Straight"]        = straight_flush,
	["Flush"]           = straight_flush,
	["Two Pair"]        = 4,
	["Full House"]      = 5,
	["Five of a Kind"]  = 5,
	["Flush House"]     = 5,
	["Flush Five"]      = 5,
}

-- Manipulation types
---@type {[string]: fun(initial: number, operand: number|{arrows: number, height: number}, value_key: string): number|nil}
Spectrallib.manipulate_types = {
	["+"] = function (initial, operand, value_key)
        if not Spectrallib.is_number(operand) then return end
		if initial ~= 0 and initial ~= 1 then
			return initial + operand
		end
	end,
	["X"] = function (initial, operand, value_key)
        if not Spectrallib.is_number(operand) then return end
		if initial ~= 0 and (initial ~= 1 or (value_key ~= "x_chips" and value_key ~= "xmult")) then
			return initial * operand
		end
	end,
	["^"] = function (initial, operand, value_key)
        if not Spectrallib.is_number(operand) then return end
		return initial ^ operand
	end,
	["hyper"] = function (initial, operand, value_key)
		if (
            Spectrallib.can_mods_load("Talisman")
			and type(operand) == table
			and operand.arrows
			and operand.height
		) then
			initial = to_big(initial)
			local arrows = operand.arrows
			local height = to_big(operand.height)
			return initial:arrow(arrows, height)
		end
	end
}