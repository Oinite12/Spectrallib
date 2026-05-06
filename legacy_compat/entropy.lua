-- Hook for Axeh's effect
local splib_calcascmod_ref = Spectrallib.calculate_ascension_modification
function Spectrallib.calculate_ascension_modification(args)
    for _,axeh in ipairs(SMODS.find_card('j_entr_axeh')) do
        args.calc_args.amount = args.calc_args.amount(axeh.ability.asc_mod)
    end
    return splib_calcascmod_ref(args)
end