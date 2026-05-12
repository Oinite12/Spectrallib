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

---@alias Spectrallib.ManipulateType string
---| "+" Arg value is added to original value
---| "X" Arg value is multiplied with the original value
---| "^" Original value is raised to the power of arg value
---| "hyper" Original value is raised to the hyperpower of arg value (which should be a BigNumber)

-- Manipulation types
---@type {[string|Spectrallib.ManipulateType]: fun(tbl_value: number, args: table|Spectrallib.manipulate.args, is_big: boolean, value_key: string): (number|nil)}
Spectrallib.manipulate_types = {
	["+"] = function (tbl_value, args, is_big, value_key)
		if not Spectrallib.is_number(args.value) then return end
		if tbl_value ~= 0 and tbl_value ~= 1 then
			return tbl_value + args.value
		end
	end,
	["X"] = function (tbl_value, args, is_big, value_key)
		if not Spectrallib.is_number(args.value) then return end
		if tbl_value ~= 0 and (tbl_value ~= 1 or (value_key ~= "x_chips" and value_key ~= "xmult")) then
			return tbl_value * args.value
		end
	end,
	["^"] = function (tbl_value, args, is_big, value_key)
		if not Spectrallib.is_number(args.value) then return end
		return tbl_value ^ args.value
	end,
	["hyper"] = function (tbl_value, args, is_big, value_key)
		if (
			Spectrallib.can_mods_load("Talisman")
			and type(args.value) == "table"
			and args.value.arrows and args.value.height
		) then
			tbl_value = to_big(tbl_value)
			local arrows = args.value.arrows
			local height = to_big(args.value.height)
			return tbl_value:arrow(arrows, height)
		end
	end,
}