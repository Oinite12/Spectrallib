local sp_Event = Spectrallib.event

-- Redeem the deck/sleeve.
---@param e Card
---@return nil
G.FUNCS.buy_deckorsleeve = function(e)
    local deck_card = e.config.ref_table
    --deck_card:open()
    deck_card.config = deck_card.config or {}
    deck_card.config.center = deck_card.config.center or G.P_CENTERS[deck_card.center_key]

    if deck_card.area then
        deck_card.area:remove_card(deck_card)
    end

    local deck_apply = Spectrallib.safe_get(deck_card, "config", "center", "apply")
    if deck_apply then
        local orig = G.GAME.starting_params.joker_slots
        if deck_card.config.center.set == "Sleeve" then
            deck_apply(deck_card.config.center)
        else
            deck_apply(false)
        end
        local diff = G.GAME.starting_params.joker_slots - orig
        if diff > 0 then
            Spectrallib.handle_card_limit(G.jokers, diff)
        end
    end

    local deck_config = Spectrallib.safe_get(deck_card, "config", "center", "config")

    for cfg_key, cfg_value in pairs(deck_config or {}) do
        if Spectrallib.deck_config_apply_effects[cfg_key] then
            Spectrallib.deck_config_apply_effects[cfg_key](deck_card.config.center, cfg_value)
        end
    end

    if deck_config then
        if deck_card.config.center.key == "b_checkered" or deck_card.config.center.key == "sleeve_casl_checkered" then
            for _, card in pairs(G.playing_cards) do
                local new_suit
                if card:is_suit("Diamonds") then
                    new_suit = "Hearts"
                elseif card:is_suit("Clubs") then
                    new_suit = "Spades"
                elseif not (card:is_suit("Hearts") or card:is_suit("Spades")) then
                    new_suit = pseudorandom_element({"Spades", "Hearts"}, pseudoseed("checkered_redeem"))
                end
                SMODS.change_base(card, new_suit, nil)
            end
        elseif deck_card.config.center.key == "b_entr_doc" or deck_card.config.center.key == "sleeve_entr_doc" then
        end
    end

    G.GAME.entr_bought_decks = G.GAME.entr_bought_decks or {}
    table.insert(G.GAME.entr_bought_decks, deck_card.config.center.key)

    -- todo: Can we replace this with destroy_cards?
    deck_card:start_dissolve()
    if deck_card.children.price then
        deck_card.children.price:remove()
    end
    deck_card.children.price = nil
    if deck_card.children.buy_button then
        deck_card.children.buy_button:remove()
    end
    deck_card.children.buy_button = nil
    remove_nils(deck_card.children)

    SMODS.calculate_context({ pull_card = true, card = deck_card })
    --deck_card:remove()
end

-- Calculate redeemed decks
local calcctx_ref = SMODS.calculate_context
function SMODS.calculate_context(context, return_table)
    local main_ret = calcctx_ref(context, return_table)

    for _,bought_deck in pairs(G.GAME.entr_bought_decks or {}) do
        local deck_proto = G.P_CENTERS[bought_deck]
        if deck_proto.calculate then
            local ret = deck_proto.calculate(deck_proto, nil, context or {})
            for ret_key, value in pairs(ret or {}) do
                main_ret[ret_key]  = value
            end
        end
    end

    if not return_table then
        return main_ret
    end
end

