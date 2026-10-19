-- Example: ctx:get(monster, zap_ids.component.NECROTISE) identifies the caster for corpse raising.
-- beam.cc:BEAM_NECROTISE applies ENCH_NECROTISE for 10 aut before death.
-- The actor.death hook consumes this mark to make a friendly skeleton.
local zap_ids = require("policy.magic.effects.zaps.ids")
local state = {}

register.component{
    id = zap_ids.component.NECROTISE,
    version = 1,
    fields = {
        source = {
            type = "entity",
        },

        expires_aut = {
            type = "int64",
            default = 0,
        },
    },
}

return state
