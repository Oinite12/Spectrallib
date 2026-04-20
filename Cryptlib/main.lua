Spectrallib.aliases = {}
Spectrallib.pointerblist = {}
Spectrallib.pointerblistrarity = {}
Spectrallib.mod_gameset_whitelist = {}
Spectrallib.mod_whitelist = {}
Spectrallib.ascension_numbers = {}
Spectrallib.rarity_table = {

}
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

-- Forcetrigger results for Vanilla Jokers
---@type { [string]: fun(card: Card, context: table): table|nil }
Spectrallib.vanilla_forcetrigger_results = {
    --#region Page 1
    ["Joker"] = function (card, context)
        return { mult = card.ability.mult }
    end,
    ["Greedy Joker"] = function (card, context)
        return { mult = card.ability.extra.s_mult }
    end,
    ["Lusty Joker"] = function (card, context)
        return { mult = card.ability.extra.s_mult }
    end,
    ["Wrathful Joker"] = function (card, context)
        return { mult = card.ability.extra.s_mult }
    end,
    ["Gluttonous Joker"] = function (card, context)
        return { mult = card.ability.extra.s_mult }
    end,
    ["Jolly Joker"] = function (card, context)
        return { mult = card.ability.t_mult }
    end,
    ["Zany Joker"] = function (card, context)
        return { mult = card.ability.t_mult }
    end,
    ["Mad Joker"] = function (card, context)
        return { mult = card.ability.t_mult }
    end,
    ["Crazy Joker"] = function (card, context)
        return { mult = card.ability.t_mult }
    end,
    ["Droll Joker"] = function (card, context)
        return { mult = card.ability.t_mult }
    end,
    ["Sly Joker"] = function (card, context)
        return { chips = card.ability.t_chips }
    end,
    ["Wily Joker"] = function (card, context)
        return { chips = card.ability.t_chips }
    end,
    ["Clever Joker"] = function (card, context)
        return { chips = card.ability.t_chips }
    end,
    ["Devious Joker"] = function (card, context)
        return { chips = card.ability.t_chips }
    end,
    ["Crafty Joker"] = function (card, context)
        return { chips = card.ability.t_chips }
    end,
    --#endregion
    --#region Page 2
    ["Half Joker"] = function (card, context)
        return { mult = card.ability.extra.mult }
    end,
    ["Joker Stencil"] = function (card, context)
        return { xmult = card.ability.x_mult }
    end,
    -- Four Fingers
    -- Mime
    -- Credit Card
    ["Ceremonial Dagger"] = function (card, context)
        local my_pos = card.rank
        local sliced_card = G.jokers.cards[my_pos + 1]
        if (
            not card.getting_sliced
            and sliced_card
            and not sliced_card.ability.eternal
            and not sliced_card.getting_sliced
        ) then
            sliced_card.getting_sliced = true
            G.GAME.joker_buffer = G.GAME.joker_buffer - 1
            G.E_MANAGER:add_event(Event({
                func = function ()
                    G.GAME.joker_buffer = 0
                    card.ability.mult = card.ability.mult + sliced_card.sell_cost * 2
                    card:juice_up(0.8, 0.8)
                    sliced_card:start_dissolve({ HEX("57ecab") }, nil, 1.6)
                    play_sound("slice1", 0.96 + math.random() * 0.08)
                    return true
                end
            }))
        end
        return { mut = card.ability.mult }
    end,
    ["Banner"] = function (card, context)
        return { chips = card.ability.extra }
    end,
    ["Mystic Summit"] = function (card, context)
        return { mult = card.ability.extra.mult }
    end,
    ["Marble Joker"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                SMODS.add_card({
                    set = "Base",
                    enhancement = "m_stone",
                    area = G.deck,
                    key_append = 'marb_fr'
                })
                return true
            end,
        }))
    end,
    ["Loyalty Card"] = function (card, context)
        return { xmult = card.ability.extra.Xmult }
    end,
    ["8 Ball"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                SMODS.add_card({
                    set = "Tarot",
                    key_append = '8ba'
                })
                return true
            end,
        }))
    end,
    ["Misprint"] = function (card, context)
        return { mult = card.ability.extra.max }
    end,
    -- Dusk
    ["Raised Fist"] = function (card, context)
        return { mult = 22 }
    end,
    -- Chaos the Clown
    --#endregion
    --#region Page 3
    ["Fibonacci"] = function (card, context)
        return { mult = card.ability.extra }
    end,
    ["Steel Joker"] = function (card, context)
        return { xmult = card.ability.extra + 1 }
    end,
    ["Scary Face"] = function (card, context)
        return { chips = card.ability.extra }
    end,
    ["Abstract Joker"] = function (card, context)
        return { mult = card.ability.extra }
    end,
    ["Delayed Gratification"] = function (card, context)
        return { dollars = card.ability.extra }
    end,
    -- Hack
    -- Pareidolia
    ["Gros Michel"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            func = function()
                SMODS.destroy_cards(card, nil, nil, true)
                return true
            end,
        }))
        G.GAME.pool_flags.gros_michel_extinct = true
        return { mult = card.ability.extra.mult }
    end,
    ["Even Steven"] = function (card, context)
        return { mult = card.ability.extra }
    end,
    ["Odd Todd"] = function (card, context)
        return { chips = card.ability.extra }
    end,
    ["Scholar"] = function (card, context)
        return {
            chips = card.ability.extra.chips,
            mult = card.ability.extra.mult
        }
    end,
    ["Business Card"] = function (card, context)
        -- todo: figure out why not return dollars
        ease_dollars(2)
    end,
    ["Supernova"] = function (card, context)
        local hand = (
            context.other_context
            and context.other_context.scoring_name
            or context.scoring_name
        )
        if hand then
            return { mult = G.GAME.hands[hand].played }
        end
    end,
    ["Ride the Bus"] = function (card, context)
        card.ability.mult = card.ability.mult + card.ability.extra
        return { mult = card.ability.mult }
    end,
    ["Space Joker"] = function (card, context)
        if #G.hand.highlighted > 0 then
            local text, disp_text = G.FUNCS.get_poker_hand_info(G.hand.highlighted)
            update_hand_text({ sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 }, {
                handname = localize(text, "poker_hands"),
                chips = G.GAME.hands[text].chips,
                mult = G.GAME.hands[text].mult,
                level = G.GAME.hands[text].level,
            })
            level_up_hand(card, text, nil, 1)
            update_hand_text(
                { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
                { mult = 0, chips = 0, handname = "", level = "" }
            )
        elseif context.scoring_name then
            level_up_hand(card, context.scoring_name)
        end
    end,
    --#endregion
    --#region Page 4
    ["Egg"] = function (card, context)
        card.ability.extra_value = card.ability.extra_value + card.ability.extra
        card:set_cost()
    end,
    ["Burglar"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            func = function()
                ease_discard(-G.GAME.current_round.discards_left, nil, true)
                ease_hands_played(card.ability.extra)
                return true
            end,
        }))
    end,
    ["Blackboard"] = function (card, context)
        return { xmult = card.ability.extra }
    end,
    ["Runner"] = function (card, context)
			card.ability.extra.chips = card.ability.extra.chips + card.ability.extra.chip_mod
            return { chips = card.ability.extra.chips }
    end,
    ["Ice Cream"] = function (card, context)
        card.ability.extra.chips = card.ability.extra.chips - card.ability.extra.chip_mod
        -- Had to switch conditional and return; not sure if that results in anything big
        if card.ability.extra.chips - card.ability.extra.chip_mod <= 0 then
            G.E_MANAGER:add_event(Event({
                trigger = "after",
                delay = 0.4,
                func = function()
                    SMODS.destroy_cards(card, nil, nil, true)
                    return true
                end,
            }))
        end
        return { chips = card.ability.extra.chips }
    end,
    ["DNA"] = function (card, context)
        G.playing_card = (G.playing_card and G.playing_card + 1) or 1
        local _card = copy_card(context.full_hand[1], nil, nil, G.playing_card)
        _card:add_to_deck()
        G.deck.config.card_limit = G.deck.config.card_limit + 1
        table.insert(G.playing_cards, _card)
        G.hand:emplace(_card)
        _card.states.visible = nil

        G.E_MANAGER:add_event(Event({
            func = function()
                _card:start_materialize()
                return true
            end,
        }))
    end,
    -- Splash
    ["Blue Joker"] = function (card, context)
        return { chips = card.ability.extra }
    end,
    ["Sixth Sense"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                SMODS.add_card({
                    set = "Spectral",
                    key_append = "sixth"
                })
                return true
            end,
        }))
    end,
    ["Constellation"] = function (card, context)
			card.ability.x_mult = card.ability.x_mult + card.ability.extra
            return { xmult = card.ability.x_mult }
    end,
    -- Hiker
    ["Faceless Joker"] = function (card, context)
        -- todo: figure out why ease_dollars, not return dollars
        ease_dollars(card.ability.extra.dollars)
    end,
    ["Green Joker"] = function (card, context)
        return { mult = card.ability.mult }
    end,
    ["Superposition"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            trigger = "after",
            delay = 0.4,
            func = function()
                SMODS.add_card({
                    set = "Tarot",
                    key_append = "sup"
                })
                return true
            end,
        }))
    end,
    ["To Do List"] = function (card, context)
        -- todo: figure out why ease_dollars, not return dollar
        ease_dollars(card.ability.extra.dollars)
    end,
    --#endregion
    --#region Page 5
    ["Cavendish"] = function (card, context)
        G.E_MANAGER:add_event(Event({
            func = function()
                SMODS.destroy_cards(card, nil, nil, true)
                return true
            end,
        }))
        return { xmult = card.ability.extra.Xmult }
    end,
    ["Card Sharp"] = function (card, context)
        return { xmult = card.ability.extra.Xmult }
    end,
    ["Red Card"] = function (card, context)
        card.ability.mult = card.ability.mult + card.ability.extra
        return { mult = card.ability.mult }
    end,
    ["Madness"] = function (card, context)
        card.ability.x_mult = card.ability.x_mult + card.ability.extra
        local destructable_jokers = {}
        for i = 1, #G.jokers.cards do
            if
                G.jokers.cards[i] ~= card
                and not G.jokers.cards[i].ability.eternal
                and not G.jokers.cards[i].getting_sliced
            then
                destructable_jokers[#destructable_jokers + 1] = G.jokers.cards[i]
            end
        end
        local joker_to_destroy = #destructable_jokers > 0
                and pseudorandom_element(destructable_jokers, pseudoseed("madness"))
            or nil

        if joker_to_destroy and not card.getting_sliced then
            joker_to_destroy.getting_sliced = true
            G.E_MANAGER:add_event(Event({
                func = function()
                    card:juice_up(0.8, 0.8)
                    joker_to_destroy:start_dissolve({ G.C.RED }, nil, 1.6)
                    return true
                end,
            }))
        end
        results = { jokers = { xmult = card.ability.x_mult, card = card } }
    end
    --#endregion
}