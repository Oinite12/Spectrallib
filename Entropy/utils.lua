-- todo: not sure what to do with this, why is this needed? cryptlib already has this
function Cryptid.get_highlighted_cards(areas, ignore, min, max, blacklist, seed)
	ignore.checked = true
	blacklist = blacklist or function()
		return true
	end
	local cards = {}
	for i, area in pairs(areas) do
		if area.cards then
			for i2, card in pairs(area.cards) do
				if
					card ~= ignore
					and blacklist(card)
					and (card.highlighted or G.cry_force_use)
					and not card.checked
				then
					cards[#cards + 1] = card
					card.checked = true
				end
			end
		end
	end
	for i, v in ipairs(cards) do
		v.checked = nil
	end
	if (#cards >= min and #cards <= max) or not G.cry_force_use then
		ignore.checked = nil
		return cards
	else
		for i, v in pairs(cards) do
			v.f_use_order = i
		end
		pseudoshuffle(cards, pseudoseed("forcehighlight" or seed))
		local actual = {}
		for i = 1, max do
			if cards[i] and not cards[i].checked and actual ~= ignore and actual.original_card ~= ignore and actual ~= ignore.original_card then
				actual[#actual + 1] = cards[i]
			end
		end
		table.sort(actual, function(a, b)
			return a.f_use_order < b.f_use_order
		end)
		for i, v in pairs(cards) do
			v.f_use_order = nil
		end
		ignore.checked = nil
		return actual
	end
	return {}
end

function Spectrallib.get_highlighted_cards(cardareas, ignorecard, min, max, blacklist)
    return Cryptid.get_highlighted_cards(cardareas, ignorecard or {}, min or 1, max or 1, type(blacklist) == "table" and function(card)
        return not blacklist[card.config.center.key]
    end or blacklist)
end
if Entropy then Entropy.get_highlighted_cards = Spectrallib.get_highlighted_cards end --idk why this doesnt get redirected





-------------------------------
--#region INTERNAL UTILITIES --
-------------------------------

-- Generates a table that contains values fulfilling a certain condition.
---@param tbl any[]
---@param func fun(value: any, i: integer): boolean
---@return any[]
function Spectrallib.filter_table(tbl, func)
    local ret = {}
    for i, value in ipairs(tbl) do
        if func(value, i) then
            table.insert(ret, value)
        end
    end
    return ret
end

Spectrallib.charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890~#$^~#$^~#$^~#$^~#$^"
-- Generates a string of random characters.
---@param length integer
---@param charset? string
---@return string
function Spectrallib.string_random(length, charset)
    charset = charset or Spectrallib.charset
    local total = ""
    for _ = 0, length do
        local val = math.random(1, #charset)
        total = total .. charset:sub(val, val)
    end
    return total
end

-- Inserts a dollar sign to the given value.
---@param val number
---@return string
function Spectrallib.format_dollar_value(val)
    if val >= 0 then
        return localize("$")..val
    else
        return "-"..localize("$")..(-val)
    end
end

-- Checks if a value is contained in a table; returns the index of said item if inside table.
---@param tbl any[]
---@param find_val fun(val: any): boolean | any If this is a function, the function checks each individual item in the table.
---@return integer|nil
function Spectrallib.in_table(tbl, find_val)
    for i, value in ipairs(tbl) do
        if (
            type(find_val) == "function"
            and find_val(value)
            or value == find_val
        ) then
            return i
        end
    end
end

-- Formats hyperoperators.
---@param arrows integer|string
---|-2               # Operator set to =
---|-1               # Operator set to +
---|"addition"       # Operator set to +
---|0                # Operator set to X
---|"multiplication" # Operator set to X
---|1                # From 1-6, operator set to ^ (repeats `arrow` times)
---|"exponent"       # Operator set to ^
---|7                # From 7 and higher or -3 and lower, operator set to {`arrow`}
---@param mult number|string
function Spectrallib.format_arrow_mult(arrows, mult)
    if arrows == "addition" then arrows = -1 end
    if arrows == "multiply" then arrows = 0 end
    if arrows == "exponent" then arrows = 1 end
    if type(arrows) == "string" then arrows = 0 end
    mult = type(mult) ~= "string" and number_format(mult) or mult

    local operator = ("{%s}"):format(arrows)

    if arrows == -2 then
        operator = "="
    elseif arrows == -1 then
        operator = "+"
    elseif arrows == 0 then
        operator = "X"
    elseif 1 <= arrows or arrows <= 6 then
        operator = ("^"):rep(arrows)
    end

    return operator .. mult
end

-- alias lemniscate used for this function
function Spectrallib.format_arrow_value(...)
    return Spectrallib.format_arrow_mult(...)
end

-- todo: what is this for?
---@param orig? number
---@param new number
---@param etype string
---@return number
function Spectrallib.stack_eval_returns(orig, new, etype)
    local valid_keys = Spectrallib.list_to_keys({
        "Xmult", "x_mult", "Xmult_mod",
        "Xchips", "Xchip_mod", "x_asc",
        "Emult_mod", "Echip_mod"
    })

    if valid_keys[etype] then
        return (orig or 1) * new
    else
        return (orig or 0) + new
    end
end

-- Split a string into its characters.
---@param s string
---@return string[]
function Spectrallib.stringsplit(s)
    local tbl = {}
    for i = 1, #s do
        table.insert(tbl, s:sub(i,i))
    end
    return tbl
end

-- Approximates a repeated application of the log function.
---@param orig number
---@param base number The base of the log function.
---@param iter integer The number of times to apply the log function.
---@return number
function Spectrallib.approximate_log_recursion(orig, base, iter)
    if iter < 1000 then
        if orig < base then return orig end
        local result = orig
        for _ = 1, to_number(iter) do
            result = result * math.log(result, base)
        end
        return result
    else
        local m = iter/math.log(base)
        local l1 = math.log(m)
        local l2 = math.log(l1)
        local E = iter * (l1 + l2 - 1 + ((l2-2)/l1))
        local result = 2.718281846 ^ E
        return result
    end
end

-- Get a random element from a table, with the option to blacklist certain values.
---@param tbl table
---@param seed string|any
---@param blacklist fun(elem: any): (boolean|any) If truthy, element is excluded.
---@return any
function Spectrallib.pseudorandom_element(tbl, seed, blacklist)
    local elem = pseudorandom_element(tbl, seed)
    local tries = 0
    while blacklist(elem) and tries < 100 do
        elem = pseudorandom_element(tbl, seed)
        tries = tries + 1
    end
    return elem
end

--#endregion
-------------------------------

----------------------------------
--#region GAMEPLAY MODIFICATION --
----------------------------------

---@alias Spectrallib.flip_then.func fun(card: Card, cardlist: Card[], i: integer): any

-- Double-flips cards in the provided list, and also run functions before, during, and after double-flipping.
---@param cardlist Card[]
---@param func {func: Spectrallib.flip_then.func, delay: number}[] | Spectrallib.flip_then.func The functions to run on a card between flips.
---@param before fun(card: Card): any The function to run on a card before flipping once.
---@param after fun(card: Card): any The function to run on a card after flipping again.
---@return nil
function Spectrallib.flip_then(cardlist, func, before, after)
    local skipanims = Spectrallib.should_skip_animations()
    if type(func) ~= "table" then
        func = {{func = func, delay = 0.5}}
    end

    for _,card in ipairs(cardlist) do
        if not card then
            -- Skip the following
        elseif skipanims then
            if before then before(card) end
        else
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.4,
                func = function()
                    if before then before(card) end
                    if card.flip then card:flip() end
                    return true
                end
            }))
        end
    end

    for _,card in ipairs(cardlist) do
        if card then
            for i, func_def in ipairs(func) do
                G.E_MANAGER:add_event(Event({
                    trigger = "after",
                    delay = func_def.delay,
                    func = function()
                        func_def.func(card, cardlist, i)
                        return true
                    end
                }))
            end
        end
    end

    for _,card in ipairs(cardlist) do
        if not card then
            -- Skip the following
        elseif skipanims then
            if after then after(card) end
        else
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.4,
                func = function()
                    if card.flip then card:flip() end
                    if after then after(card) end
                    return true
                end
            }))
        end
    end
