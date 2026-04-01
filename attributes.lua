local attributes = {
    "echips", "emult", "hyperchips", "hypermult",
    "eqchips", "eqmult", "asc", "xasc", "easc", "hyperasc",
    "forcetrigger", "value_manip"
}

for _, v in ipairs(attributes) do
    SMODS.Attribute { key = v }
end