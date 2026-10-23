-- An authored mutant beast keeps its source tier and facets on the actor,
-- rather than losing them when the DES expression resolves to one catalog
-- ID. Combat, display, and future beast rules read the same saved state.
local component = require("constants.component")

register.component({
    id = component.MONSTER_MUTANT_BEAST,
    version = 1,
    fields = {
        tier = {
            type = "string",
            default = "",
        },
        hit_dice = {
            type = "int64",
            default = 0,
        },
        facets = {
            type = "list<string>",
        },
    },
})
