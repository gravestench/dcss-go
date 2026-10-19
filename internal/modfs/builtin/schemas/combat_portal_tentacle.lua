local ids = require("constants.monster_construct_components")

register.component({
    id = ids.PORTAL,
    version = 1,
    fields = {
        marker = { type = "entity" },
        remaining_aut = { type = "int64", default = 0 },
        pacified_aut = { type = "int64", default = 0 },
        severed = { type = "bool", default = false },
    },
})
