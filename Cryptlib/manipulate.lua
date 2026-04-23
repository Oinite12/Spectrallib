----------
-- DATA --
----------

Spectrallib.base_values = {}

Spectrallib.misprintize_value_blacklist = Spectrallib.list_to_keys({
	"perish_tally", "id", "suit_nominal", "base_nominal", "face_nominal",
	"qty", "h_x_chips", "d_size", "h_size", "selected_d6_face",
	"cry_hook_id", "colour", "suit_nominal_original", "times_played",
	"extra_slots_used", "card_limit"
}, false)

Spectrallib.misprintize_bignum_blacklist = Spectrallib.list_to_keys({
	"odds", "cry_prob", "perma_repetitions", "repetitions", "nominal"
}, false)

Spectrallib.misprintize_value_cap = { --yeahh.. this is mostly just for retriggers, but i might as well make it fully functional
	perma_repetitions = 40,
	repetitions = 40,
}



-----------
-- HOOKS --
-----------

--use ID to work with glitched/misprint
function Card:get_nominal(mod)
	local mult = 1
	local rank_mult = 1
	if mod == "suit" then
		mult = 1000000
	end

	if self.ability.effect == "Stone Card" or (self.config.center.no_suit and self.config.center.no_rank) then
		mult = -10000
	elseif self.config.center.no_suit then
		mult = 0
	elseif self.config.center.no_rank then
		rank_mult = 0
	end

	local nominal = 10 * (self.base.id or 0.1) * rank_mult
		+ self.base.suit_nominal * mult
		+ (self.base.suit_nominal_original or 0) * 0.0001 * mult
		+ 10 * self.base.face_nominal * rank_mult
		+ 0.000001 * self.unique_val

	return to_number(nominal)
end



---------------
-- FUNCTIONS --
---------------

-- Select a random number from a logarithmically distributed set.
---@param seed integer
---@param min number
---@param max number
---@return number
function Spectrallib.log_random(seed, min, max)
	math.randomseed(seed)
	local lmin = math.log(min, 2.718281828459045)
	local lmax = math.log(max, 2.718281828459045)
	local poll = math.random() * (lmax - lmin) + lmin
	return math.exp(poll)
end

---@class Spectrallib.manipulate.args
---@field min? number
---@field max? number
---@field type? string
---@field value? number
---@field func? fun(num: number, args: table, is_big?: boolean, num_key: any)
---@field dont_stack? boolean
---@field no_deck_effects? boolean
---@field bypass_checks? boolean

---Manipulates the values of a given card.
---`func` takes priority over all other arguments and returns the new value.
---`min` and `max` can be set to use a logarithmically distributed random value as the amount, else `value` will be used.
---@param card table|Card
---@param args table|Spectrallib.manipulate.args
---@return boolean|nil
function Spectrallib.manipulate(card, args)
	if not card or not card.config or not card.config.center then return end
	if not (not Card.no(card, "immutable", true) or (args and args.bypass_checks)) then return end

	args = args or {
		min = G.GAME.modifiers.cry_misprint_min or 1,
		max = G.GAME.modifiers.cry_misprint_max or 1,
		dont_stack = true,
		no_deck_effects = true,
	}
	args.type = args.type or "X"

	-- If a center doesn't have its base values recorded yet,
	-- record it
	local center_config = copy_table(card.config.center.config)
	local center_key = card.config.center.key
	if not Spectrallib.base_values[center_key] then
		Spectrallib.base_values[center_key] = {}
		local recorded_config = Spectrallib.base_values[center_key]

		for config_key, config_value in pairs(center_config) do
			if Spectrallib.is_number(config_value) and config_value ~= 0 then
				recorded_config[config_key .. "ability"] = config_value
			elseif type(config_value) == "table" then
				for subability_key, subability_value in pairs(config_value) do
					recorded_config[subability_key .. config_key] = subability_value
				end
			end
		end
	end

	-- Where the manipulation actually occurs (called later)
	local func = function(cardd) -- cardd is effectively exactly card
		--hardcoded whatever
		if cardd.config.center.set == "Booster" then
			args.big = false
		end

		-- maybe we could try and convince infinifusion folks to
		-- make this a patch instead of hardcoding this into default Spectrallib
		if cardd.infinifusion then
			if cardd.config.center == cardd.infinifusion_center or cardd.config.center.key == "j_infus_fused" then
				calculate_infinifusion(cardd, nil, function(i)
					Spectrallib.manipulate(cardd, args)
				end)
			end
		end

		-- Manipulate values
		Spectrallib.manipulate_table(cardd, cardd, "ability", args)
		if cardd.base then
			Spectrallib.manipulate_table(cardd, cardd, "base", args)
		end

		-- Randomize cost
		if G.GAME.modifiers.cry_misprint_min then
			local misprint_seed = pseudoseed("cry_misprint" .. G.GAME.round_resets.ante)
			local logrnd_min = G.GAME.modifiers.cry_misprint_min
			local logrnd_max = G.GAME.modifiers.cry_misprint_max
			cardd.misprint_cost_fac = 1 / Spectrallib.log_random(misprint_seed, logrnd_min, logrnd_max)
			cardd:set_cost()
		end

		-- Set caps on all values
		local misprintize_caps = cardd.config.center.misprintize_caps or {}
		for ability_key, value_cap in pairs(misprintize_caps) do
			if (
				type(card.ability[ability_key]) == "table"
				and type(value_cap) == "table"
				and not Spectrallib.is_number(value_cap)
			) then
				for subability_key, subability_value_cap in pairs(value_cap) do
					if cardd.ability[ability_key][subability_key] > subability_value_cap then
						cardd.ability[ability_key][subability_key] = Spectrallib.sanity_check(subability_value_cap, Spectrallib.is_card_big(cardd))
					end
				end
			else
				if cardd.ability[ability_key] > value_cap then
					cardd.ability[ability_key] = Spectrallib.sanity_check(value_cap, Spectrallib.is_card_big(cardd))
				end
			end
		end
	end

	-- Finally perform manipulation
	if not args.bypass_checks and not args.no_deck_effects then
		Spectrallib.with_deck_effects(card, func)
	else
		func(card)
	end

	if card.ability.consumeable then
		for consumable_cfg_key in pairs(card.ability.consumeable) do
			card.ability.consumeable[consumable_cfg_key] = Spectrallib.deep_copy(card.ability[consumable_cfg_key])
		end
	end

	--ew ew ew ew
		-- What makes this ew? 
	G.P_CENTERS[card.config.center.key].config = center_config

	return true
