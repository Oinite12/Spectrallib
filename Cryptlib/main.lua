Spectrallib.aliases = {}
Spectrallib.pointerblist = {}
Spectrallib.pointerblistrarity = {}
Spectrallib.mod_gameset_whitelist = {}
Spectrallib.mod_whitelist = {}
---@type { [string]: integer | fun():(integer|nil) }
Spectrallib.ascension_numbers = {}
Spectrallib.rarity_table = {}

Cryptid_config = {}
function cry_format(...)
    return ...
end

--Ascension numbers for Vanilla hands

---@param x integer
---@return fun(): integer|nil
local function tether_check(x)
    return function()
        return Spectrallib.has_tether() and x or nil
    end
end

local ascnum = Spectrallib.ascension_numbers
ascnum["High Card"]       = tether_check(1)
ascnum["Pair"]            = tether_check(2)
ascnum["Three of a Kind"] = tether_check(3)
ascnum["Four of a Kind"]  = tether_check(4)
ascnum["Straight"] = function ()
    return (
        next(SMODS.find_card("j_four_fingers"))
        and Spectrallib.gameset() ~= "modest"
        and 4
        or 5
    )
end
ascnum["Flush"] = ascnum["Straight"]
ascnum["Two Pair"]       = 4
ascnum["Full House"]     = 5
ascnum["Five of a Kind"] = 5
ascnum["Flush House"]    = 5
ascnum["Flush Five"]     = 5

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