end

---@class Spectrallib.modify_hand_card.modifications
---@field suit? Suits|string
---@field rank? Ranks|string
---@field enhancement? string
---@field edition? string|table
---@field seal? string
---@field sticker? string
---@field extra? table

-- Generates a function that modifies a list of cards according to given specifications.
---@param modifications Spectrallib.modify_hand_card.modifications
---@param cards Card[]
---@param dont_flip? boolean If true, cards will not be flipped on modification.
---@return fun(self: any, card: Card): nil
function Spectrallib.modify_hand_card(modifications, cards, dont_flip)
    local func = function(mcard)
        if modifications.suit or modifications.rank then
            SMODS.change_base(mcard, modifications.suit, modifications.rank)
        end
        if modifications.enhancement then
            mcard:set_ability(G.P_CENTERS[modifications.enhancement])
        end
        if modifications.edition then
            if type(modifications.edition) == "table" then
                mcard:set_edition(modifications.edition)
            else
                mcard:set_edition(G.P_CENTERS[modifications.edition])
            end
        end
        if modifications.seal then
            mcard:set_seal(modifications.seal)
        end
        if modifications.sticker then
            Spectrallib.apply_sticker(mcard, modifications.sticker)
        end
        if modifications.extra then
            for extra_key, value in pairs(modifications.extra) do
                mcard.ability[extra_key] = value
            end
        end
    end

    return function(self, card)
        local cardlist = cards or Spectrallib.get_highlighted_cards({G.hand}, {}, 1, card.ability.highlighted or 1)
        if not dont_flip then
            Spectrallib.flip_then(cardlist, func)
        else
            for _, mcard in pairs(cardlist) do
                G.E_MANAGER:add_event(Event({
                    delay = 0,
                    func = function()
                        func(mcard)
                        return true
                    end
                }))
            end
        end
    end
end

-- Generates a function that modifies a list of cards according to given specifications. Cards will not be flipped on modification.
---@param modifications Spectrallib.modify_hand_card.modifications
---@param cards Card[]
---@return fun(self: any, card: Card): nil
function Spectrallib.modify_hand_card_NF(modifications, cards)
    return Spectrallib.modify_hand_card(modifications, cards, true)
end

-- Forcetrigger a random card.
---@param card Card The card causing the forcetriggering.
---@param count integer
---@param context table
---@return nil
function Spectrallib.random_forcetrigger(source_card, count, context)
    local searched_areas = {G.jokers, G.hand, G.consumeables, G.play}
    local random_condition = function(cardd)
        return not cardd.edition or cardd.edition.key ~= "e_entr_fractured"
    end
    local cards = Spectrallib.get_random_cards(searched_areas, count, "fractured", random_condition)

    for _, card in pairs(cards) do
        if card.base.id and (not card.edition or card.edition.key ~= "e_entr_fractured") then
            for _,area in ipairs({G.play, G.hand}) do
                local results = eval_card(card, {cardarea=area, main_scoring=true, forcetrigger=true, individual=true})
                for _, result_group in pairs(results or {}) do
                    if type(result_group) == "table" then
                        for effect_key, result in pairs(result_group) do
                            SMODS.calculate_individual_effect({[effect_key] = result}, source_card, effect_key, result, false)
                        end
                    end
                end
            end
            card_eval_status_text( card,"extra", nil, nil, nil, { message = localize("cry_demicolon"), colour = G.C.GREEN })
        elseif not card.edition or card.edition.key ~= "e_entr_fractured" then
            Spectrallib.forcetrigger({card = card, context = context, mesasge_card = source_card})
        end
    end