end

-- Manipulate all values in a card's select table.
---@param card Card
---@param ref_table table
---@param ref_value string|any
---@param args table|{big?: boolean, dont_stack?: boolean}
---@return nil
function Spectrallib.manipulate_table(card, ref_table, ref_value, args)
	if ref_value == "consumeable" then return end

	local base_values = Spectrallib.base_values[card.config.center.key]

	for tbl_key, tbl_value in pairs(ref_table[ref_value]) do
		if
			Spectrallib.is_number(tbl_value)
			and Spectrallib.misprintize_value_blacklist[tbl_key] ~= false
		then
			-- Determine which value to manipulate
			local new_value = tbl_value
			if (
				args.dont_stack
				and base_values
				and (
					base_values[tbl_key .. ref_value]
					or (ref_value == "ability" and base_values[tbl_key .. "consumeable"])
				)
			) then
				new_value = base_values[tbl_key .. ref_value] or base_values[tbl_key .. "consumeable"]
			end

			-- Proceed to manipulation
			if args.big ~= nil then
				ref_table[ref_value][tbl_key] = Spectrallib.manipulate_value(new_value, args, args.big, tbl_key)
			else
				ref_table[ref_value][tbl_key] = Spectrallib.manipulate_value(new_value, args, Spectrallib.is_card_big(card), tbl_key)
			end
		elseif (
			tbl_key ~= "immutable"
			and type(tbl_value) == "table"
			and Spectrallib.misprintize_value_blacklist[tbl_key] ~= false
		) then
			Spectrallib.manipulate_table(card, ref_table[ref_value], tbl_key, args)
		end
	end
end

---@class Spectrallib.manipulate_value.args
---@field func function
---@field min number
---@field max number
---@field seed string|any
---@field type "+"|"X"|"^"|"hyper"
---@field value number|{arrows: number, height: number}

-- Calculate the manipulation of a given value.
---@param num number
---@param args table
---@param is_big boolean
---@param num_key string
function Spectrallib.manipulate_value(num, args, is_big, num_key)
	if not Spectrallib.is_number(num) then return end

	-- Calculate new value
	if args.func then
		num = args.func(num, args, is_big, num_key)
	else
		local new_num
		if args.min and args.max then
			local seed = pseudoseed(args.seed or ("cry_misprint" .. G.GAME.round_resets.ante))
			local big_min = to_big(args.min)
			local big_max = to_big(args.max)
			local operand = Spectrallib.log_random(seed, big_min, big_max)
			new_num = (
				Spectrallib.manipulate_types[args.type]
				and Spectrallib.manipulate_types[args.type](num, operand, num_key)
				or nil
			)
		elseif args.value then
			new_num = (
				Spectrallib.manipulate_types[args.type]
				and Spectrallib.manipulate_types[args.type](num, args.value, num_key)
				or nil
			)
		end
		if new_num then num = new_num end
	end

	-- Place cap on new value
	if Spectrallib.misprintize_value_cap[num_key] then
		num = math.min(num, Spectrallib.misprintize_value_cap[num_key])
	end

	-- Prevent blacklisted keys from being BigNum
	if Spectrallib.misprintize_bignum_blacklist[num_key] == false then
		num = to_number(num)
		return to_number(Spectrallib.sanity_check(num, false))
	end

	local val = Spectrallib.sanity_check(num, is_big)
	if -1e100 < val and val < 1e100 then
		return to_number(val)
	end
	return val
end

-- todo: figure out what tf this is supposed to be for
---@param val number
---@param is_big? boolean
---@return number
function Spectrallib.sanity_check(val, is_big)
	if not Spectrallib.can_mods_load("Talisman") then return val end

	if is_big then
		if not val or type(val) == "number" and (val < -1e300 or 1e300 < val) then
			val = 1e300
		end
		if Spectrallib.is_big(val) then
			return val
		end
		if val < -1e100 or 1e100 < val then
			return to_big(val)
		end
	end

	if not val or type(val) == "number" and (val < -1e300 or 1e300 < val)  then
		return 1e300
	end

	if Spectrallib.is_big(val) then
		if val > 1e300 then
			return 1e300
		end
		if val < -1e300 then
			return -1e300
		end
		return to_number(val)
	end

	return val
end
