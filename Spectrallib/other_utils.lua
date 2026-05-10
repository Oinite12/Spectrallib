---@param ... string|string[]
---@return true|nil
function Spectrallib.can_mods_load(...)
    local mods = {...}
    if type(mods[1]) == "table" then
        mods = mods[1]
    end
    for _,mod_key in pairs(mods --[[@as string[] ]]) do
        if (SMODS.Mods[mod_key] or {}).can_load then return true end
    end
end

---@param key string
---@return true|nil
function Spectrallib.optional_feature(key)
    for _,mod in pairs(SMODS.Mods) do
        if (
            mod.can_load
            and mod.spectrallib_features
            and Spectrallib.in_table(mod.spectrallib_features, key)
        ) then return true end
    end
end

function Spectrallib.mod_score(amt) --good version
    G.SCORE_DISPLAY_QUEUE = G.SCORE_DISPLAY_QUEUE or {}
    local old = G.GAME.chips
    table.insert(G.SCORE_DISPLAY_QUEUE, old)
    G.GAME.chips = amt
end

function Spectrallib.mod_blindsize(amt) --good version
    G.BLIND_SIZE_DISPLAY_QUEUE = G.BLIND_SIZE_DISPLAY_QUEUE or {}
    table.insert(G.BLIND_SIZE_DISPLAY_QUEUE,amt)
    G.GAME.blind.chips = amt
end

---@class Spectrallib.redeem_animation.cfg
---@field colour? [number, number, number, number] Text colour. Defaults to white.
---@field scale? number Text scale. Defaults to 0.9.
---@field sounds? string[] The keys of sounds to play during the animation. Defaults to `{'card1', 'coin1'}`.
---@field top_txt? string|any Text to display at the top. Defaults to `card`'s name.
---@field btm_txt? string|any Text to display at the bottom. Defaults to the localization of "Redemed!"
---@field during_func? function A function to run after displaying text, but before removing it.

-- Play the voucher redeem animation, with customization options.
---@param card Card
---@param cfg Spectrallib.redeem_animation.cfg
---@return nil
function Spectrallib.redeem_animation(card, cfg)
    cfg.colour = cfg.colour or G.C.WHITE
    cfg.scale  = cfg.scale or 0.9
    cfg.sounds = cfg.sounds or {'card1', 'coin1'}
    cfg.top_txt = cfg.top_txt or localize({
        type = 'name_text',
        set = card.config.center.set,
        key = card.config.center.key
    })
    cfg.btm_txt = localize('k_redeemed_ex')

    local function redeem_dynatext(args)
        return DynaText {
            colours = { cfg.colour }, scale = cfg.scale,
            shadow = true, bump = true, float = true,

            string = args.string,
            rotate = args.rotate,
            pop_in = args.pop_in / G.SPEEDFACTOR,
            pop_in_rate = 1.5 * G.SPEEDFACTOR,
            pitch_shift = args.pitch_shift
        }
    end
    local function redeem_uibox(pos, dynatext)
        return UIBox({
            definition =
            {n=G.UIT.ROOT, config={ align="tm", r=0.15, colour=G.C.CLEAR, padding=0.15 }, nodes={
                {n=G.UIT.O, config={ object=dynatext } },
            }},
            config = {
                align = pos,
                offset = {x=0, y=0},
                parent = card
            },
        })
    end

    card.states.hover.can = false
    local top_dynatext, btm_dynatext

    Spectrallib.event{
        function ()
            top_dynatext = redeem_dynatext{
                string = cfg.top_txt,
                rotate = 1, pop_in = 0.6
            }
            btm_dynatext = redeem_dynatext{
                string = cfg.btm_txt,
                rotate = 2, pop_in = 1.4,
                pitch_shift = 0.25,
            }

            card:juice_up(0.3, 0.5)
            for _,sound_key in ipairs(cfg.sounds) do
                play_sound(sound_key)
            end

            card.children.top_disp = redeem_uibox("tm", top_dynatext)
            card.children.bot_disp = redeem_uibox("bm", btm_dynatext)

            return true
        end,
        trigger = 'after',
        delay = 0.4,
    }

    if cfg.during_func then cfg.during_func() end

    Spectrallib.event(0.6)
    Spectrallib.event{
        function ()
            top_dynatext:pop_out(4)
            btm_dynatext:pop_out(4)
            return true
        end,
        trigger = 'after',
        delay = 2.6
    }
    Spectrallib.event{
        function ()
            card.children.top_disp:remove()
            card.children.top_disp = nil
            card.children.bot_disp:remove()
            card.children.bot_disp = nil
            return true
        end,
        trigger = 'after',
        delay = 0.5
    }
end

--allow selecting multiple jokers/consumables. should probably go elsewhere but since this is pretty generically useful to a lot of features idk where it would go
local start_run_ref = Game.start_run
function Game:start_run(args)
    start_run_ref(self, args)
    G.consumeables.config.highlighted_limit = 99
    G.jokers.config.highlighted_limit = 99
end