end

-- Change the enhancement of all cards in the provided card areas.
---@param areas CardArea[]|Card[]
---@param enhancement_key string Key of the enhancement to transform into.
---|"null" Destroy all cards that meet requirements.
---|"ccd" Do completely nothing.
---@param required string Key of the enhancement of cards to transform. If nil, all cards will be transformed.
---@return nil
function Spectrallib.change_enhancements(areas, enhancement_key, required)
    for i, area in pairs(areas) do
        if not area.cards then 
            areas[i] = {cards = {area}}
        end
    end

    for _,area in pairs(areas) do
        for _, card in pairs(area.cards) do
            if not required or (card.config and card.config.center.key == required) then
                if enhancement_key == "null" then
                    card:start_dissolve()
                elseif enhancement_key == "ccd" then
                    -- Do nothing
                else
                    card:set_ability(G.P_CENTERS[enhancement_key])
                    card:juice_up()
                end
            end
        end
    end
end

---@param card Card
---@param sticker_key string
---@return nil
function Spectrallib.apply_sticker(card, sticker_key)
    local sticker = SMODS.Stickers[sticker_key]
    if not sticker then return end
    if not card.ability then card.ability = {} end

    card.ability[sticker_key] = true
    if sticker.apply then
        sticker.apply(sticker, card)
    end
end

---@param mod number Added to current play limit.
---@param stroverride string The label to display for the play limit.
---@return nil
function Spectrallib.change_play_limit_no_bs(mod,stroverride)
    if SMODS.hand_limit_strings then
        G.GAME.starting_params.play_limit = (G.GAME.starting_params.play_limit or 5) + mod
        G.hand.config.highlighted_limit = math.max(G.GAME.starting_params.discard_limit or 5, G.GAME.starting_params.play_limit or 5)
        local str = stroverride or G.GAME.starting_params.play_limit or ""
        SMODS.hand_limit_strings.play = G.GAME.starting_params.play_limit ~= 5 and localize('b_limit') .. str  or ''
    else
        G.hand.config.highlighted_limit = G.hand.config.highlighted_limit + mod
    end
end

---@param mod number Added to current play limit.
---@param stroverride string The label to display for the discard limit.
---@return nil
function Spectrallib.change_discard_limit_no_bs(mod,stroverride)
    G.GAME.starting_params.discard_limit = (G.GAME.starting_params.discard_limit or 5) + mod
    G.hand.config.highlighted_limit = math.max(G.GAME.starting_params.discard_limit or 5, G.GAME.starting_params.play_limit or 5)
    local str = stroverride or G.GAME.starting_params.discard_limit or ""
    SMODS.hand_limit_strings.discard = G.GAME.starting_params.discard_limit ~= 5 and localize('b_limit') .. str or ''
end

---@param mod number Added to current play limit.
---@param stroverride string The label to display for the play and discard limit.
---@return nil
function Spectrallib.change_selection_limit(mod,stroverride)
    if not SMODS.hand_limit_strings then SMODS.hand_limit_strings = {} end
    Spectrallib.change_play_limit_no_bs(mod,stroverride)
    if SMODS.hand_limit_strings then
        Spectrallib.change_discard_limit_no_bs(mod,stroverride)
    end
end

--#endregion
----------------------------------

----------------------------
--#region OBJECT CHECKING --
----------------------------

-- Get the previous item in a pool before a given item.
---@param item_key string Key of the item to check predecessor of.
---@param pool_name string
---@param ignore? integer When iterating through the pool, this value corresponds to the index to ignore.
---@return string|nil
function Spectrallib.find_previous_in_pool(item_key, pool_name, ignore)
    local select_pool = G.P_CENTER_POOLS[pool_name]
    for i in pairs(select_pool) do
        if select_pool[i].key == item_key then
            local ind = i - 1
            while (
                G.GAME.banned_keys[select_pool[ind].key]
                or select_pool[ind].no_doe
                or ind == ignore
            ) do
                ind = ind - 1
            end
            return select_pool[ind].key
        end
    end
    return nil
end

-- Given the rarity rank list `Spectrallib.RarityChecks`, get the rarity higher than the given rarity.<br>
-- If such does not exist, return the given rarity.
---@param rarity integer|string
---@return integer|string
function Spectrallib.get_next_rarity(rarity)
    if rarity == "entr_reverse_legendary" then return "cry_exotic" end
    for i, next_rarity in pairs(Spectrallib.RarityChecks) do
        if next_rarity == rarity then
            return Spectrallib.RarityChecks[i+1] or next_rarity
        end
    end
    return rarity
end

-- Given the rarity rank list `Spectrallib.RarityChecks`, check if a rarity is lower than another rarity.
---@param check integer|string
---@param threshold integer|string
---@param check_greater_than boolean If true, the comparison is based on greater-than (<) instead of greater-than/equal (<=).
function Spectrallib.rarity_above(check, threshold, check_greater_than)
    if not Spectrallib.ReverseRarityChecks[check] then
        Spectrallib.ReverseRarityChecks[check] = 1
    end
    if not Spectrallib.ReverseRarityChecks[threshold] then
        Spectrallib.ReverseRarityChecks[threshold] = 1
    end
    if check_greater_than then
        return Spectrallib.ReverseRarityChecks[check] < Spectrallib.ReverseRarityChecks[threshold]
    end
    return Spectrallib.ReverseRarityChecks[check] <= Spectrallib.ReverseRarityChecks[threshold]
end

-- Get a random center with a given rarity.
---@param rarity string|integer
---@return table
function Spectrallib.get_random_rarity_card(rarity)
    if rarity == 1 then rarity = "Common" end
    if rarity == 2 then rarity = "Uncommon" end
    if rarity == 3 then rarity = "Rare" end
    local _pool, _pool_key = get_current_pool("Joker", rarity, rarity == 4, "ieros")
    local center = pseudorandom_element(_pool, pseudoseed(_pool_key))
    local it = 1 -- Resample index
    while center == 'UNAVAILABLE' do
        it = it + 1
        center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
    end
    return center
