---Levels up a given suit
---@param suit string|Suit|'suitless' The suit key to be leveled up. Can be `suitless` to level up suitless cards.
---@param card table|Card The card to play the animation on.
---@param amt? number The amount of levels to upgrade by.
---@param chips_override? number The amount of chips per level. Defaults to `10` if not set.
---@param mult? number The amount of mult per level. Defaults to `0` if not set
---@param instant? boolean If `true`, skips the animation (similar to `level_up_hand` in vanilla).
---@param display_all? boolean If `true`, parameters with a level up amount of `0` will not be displayed as `...` during the animation.
function Spectrallib.level_suit(suit, card, amt, chips_override, mult, instant, display_all)
    amt = amt or 1
    local hide = {}
    if chips_override == 0 and not hide.chips and not display_all then hide.chips = "..." end
    if (not mult or mult == 0) and not hide.mult and not display_all then hide.mult = "..." end
    local vals_after_level
    --for properly resetting to previous hand display when leveling in scoring
    if SMODS.displaying_scoring then
        vals_after_level = copy_table(G.GAME.current_round.current_hand)
        local text,disp_text,_,_,_ = G.FUNCS.get_poker_hand_info(G.play.cards)
        vals_after_level.handname = disp_text or ''
        vals_after_level.level = (G.GAME.hands[text] or {}).level or ''
        for name, p in pairs(SMODS.Scoring_Parameters) do
            vals_after_level[name] = p.current
        end
    end

    if not G.GAME.SuitBuffs then G.GAME.SuitBuffs = {} end
    if not G.GAME.SuitBuffs[suit] then
        G.GAME.SuitBuffs[suit] = {level = 1, chips = 0, mult = 0}
    end
    if not G.GAME.SuitBuffs[suit].chips then G.GAME.SuitBuffs[suit].chips = 0 end
    if not G.GAME.SuitBuffs[suit].level then G.GAME.SuitBuffs[suit].level = 1 end
    if not G.GAME.SuitBuffs[suit].mult then G.GAME.SuitBuffs[suit].mult = 0 end
    if not instant then
        update_hand_text(
        { sound = "button", volume = 0.7, pitch = 0.8, delay = 0.3 },
        { handname = localize(suit,'suits_plural'), chips = hide.chips or number_format(G.GAME.SuitBuffs[suit].chips), mult = hide.mult or number_format(G.GAME.SuitBuffs[suit].mult), level = G.GAME.SuitBuffs[suit].level }
        )
    end
    G.GAME.SuitBuffs[suit].chips = G.GAME.SuitBuffs[suit].chips + (chips_override or 10)*amt
    G.GAME.SuitBuffs[suit].mult = G.GAME.SuitBuffs[suit].mult + (mult or 0)*amt
    G.GAME.SuitBuffs[suit].level = G.GAME.SuitBuffs[suit].level + amt
    if not instant then
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                if card then card:juice_up(0.8, 0.5) end
                G.TAROT_INTERRUPT_PULSE = nil
                return true 
            end 
        }))
        if mult then update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { mult = "+"..number_format(mult*amt), StatusText = true }) end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                if card then card:juice_up(0.8, 0.5) end
                G.TAROT_INTERRUPT_PULSE = nil
                return true 
            end 
        }))
        if chips_override ~= 0 then update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { chips="+"..number_format((chips_override or 10)*amt), StatusText = true }) end
        G.E_MANAGER:add_event(Event({trigger = 'after', delay = 0.9, func = function()
                play_sound('tarot1')
                if card then card:juice_up(0.8, 0.5) end
                G.TAROT_INTERRUPT_PULSE = nil
                return true 
            end 
        }))
        update_hand_text({ sound = "button", volume = 0.7, pitch = 0.9, delay = 0 }, { level = G.GAME.SuitBuffs[suit].level, chips= not hide.chips and number_format(G.GAME.SuitBuffs[suit].chips) or nil, mult = not hide.mult and number_format(G.GAME.SuitBuffs[suit].mult) or nil })
        delay(1.3)
        update_hand_text(
        { sound = "button", volume = 0.7, pitch = 1.1, delay = 0 },
        vals_after_level or { mult = 0, chips = 0, handname = "", level = "" }
        )
    end
