-- Source: player attributes ATTR_EVOL_XP and EVOLUTION_MUTS_KEY, plus the
-- periodic _evolve timer in timed-effects.cc.
local schema = {
    id = "character.evolution",
    version = 1,
    fields = {
        mutation_id = { type = "string", default = "" },
        remaining_xp = { type = "int64", default = 0 },
        mutations_gained = { type = "int64", default = 0 },
        elapsed_aut = { type = "int64", default = 0 },
        next_check_aut = { type = "int64", default = 200 },
    },
}

register.component(schema)

return schema