end

-- Position -> Rarity key
Spectrallib.RarityChecks = {1, 2, 3, 4}
if Cryptid and Cryptid.memepack then --using legacy stuff to check for cryptid and not cryptlib
    Spectrallib.RarityChecks = {[0] = "cry_candy", 1, 2, 3, "cry_epic", 4, "cry_exotic", "entr_entropic"}
end

-- Rarity key -> Position
Spectrallib.ReverseRarityChecks = {}
for i, v in ipairs(Spectrallib.RarityChecks) do
    Spectrallib.ReverseRarityChecks[v] = i
end

-- Get the key of the higher tier of a voucher, if it has higher tiers.
---@param voucher_key string
---@return string
function Spectrallib.get_higher_voucher_tier(voucher_key)
    for _, voucher in pairs(G.P_CENTER_POOLS.Voucher) do
        if Spectrallib.in_table(voucher.requires or {}, voucher_key) then
            return voucher.key
        end
    end
end

-- Get a random set.
function Spectrallib.get_random_set(has_parakmi)
    local pool = pseudorandom_element(G.P_CENTER_POOLS, pseudoseed(has_parakmi and "parakmi" or "chaos"))
    local set = pool and pool[1] and G.P_CENTERS[pool[1].key] and pool[1].set

    while (
        not set
        or Spectrallib.ParakmiBlacklist[set]
        or (not has_parakmi and Spectrallib.ChaosBlacklist[set])
    ) do
        pool = pseudorandom_element(G.P_CENTER_POOLS, pseudoseed(has_parakmi and "parakmi" or "chaos"))
        set = pool and pool[1] and G.P_CENTERS[pool[1].key] and pool[1].set
    end

    return set
end

-- Get a random set of cards from the select areas.
---@param areas CardArea[]
---@param count integer
---@param seed string|any
---@param cond fun(card: Card): boolean Iterated over each card; if true, the card can have a chance to be randomly selected.
---@return Card[]
function Spectrallib.get_random_cards(areas, count, seed, cond)
    local cards = {}
    for _, area in pairs(areas) do
        for _, card in pairs(area.cards) do
            if not cond or cond(card) then
                table.insert(cards, card)
            end
        end
    end

    pseudoshuffle(cards, pseudoseed(seed or "fractured"))

    local ret = {}
    for i = 1, count do
        table.insert(ret, cards[i])
    end
    return ret
end

-- Counts how many times a deck's effect is applied to the run.
---@param key string
---@return integer|nil
function Spectrallib.deck_or_sleeve(key)
    local num = 0
    if key == "doc" and G.GAME.modifiers.doc_antimatter then
        num = num + 1
    elseif key == "butterfly" and G.GAME.modifiers.butterfly_antimatter then
        num = num + 1
    end

    if Spectrallib.can_mods_load({"CardSleeves"}) and (
        G.GAME.selected_sleeve == ("sleeve_entr_"..key)
        or G.GAME.selected_sleeve == key
        or G.GAME.selected_sleeve == "sleeve_"..key
    ) then
        num = num + 1
    end

    for _, bought_deck_key in pairs(G.GAME.entr_bought_decks or {}) do
        if (
            bought_deck_key == "b_entr_"..key
            or bought_deck_key == key
            or bought_deck_key == "b_"..key
            or bought_deck_key == "sleeve_"..key)
        then
            num = num + 1
        end
    end

    if G.GAME.selected_back and (
        G.GAME.selected_back.effect.center.original_key == key
        or G.GAME.selected_back.effect.center.key == key
        or G.GAME.selected_back.effect.center.original_key == "b_"..key
        or G.GAME.selected_back.effect.center.key == "b_"..key
    ) then
        num = num + 1
    end

    return num > 0 and num or nil
end

-- Get the higher enhancement of a card's enhancement (as defined by `card.upgrade_order` in enhancement prototypes).
---@param card Card
---@param bypass boolean Whether to bypass `card.no_doe` or not.
---@param blacklist string[] A list of keys of enhancements to ignore.
---@return string|nil
function Spectrallib.upgrade_enhancement(card, bypass, blacklist)
    local current_enh = card.config.center.key
    if current_enh == "c_base" then return "m_bonus" end

    local enhancements = {}
    for _,enhancement in pairs(G.P_CENTER_POOLS.Enhanced) do
        if (not enhancement.no_doe or bypass) and not blacklist[enhancement.key] then
            table.insert(enhancements, enhancement)
        end
    end

    table.sort(enhancements, function(a, b)
        return (a.upgrade_order or a.order) < (b.upgrade_order or b.order)
    end)

    for i, enhancement in pairs(enhancements) do
        if enhancement.key == current_enh then
            return enhancements[i+1] and enhancements[i+1].key
        end
    end
    return nil
end

-- Get the key of a card area in `G`.
---@param area CardArea
---@return string|nil
function Spectrallib.get_area_name(area) 
    if not area then return nil end
    for i, v in pairs(G) do
        if v == area then return i end
    end
end

-- Get the index of a card in its area.
---@param card Card
---@return integer|nil
function Spectrallib.get_idx_in_area(card)
    if card and card.area then
        for i, v in pairs(card.area.cards) do
            if v == card then return i end
        end
    end
end

-- Give a random context key.
---@param seed string|any
---@return "before"|"pre_joker"|"joker_main"|"individual"|"pre_discard"|"remove_playing_cards"|"setting_blind"|"ending_shop"|"reroll_shop"|"selling_card"|"using_consumeable"|"playing_card_added"
---@return any
function Spectrallib.random_context(seed)
    --Is this useful? idk but its entropy agnostic so :shrug:
    return pseudorandom_element({
        "before",
        "pre_joker",
        "joker_main",
        "individual",
        "pre_discard",
        "remove_playing_cards",
        "setting_blind",
        "ending_shop",
        "reroll_shop",
        "selling_card",
        "using_consumeable",
        "playing_card_added"
    }, pseudoseed(seed or "desync"))