local trigger_effectref = Back.trigger_effect
function Back:trigger_effect(args, ...)
    local chips, mult = trigger_effectref(self, args, ...)
    if not G.GAME.entr_bought_decks then return chips, mult end

    for _, deck_key in pairs(G.GAME.entr_bought_decks or {}) do
        if (
            deck_key == 'b_anaglyph'
            and args.context == 'eval'
            and G.GAME.last_blind
            and G.GAME.last_blind.boss
        ) then
            sp_Event(function ()
                add_tag(Tag('tag_double'))
                play_sound('generic1', 0.9 + math.random()*0.1, 0.8)
                play_sound('holo1', 1.2 + math.random()*0.1, 0.4)
                return true
            end)
        end
        if deck_key == "b_plasma" and args.context == 'final_scoring_step' then
            chips = chips or args.chips; mult = mult or args.mult
            local total = chips + mult
            chips = math.floor(total/2); mult = math.floor(total/2)
            update_hand_text({delay = 0}, {mult = mult, chips = chips})

            sp_Event{ function ()
                local text = localize('k_balanced')
                play_sound('gong', 0.94, 0.3)
                play_sound('gong', 0.94*1.5, 0.2)
                play_sound('tarot1', 1.5)
                ease_colour(G.C.UI_CHIPS, {0.8, 0.45, 0.85, 1})
                ease_colour(G.C.UI_MULT, {0.8, 0.45, 0.85, 1})
                attention_text({
                    scale = 1.4, text = text, hold = 2, align = 'cm', offset = {x = 0,y = -2.7},major = G.play
                })
                sp_Event {
                    function ()
                        ease_colour(G.C.UI_CHIPS, G.C.BLUE, 2)
                        ease_colour(G.C.UI_MULT, G.C.RED, 2)
                        return true
                    end,
                    delay = 4.3,
                    trigger = 'after',
                    blockable = false,
                    blocking = false,
                }
                sp_Event{
                    function ()
                        G.C.UI_CHIPS = SMODS.shallow_copy(G.C.BLUE)
                        G.C.UI_MULT = SMODS.shallow_copy(G.C.RED)
                        return true
                    end,
                    delay = 6.3,
                    trigger = 'after',
                    blockable = false,
                    blocking = false,
                    no_delete = true,
                }
                return true
            end}
        end
    end

    return chips, mult
end

-- Redeem a deck, if the card is a deck/sleeve.
---@return nil
function Card:redeem_deck()
    if not (
        self.ability.set == "Back"
        or self.ability.set == "Sleeve"
    ) then return end

    G.GAME.current_round.voucher.spawn[self.config.center_key] = nil
    local prev_state = G.STATE

    stop_use()
    if not self.config.center.discovered then
        discover_card(self.config.center)
    end

    Spectrallib.redeem_animation(self, {
        during_func = function ()
            if self.cost ~= 0 then
                ease_dollars(-self.cost)
                inc_career_stat('c_shop_dollars_spent', self.cost)
            end
        end
    })

    local function nuke_ui(key)
        if not self.children[key] then return end
        self.children[key]:remove()
        self.children[key] = nil
    end
    nuke_ui("use_button")
    nuke_ui("sell_button")
    nuke_ui("price")

    local in_pack = (
        G.STATE ~= G.STATES.SHOP
        and (
            G.STATE == G.STATES.SMODS_BOOSTER_OPENED
            or (G.GAME.pack_choices or -1) > 0
        )
    )
    local function offset_reset(tbl)
        if not tbl then return end
        local offset = tbl.alignment.offset
        offset.y, offset.py = offset.py, nil
    end
    sp_Event{
        function ()
            G.FUNCS.buy_deckorsleeve{ config = { ref_table = self} }
            if G.booster_pack then
                sp_Event{
                    function ()
                        if (G.GAME.pack_choices or -1) >= 1 then
                            offset_reset(G.booster_pack)
                        else
                            offset_reset(G.shop)
                        end
                        return true
                    end,
                    trigger = 'after',
                    delay = 0.5
                }
            elseif not in_pack then
                offset_reset(G.shop)
                offset_reset(G.blind_select)
                offset_reset(G.round_eval)
            end
            return true
        end,
        trigger = 'after',
        delay = 0.5
    }

    local function offset_move(tbl, room_relative)
        if not tbl or tbl.alignment.offset.py then return end
        local offset = tbl.alignment.offset
        offset.py, offset.y = offset.y, (G.ROOM.T.Y + room_relative)
    end
    if in_pack then
        G.GAME.pack_choices = G.GAME.pack_choices - 1
        if G.GAME.pack_choices <= 0 then
            G.CONTROLLER.interrupt.focus = true
            if prev_state == G.STATES.SMODS.BOOSTER_OPENED then
                if booster_obj.name:find('Arcana') then
                    inc_career_stat('c_tarot_reading_used', 1)
                elseif booster_obj.name:find('Celestial') then
                    inc_career_stat('c_planetarium_used', 1)
                end
            end
            G.FUNCS.end_consumeable()
        elseif G.GAME.pack_choices <= 1 then
            offset_move(G.booster_pack, 29)
        end
    else
        offset_move(G.shop, 29)
        offset_move(G.blind_select, 39)
        offset_move(G.round_eval, 29)
    end
end
