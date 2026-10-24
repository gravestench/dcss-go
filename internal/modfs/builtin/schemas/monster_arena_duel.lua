-- The current mark stays with a live Duel lineage; ordinary mirror clones
-- do not copy it. An abandoned mark records a still-living returnee.
local component = require("constants.component")

register.component({
    id = component.MONSTER_ARENA_DUEL,
    version = 1,
    fields = {
        current = {
            type = "bool",
            default = false,
        },
        abandoned = {
            type = "bool",
            default = false,
        },
        root_id = {
            type = "string",
            default = "",
        },
    },
})