end

-- A shorthand for various context checks.
---@param self any
---@param card Card
---@param context table
---@param currc string
---@param edition boolean|any
---@return boolean|nil
function Spectrallib.context_checks(self, card, context, currc, edition)
    if (
        context.retrigger_joker
        or context.blueprint
        or context.forcetrigger
        or context.post_trigger
    ) then return end

    local context_check = Spectrallib.context_check_def[currc]
    if not context_check then
        return
    elseif type(context_check) == "function" and context_check(card, context, currc, edition) then
        return true
    elseif context_check == true then
        return true
    end
end

---@type {[string]: true | fun(card: Card, context: table, currc: string, edition: boolean|any): (boolean|any) }
Spectrallib.context_check_def = {
    pre_joker = function (card, context, currc, edition)
        return context.pre_joker or (
            edition
            and context.main_scoring
            and context.cardarea == G.play
        )
    end,
    joker_main = function (card, context, currc, edition)
        return context.joker_main or (
            edition
            and context.main_scoring
            and context.cardarea == G.play
        )
    end,
    individual = function (card, context, currc, edition)
        return (
            context.individual
            and context.cardarea == G.play
            and not context.blueprint
        ) or (
            edition
            and context.main_scoring
            and context.cardarea == G.play
        )
    end,
    pre_discard = function (card, context, currc, edition)
        return (
            context.pre_discard
            and context.cardarea == G.hand
            and not context.retrigger_joker
            and not context.blueprint
        )
    end,
    remove_playing_cards = function (card, context, currc, edition)
        return (
            context.remove_playing_cards
            and not context.blueprint
        )
    end,
    -- Equivalent to `function(card, context, currc, edition) return context[key] end`
    before = true,
    setting_blind = true,
    ending_shop = true,
    reroll_shop = true,
    selling_card = true,
    using_consumeable = true,
    playing_card_added = true,
}

-- Get the number of times that the given card will repeat.
---@param card Card
---@return {repetitions: integer}
function Spectrallib.get_repetitions(card)
    local res2 = {}
    for _, joker in ipairs(G.jokers.cards) do
        local res = eval_card(joker, {
            repetition = true,
            other_card = card,
            cardarea = card.area,
            card_effects = {{},{}}
        }) or {}
        if res.jokers and res.jokers.repetitions then
            res2.repetitions = (res2.repetitions or 0) + res.jokers.repetitions
        end
    end
    return res2
end

-- todo: figure out what this does
---@param poker_hands table
---@return string|nil
function Spectrallib.no_recurse_scoring(poker_hands)
    local text, scoring_hand
	for _, hand in ipairs(G.handlist) do
		if next(poker_hands[hand]) then
			text = hand
			scoring_hand = poker_hands[hand][1]
			break
		end
	end
    return text
end

--#endregion
----------------------------------

---------------
--#region UI --
---------------

-- Creates a UI node containing a random character.
---@param arr string
---@return {n: G.UIT.O, config: {object: DynaText}}
function Spectrallib.randomchar(arr)
    return {
        n = G.UIT.O,
        config = {
            object = DynaText({
                string = arr,
                colours = { HEX("b1b1b1") },
                pop_in_rate = 9999999,
                silent = true,
                random_element = true,
                pop_delay = 0.1,
                scale = 0.3,
                min_cycle_time = 0,
            }),
        },
    }
end

--#endregion
---------------












--------------
-- UNSORTED --
--------------

-- Get a center that is in a pool.
---@param _type string
---@param twisted any
---@param _rarity string
---@param _noparakmi boolean
---@param soulable boolean
---@param key_append string
function Spectrallib.get_pooled_center(_type, twisted, _rarity, _noparakmi, soulable, key_append)
    local center = G.P_CENTERS.b_red
    local forced_key

    --should pool be skipped with a forced key
    if not forced_key and soulable and (not G.GAME.banned_keys['c_soul']) then
        for _, v in ipairs(SMODS.Consumable.legendaries) do
            if (_type == v.type.key or _type == v.soul_set) and not (G.GAME.used_jokers[v.key] and not SMODS.showman(v.key) and not v.can_repeat_soul) and SMODS.add_to_pool(v, {}) then
                if pseudorandom('soul_'..v.key.._type..G.GAME.round_resets.ante) > (1 - v.soul_rate) then
                    if not G.GAME.banned_keys[v.key] then forced_key = v.key end
                end
            end
        end
        if (_type == 'Tarot' or _type == 'Spectral' or _type == 'Tarot_Planet') and
        not (G.GAME.used_jokers['c_soul'] and not SMODS.showman("c_soul"))  then
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_soul'
            end
        end
        if (_type == 'Planet' or _type == 'Spectral') and
        not (G.GAME.used_jokers['c_black_hole'] and not SMODS.showman("c_black_hole"))  then 
            if pseudorandom('soul_'.._type..G.GAME.round_resets.ante) > 0.997 then
                forced_key = 'c_black_hole'
            end
        end
    end

    if _type == 'Base' then 
        forced_key = 'c_base'
    end
    G.GAME.entr_parakmi_bypass = _noparakmi
    if forced_key and not G.GAME.banned_keys[forced_key] then 
        center = G.P_CENTERS[forced_key]
        _type = (center.set ~= 'Default' and center.set or _type)
    else
        local _pool, _pool_key = get_current_pool(_type, _rarity, legendary, key_append)
        center = pseudorandom_element(_pool, pseudoseed(_pool_key))
        local it = 1
        while center == 'UNAVAILABLE' do
            it = it + 1
            center = pseudorandom_element(_pool, pseudoseed(_pool_key..'_resample'..it))
        end

        center = G.P_CENTERS[center]
    end
    G.GAME.entr_parakmi_bypass = nil
    return center
