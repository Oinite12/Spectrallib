-- Hook for EXPLOIT://-provided temporary Ascension power
local gf_cryascui_ref = G.FUNCS.cry_asc_UI_set
function G.FUNCS.cry_asc_UI_set(e)
    gf_cryascui_ref(e)
    if G.GAME.cry_exploit_override then
        e.config.object.colours = { darken(G.C.SECONDARY_SET.Code, 0.2) }
    end
end

-- Hook for Hyperspace Tether's effect
local splib_tether_hook = Spectrallib.has_tether
function Spectrallib.has_tether()
    if not splib_tether_hook() then
        return G.GAME.used_vouchers.v_cry_hyperspacetether
    end
end

-- Moving Cluterwark rename here
local gf_pokerhandinfo_ref = G.FUNCS.get_poker_hand_info
function G.FUNCS.get_poker_hand_info(_cards)
    local text, loc_disp_text, poker_hands, scoring_hand, disp_text = gf_pokerhandinfo_ref(_cards)
    -- Display text if played hand contains a Cluster and a Bulwark
    if text == "cry_Clusterfuck" and next(poker_hands["cry_Bulwark"]) then
        disp_text = "cry-Cluster Bulwark"
        loc_disp_text = localize(disp_text, "poker_hands")
    end
    return text, loc_disp_text, poker_hands, scoring_hand, disp_text
end

-- Hook to give extra starting asc power for declare hands
local splib_startasc_ref = Spectrallib.calculate_starting_asc_power
function Spectrallib.calculate_starting_asc_power(hand_name, hand_cards, hand_scoring_cards)
    local starting_power = splib_startasc_ref(hand_name, hand_cards, hand_scoring_cards)
    if not (
        hand_name
        and G.GAME.hands[hand_name]
        and G.GAME.hands[hand_name].declare_cards
    ) then return starting_power end

    local total_declare_cards = 0
    -- todo: annotate this to make clear wtf is happening
    for _, declare_card in pairs(G.GAME.hands[hand_name].declare_cards) do
        local how_many_fit = 0
        local suit, rank
        for _, played_card in pairs(hand_cards) do
            if not played_card.marked then
                if (
                    SMODS.has_no_rank(played_card)
                    and declare_card.rank == "rankless"
                    or played_card:get_id() == declare_card.rank
                ) then
                    rank = true
                end

                if (
                    played_card:is_suit(declare_card.suit)
                    or (declare_card.suit == "suitless" and SMODS.has_no_suit(played_card))
                    or not declare_card.suit
                ) then
                    suit = true
                end

                if not (suit and rank) then
                    suit = false
                    rank = false
                end

                if suit and rank then
                    how_many_fit = how_many_fit + 1
                    played_card.marked = true
                end
            end
        end
        if not rank or not suit then
            how_many_fit = 0
        end
        total_declare_cards = total_declare_cards + how_many_fit
    end

    -- Remove flags
    for _, played_card in pairs(hand_cards) do
        played_card.marked = nil
    end

    starting_power = starting_power + (total_declare_cards - #hand_scoring_cards)
    return starting_power
end

-- Hook to give bonus asc power from other sources
local splib_bonusasc_ref = Spectrallib.calculate_bonus_asc_power
function Spectrallib.calculate_bonus_asc_power(hand_name, hand_cards, hand_scoring_cards)
    local bonus_power = splib_bonusasc_ref(hand_name, hand_cards, hand_scoring_cards)

    -- Bonus from EXPLOIT://
    if G.GAME.cry_exploit_override then
        bonus_power = bonus_power + 1
    end

    -- Bonus from Sol/Perkele under Observatory
    if (
        G.GAME.used_vouchers.v_observatory
        and (
            next(SMODS.find_card("cry-sunplanet"))
            or next(SMODS.find_card("cry-Perkele"))
        )
    ) then
        local solperkele_count = #SMODS.find_card("cry-sunplanet") + #SMODS.find_card("cry-Perkele")
        if solperkele_count == 1 then
            bonus_power = bonus_power + 1
        else
            local solperkele_bonus = Spectrallib.funny_log(2, solperkele_count + 1)
            local solperkele_bonus_simple = Spectrallib.nuke_decimals(solperkele_bonus, 2)
            bonus_power = bonus_power + solperkele_bonus_simple
        end
    end

    return bonus_power
end

-- Ascension numbers for Cryptid hands
---@param index integer
---@return fun(): integer|nil
local function declare_check(index)
    local key = "cry_Declare" .. index
    return function ()
        return (
            G.GAME.hands[key]
            and G.GAME.hands[key].declare_cards
            and #G.GAME.hands[key].declare_cards
        )
    end
end
local ascnum = Spectrallib.ascension_numbers
ascnum["cry_Bulwark"]     = 5
ascnum["cry_Clusterfuck"] = 8
ascnum["cry_UltPair"]     = 8
ascnum["cry_WholeDeck"]   = 52
ascnum["cry_Declare0"]    = declare_check(0)
ascnum["cry_Declare1"]    = declare_check(1)
ascnum["cry_Declare2"]    = declare_check(2)



if not Spectrallib.can_mods_load({"Cryptid"}) then return end



-- Hook for contentset-activated Ascended Hands
local splib_ascenable_ref = Spectrallib.ascension_power_enabled
function Spectrallib.ascension_power_enabled()
    local ret = splib_ascenable_ref()
    if not ret then
        return Spectrallib.enabled("set_cry_poker_hand_stuff")
    end
    return ret
end