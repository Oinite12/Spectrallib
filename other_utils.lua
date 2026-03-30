function Spectrallib.can_mods_load(...)
    local mods = {...}
    if type(mods[1]) == "table" then
        mods = mods[1]
    end
    for i, v in pairs(mods) do
        if (SMODS.Mods[v] or {}).can_load then return true end
    end
end

function Spectrallib.optional_feature(key)
    for i, v in pairs(SMODS.Mods) do
        if v.can_load and v.spectrallib_features and Spectrallib.in_table(v.spectrallib_features, key) then return true end
    end
end

--allow selecting multiple jokers/consumables. should probably go elsewhere but since this is pretty generically useful to a lot of features idk where it would go
local start_run_ref = Game.start_run
function Game:start_run(args)
    start_run_ref(self, args)
    G.consumeables.config.highlighted_limit = 99
    G.jokers.config.highlighted_limit = 99
end