end

function Spectrallib.count_stickers(card)
    local total = 0
    local cards = {}
    local add_self = true
    for i, v in pairs({G.jokers, G.consumeables, G.hand, G.play, G.deck}) do
        for i2, v2 in pairs(v.cards) do
            cards[#cards+1] = v2
            if v2 == card then add_self = nil end
        end
    end
    if add_self then cards[#cards+1] = card end
    for i, v in pairs(SMODS.Sticker.obj_table) do
        for i2, v2 in pairs(cards) do
            if v2.ability and v2.ability[i] then
                total = total + 1
            end
        end
    end
    return total
end

function Spectrallib.unhighlight(areas) 
    for i, v in pairs(areas) do
        v:unhighlight_all()
    end
end

function Spectrallib.get_inverse_suit(suit)
    return ({
        Diamonds = "Hearts",
        Hearts = "Diamonds",
        Clubs = "Spades",
        Spades = "Clubs"
    })[suit] or suit
end

function Spectrallib.get_inverse_rank(rank)
    return ({
        ["2"] = "Ace",
        ["3"] = "King",
        ["4"] = "Queen",
        ["5"] = "Jack",
        ["6"] = "10",
        ["7"] = "9",
        ["9"] = "7",
        ["10"] = "6",
        ["11"] = "5",
        ["12"] = "4",
        ["13"] = "3",
        ["14"] = "2"
        --["8"] = 8 duh
    })[tostring(rank)] or rank
end

function Spectrallib.randomise_once(card, types, seed, noflip)
    local mtype = pseudorandom_element(types or {"Enhancement", "Edition", "Seal", "Base"}, pseudoseed(seed or "ihwaz"))    
    if mtype == "Edition" then
        local edition = SMODS.poll_edition({guaranteed = true, key = "entr_ihwaz"})
        card:set_edition(edition)
        card:juice_up()
    end
    if mtype == "Enhancement" then
        local enhancement = SMODS.poll_enhancement({guaranteed = true, key = seed or "entr_ihwaz"})
        if not noflip then
            card:flip()
        end
        card:set_ability(G.P_CENTERS[enhancement])
        if not noflip then
            card:flip()
        end
    end
    if mtype == "Seal" then
        local seal = SMODS.poll_seal{guaranteed = true, key = seed or "ihwaz"}
        card:set_seal(seal)
        card:juice_up()
    end
    if mtype == "Base" then
        if not noflip then
            card:flip()
        end
        Spectrallib.randomize_rank_suit(card, true, true, seed or "ihwaz")
        if not noflip then
            card:flip()
        end
    end
end

function Spectrallib.randomize_rank_suit(card, rank, suit, seed)
    local ranks = {}
    local suits = {}
    if rank then
        for i, v in pairs(SMODS.Ranks) do
            if SMODS.add_to_pool(v, {}) then ranks[#ranks+1] = i end
        end
    end
    if suit then
        for i, v in pairs(SMODS.Suits) do
            if SMODS.add_to_pool(v, {}) then suits[#suits+1] = i end
        end
    end
    SMODS.change_base(card, pseudorandom_element(suits, pseudoseed(seed)),pseudorandom_element(ranks, pseudoseed(seed)), nil)
end

function Spectrallib.is_in_shop(key, consumable)
	local center = G.P_CENTERS[key]
	if center.hidden or center.no_doe or center.no_collection then
		return
	elseif G.GAME.banned_keys[key] or not center.unlocked then
		return
	elseif center.set == "Joker" then
		if type(center.rarity) == "number" and center.rarity <= 3 then
			return center.unlocked or nil
		end
		local rare = ({
			"Common",
			"Uncommon",
			"Rare",
		})[center.rarity] or center.rarity
		if
			SMODS.Rarities[rare]
			and (
				SMODS.Rarities[rare].get_weight
				or (SMODS.Rarities[rare].default_weight and SMODS.Rarities[rare].default_weight > 0)
			)
		then
			return center.unlocked or nil
		end
		return nil
	else
		if consumable then
			if center.set == "Tarot" then
				return G.GAME.tarot_rate * (G.GAME.cry_percrate.tarot / 100) > 0 or nil
			end
			if center.set == "Planet" then
				return G.GAME.planet_rate * (G.GAME.cry_percrate.planet / 100) > 0 or nil
			end
			if center.set == "Spectral" then
				return G.GAME.spectral_rate > 0 or nil
			end
			local num = G.GAME.cry_percrate and G.GAME.cry_percrate[center.set:lower()] or 100
			local val = G.GAME[center.set:lower() .. "_rate"] * ((num or 100) / 100)
			return val > 0
		end
	end
	return SMODS.add_to_pool(center, {})
end

function Spectrallib.true_suitless(card)
    if SMODS.has_no_suit(card) or card.config.center.key == "m_stone" 
    or card.config.center.overrides_base_rank 
    or card.base.suit == "entr_nilsuit" 
    or card.base.value == "entr_nilrank" then return true end
end

function Spectrallib.played_hands(threshold)
    local total = 0
    for i, v in pairs(G.GAME.hands or {}) do
        if to_big(v.played) > to_big(threshold) then
            total = total + 1
        end
    end
    return total
end

function Spectrallib.calculate_ratios(incl_vanilla, only_vanilla)
    local total = 0
    local rarities = {}
    for i, v in pairs(G.P_CENTER_POOLS.Joker) do
        if (not only_vanilla and v.original_mod and v.original_mod.id == "entr") or (incl_vanilla and not v.original_mod) then
                if not v.no_collection then
                total = total + 1
                if not rarities[v.rarity] then rarities[v.rarity] = 0 end
                rarities[v.rarity] = rarities[v.rarity] + 1
            end
        end
    end
    for i, v in pairs(rarities) do
        print(i.." = "..v.. " = "..(v/total * 100).."%")
    end
    print("total: "..total)
end

function Spectrallib.allow_spawning(center)
    for i, v in pairs(G.I.CARD) do
        if v.config and v.config.center and center and v.config.center.key == center.key then return SMODS.showman(center.key) or nil end
    end
    return true
end

function Spectrallib.can_be_pulled(card)
    local center = card.ability.glitched_crown and G.P_CENTERS[card.ability.glitched_crown[card.glitched_index]] or card.config.center
    if not card:selectable_from_pack(SMODS.OPENED_BOOSTER) and next(SMODS.find_card("j_entr_oekrep")) and card.ability.consumeable then --should probably have a hookable function like SMODS.showman instead of a hardcoded Oekrep check
        return not center.hidden and not center.no_select
    end
    return not center.no_select and (SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].can_be_pulled or center.can_be_pulled) and not center.hidden
end

function Spectrallib.needs_pull_button(card)
    local center = card.config.center
    if not card:selectable_from_pack(SMODS.OPENED_BOOSTER) and next(SMODS.find_card("j_entr_oekrep")) and card.ability.consumeable then
        return not center.hidden and not center.no_select and localize("b_select")
    end
    if not center.no_select and (SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].can_be_pulled or center.can_be_pulled) and not center.hidden then
        local loc = SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].can_be_pulled or center.can_be_pulled
        return localize(type(loc) == "string" and loc or "b_select")
    end
    for i, v in pairs(card.ability.glitched_crown or {}) do
        local center = G.P_CENTERS[v]
        if center and not center.no_select and (SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].can_be_pulled or center.can_be_pulled) and not center.hidden then
            local loc = SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].can_be_pulled or center.can_be_pulled
            return localize(type(loc) == "string" and loc or "b_select")
        end
    end