end

function Card:get_suit_bonus()
    local bonus = 0
    for k in pairs(SMODS.Suits) do
        if self:is_suit(k) then
            bonus = bonus + G.GAME.SuitBuffs[k].chips
        end
    end
    if Spectrallib.true_suitless(self) then
        bonus = bonus + G.GAME.SuitBuffs.suitless.chips
    end
    return bonus
end

function Card:get_suit_mult()
    local bonus = 0
    for k in pairs(SMODS.Suits) do
        if self:is_suit(k) then
            bonus = bonus + G.GAME.SuitBuffs[k].mult
        end
    end
    if Spectrallib.true_suitless(self) then
        bonus = bonus + G.GAME.SuitBuffs.suitless.mult
    end
    return bonus
end

function Card:get_suit_bonus_table()
    local t = {}
    (if not G.GAME.SuitBuffs then return t end)
    for _, v in ipairs(SMODS.Suit.obj_buffer) do
        if self:is_suit(v) and (G.GAME.SuitBuffs[v].level ~= 1 or G.GAME.SuitBuffs[v].chips ~= 0 or G.GAME.SuitBuffs[v].mult ~= 0) then
            local loc_key
            if G.GAME.SuitBuffs[v].chips == 0 and G.GAME.SuitBuffs[v].mult ~= 0 then
                loc_key = "entr_card_suit_level_mult"
            elseif G.GAME.SuitBuffs[v].mult == 0 and G.GAME.SuitBuffs[v].chips ~= 0 then
                loc_key = "entr_card_suit_level_chips"
            else
                loc_key = "entr_card_suit_level"
            end
            t[#t+1] = { level = G.GAME.SuitBuffs[v].level, chips = G.GAME.SuitBuffs[v].chips, mult = G.GAME.SuitBuffs[v].mult, key = v, loc_key = loc_key }
        end
    end
    if Spectrallib.true_suitless(self) and (G.GAME.SuitBuffs.suitless.level ~= 1 or G.GAME.SuitBuffs.suitless.chips ~= 0 or G.GAME.SuitBuffs.suitless.mult ~= 0) then
        local loc_key
        if G.GAME.SuitBuffs.suitless.chips == 0 and G.GAME.SuitBuffs.suitless.mult ~= 0 then
            loc_key = "entr_card_suit_level_mult"
        elseif G.GAME.SuitBuffs.suitless.mult == 0 and G.GAME.SuitBuffs.suitless.chips ~= 0 then
            loc_key = "entr_card_suit_level_chips"
        else
            loc_key = "entr_card_suit_level"
        end
        t[#t+1] = { level = G.GAME.SuitBuffs.suitless.level, chips = G.GAME.SuitBuffs.suitless.chips, mult = G.GAME.SuitBuffs.suitless.mult, key = "suitless", loc_key = loc_key }
    end
    return t
end

local get_chips_ref = Card.get_chip_bonus
function Card:get_chip_bonus(...)
    if self.ability.extra_enhancement then return self.ability.bonus end
    return get_chips_ref(self, ...) + self:get_suit_bonus()
end

local get_mult_ref = Card.get_chip_mult
function Card:get_chip_mult()
    return get_mult_ref(self) + self:get_suit_mult()
end

--default suit level functionality akin to `hand_type` config in vanilla
local use_ref = Card.use_consumeable
function Card:use_consumeable(area, copier)
    use_ref(self, area, copier)
    local obj = self.config.center
    if obj.use then return end
    if self.ability.consumeable.level_suit then
        Spectrallib.level_suit(self.ability.consumeable.level_suit, self, 1, self.ability.consumeable.suit_chips or 0, self.ability.consumeable.suit_mult, nil, true)
    end
end