end

function Spectrallib.needs_use_button(card)
    local center = card.config.center
    local center_cant_use = false
    if not (center.no_use_button or (SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].no_use_button)) then
        center_cant_use = true
    end
    for i, v in pairs(card.ability.glitched_crown or {}) do
        local center = G.P_CENTERS[v]
        if not (center.no_use_button or (SMODS.ConsumableTypes[center.set] and SMODS.ConsumableTypes[center.set].no_use_button)) then
            center_cant_use = true
        end
    end
    return center_cant_use
end

function Spectrallib.reduction_index(card, pool, strict)
    local i = 0
    for _, v in pairs(G.P_CENTER_POOLS[pool]) do
        if card.config and v.key == card.config.center_key then
            break
        end
        i = i + 1
    end
    if strict then
        while G.P_CENTER_POOLS[pool] 
            and G.P_CENTER_POOLS[pool][i] 
            and (G.P_CENTER_POOLS[pool][i].no_doe 
            or G.P_CENTER_POOLS[pool][i].no_collection)
        do
            i = i - 1
        end
    end
    if i < 1 then i = 1 end
    return i
end

function Spectrallib.reduce_cards(cards, card)
    if cards.ability then cards = {cards} end
    Spectrallib.flip_then(cards, function(card)
        local ind = Spectrallib.reduction_index(card, card.config.center.set, true)
        if G.P_CENTER_POOLS.Joker[ind] then
            card:set_ability(G.P_CENTER_POOLS.Joker[ind])
        end
        card.area:remove_from_highlighted(card)
    end)
end

function Spectrallib.handle_card_limit(area, num)
    area.config.card_limit = area.config.card_limit + (num or 0)
    area:handle_card_limit()
end

function Spectrallib.should_skip_animations(strict)
    if Talisman and Talisman.config_file.disable_anims then return true end
    if Handy and Handy.animation_skip and Handy.animation_skip.get_value and Handy.animation_skip.get_value() >= (strict and 4 or 3) then return true end
end

function Spectrallib.get_random_rare(seed)
    seed = seed or "entr_rare"
    local cards = {}
    for i, v in pairs(G.P_CENTERS) do
        if SMODS.add_to_pool(v, {}) and v.hidden and not v.no_doe then
            cards[#cards+1] = v
        end
    end
    return pseudorandom_element(cards, pseudoseed(seed))
end

function Spectrallib.get_card_pixel_pos(card)
    return {
        (G.ROOM.T.x + card.T.x + card.T.w * 0.5) * (G.TILESIZE * G.TILESCALE),
        (G.ROOM.T.y + card.T.y + card.T.h * 0.5) * (G.TILESIZE * G.TILESCALE),
    }
end

function Spectrallib.pythag(a, b)
    local ax, ay, bx, by = a[1], a[2], b[1], b[2]
    return math.sqrt(((ax - bx) ^ 2) + ((ay - by) ^ 2))
end

function Spectrallib.max_diagonal()
    return Spectrallib.pythag({0, 0}, {love.graphics.getWidth(), love.graphics.getHeight()})
end

function Spectrallib.get_dummy(center, area, self, silent)
    local abil = copy_table(center.config) or {}
    abil.consumeable = copy_table(abil)
    abil.name = center.name or center.key
    abil.set = center.set
    abil.t_mult = abil.t_mult or 0
    abil.t_chips = abil.t_chips or 0
    abil.x_mult = abil.x_mult or abil.Xmult or 1
    abil.extra_value = abil.extra_value or 0
    abil.d_size = abil.d_size or 0
    abil.mult = abil.mult or 0
    abil.effect = center.effect
    abil.h_size = abil.h_size or 0
    abil.card_limit = abil.card_limit or 1
    abil.extra_slots_used = abil.extra_slots_used or 0
    local eligible_editionless_jokers = {}
    for i, v in pairs(G.jokers and G.jokers.cards or {}) do
        if not v.edition then
            eligible_editionless_jokers[#eligible_editionless_jokers + 1] = v
        end
    end
    local tbl = {
        ability = abil,
        config = {
            center = center,
            center_key = center.key
        },
        juice_up = function(_, ...)
            return self:juice_up(...)
        end,
        start_dissolve = function(_, ...)
            if not _.silent then
                return self:start_dissolve(...)
            end
        end,
        remove = function(_, ...)
            return self:remove(...)
        end,
        flip = function(_, ...)
            return self:flip(...)
        end,
        can_use_consumeable = function(self, ...)
            return Card.can_use_consumeable(self, ...)
        end,
        calculate_joker = function(self, ...)
            return Card.calculate_joker(self, ...)
        end,
        can_calculate = function(self, ...)
            return Card.can_calculate(self, ...)
        end,
        set_cost = function(self, ...)
            Card.set_cost(self, ...)
        end,
        calculate_sticker = function(self, ...)
            Card.calculate_sticker(self, ...)
        end,
        base_cost = 1,
        extra_cost = 0,
        original_card = self,
        area = area,
        added_to_deck = added_to_deck,
        cost = self.cost,
        sell_cost = self.sell_cost,
        eligible_strength_jokers = eligible_editionless_jokers,
        eligible_editionless_jokers = eligible_editionless_jokers,
        T = self.T,
        VT = self.VT,
        CT = self.CT,
        silent = silent
    }
    for i, v in pairs(Card) do
        if type(v) == "function" and i ~= "flip_side" then
            tbl[i] = function(_, ...)
                return v(self, ...)
            end
        end
    end
    tbl.set_edition = function(s, ed, ...)
        Card.set_edition(s, ed, ...)
    end
    tbl.get_chip_h_x_mult = function(s, ...)
        local ret = SMODS.multiplicative_stacking(s.ability.h_x_mult or 1,
            (not s.ability.extra_enhancement and s.ability.perma_h_x_mult) or 0)
        return ret
    end
    tbl.get_chip_x_mult = function(s, ...)
        local ret = SMODS.multiplicative_stacking(s.ability.x_mult or 1,
            (not s.ability.extra_enhancement and s.ability.perma_x_mult) or 0)
        return ret
    end
    tbl.use_consumeable = function(self, ...)
        self.bypass_echo = true
        local ret = Card.use_consumeable(self, ...)
        self.bypass_echo = nil
    end
    return tbl
end

local card_eval_status_text_ref = card_eval_status_text
function card_eval_status_text(card, ...)
    return card_eval_status_text_ref(card.original_card or card, ...)
end

function Spectrallib.concat_strings(tbl)
    local result = ""
    for i, v in pairs(tbl) do result = result..v end
    return result
end

function Spectrallib.get_by_sortid(id)
    for i, v in pairs(G.jokers.cards) do
        if v.sort_id == id then return v end
    end
end

function Spectrallib.trigger_enhancement(enh, card)
    if G.P_CENTERS[enh].demicoloncompat then
        return G.P_CENTERS[enh]:calculate(card, {forcetrigger = true})
    end
    local lucky = {}
    if SMODS.pseudorandom_probability(card, 'entr_chameleon', 1, 5) then
        lucky.mult = 20
    end
    if SMODS.pseudorandom_probability(card, 'entr_chameleon', 1, 15) then
        lucky.money = 20
    end
    local funcs = {
        m_mult = {mult = 4},
        m_bonus = {chips = 30},
        m_glass = {xmult = 2},
        m_steel = {xmult = 1.5},
        m_stone = {chips = 50},
        m_gold = {money=3},
        m_lucky = lucky
    }
    if funcs[enh] then
        return funcs[enh]
    end
end

function Spectrallib.gather_values(card)
    local total = 0
    for i, v in pairs(card.ability) do
        if Spectrallib.is_number(v) and to_big(v) > to_big(1) and i ~= "order" then
            total = total + v
        elseif type(v) == "table" then
            total = total + Spectrallib.gather_values({ability = v})
        end
    end
    return total
end

function Spectrallib.kind_to_set(kind, c)
    local check = {
        Arcana = "Tarot",
        Celestial = "Planet",
        Ethereal = "Spectral",
        Buffoon = "Joker",
        Inverted = c and "Twisted" or nil
    }
    local kind2 = check[kind] or kind
    check.Inverted = "Twisted"
    local check2 = check[kind] or kind
    if not G.P_CENTER_POOLS[kind2] and not G.P_CENTER_POOLS[check2] then return end
    return kind2
end

function Spectrallib.missing_ranks()
    local ranks = {}
    for i, v in pairs(SMODS.Ranks) do
        if not v.original_mod and not v.mod then ranks[v.id] = 0 end
    end
    for i, v in pairs(G.playing_cards or {}) do
        if ranks[v.base.id] then
            ranks[v.base.id] = ranks[v.base.id] + 1
        end
    end
    local total = 0
    for i, v in pairs(ranks) do
        if v == 0 then total = total + 1 end
    end
    return total
end

function Spectrallib.shares_aspect(card1, card2)
    if card1:get_id() == card2:get_id() then return true end
    if card1.config.center.set ~= "Default" and card1.config.center.key == card2.config.center.key then return true end
    if card1.edition and card2.edition and card1.edition.key == card2.edition.key then return true end
    if card1.seal and card1.seal == card2.seal then return true end
end



function Card:is_playing_card()
    if not G.deck or not self then return end
    if self.area == G.play and self.ability.consumeable then return end
    if (self.area == G.hand or self.area == G.play or self.area == G.discard) and (self.config.center.set == "Default" or self.config.center.set == "Enhanced") then return true end
    for i, v in pairs(G.playing_cards) do
        if v == self then return true end
    end
    if self.area and self.area.config.view_deck then return true end
end





Spectrallib.ChaosBlacklist = {}
Spectrallib.ParakmiBlacklist = {}
Spectrallib.ChaosConversions = {}
Spectrallib.ConsumablePackBlacklist = { --identical to entropy, for some reason entropy table was still used in use and sell buttons hook
    p_mupack_multipack1=true,
    p_mupack_multipack2=true,
    p_mupack_multipack3=true,
    p_mupack_multipack4=true,
    p_mupack_multipack5=true,
}