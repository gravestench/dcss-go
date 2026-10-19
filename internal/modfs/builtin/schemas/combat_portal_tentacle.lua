local ids = require("constants.monster_construct_components")

register.component({
    id = ids.PORTAL,
    version = 3,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
        pacified_aut = { type = "int64", default = 0 },
        severed = { type = "bool", default = false },
        -- The head owns BASE_POSITION after the marker leaves the world.
        anchor_x = { type = "int64", default = 0 },
        anchor_y = { type = "int64", default = 0 },
    },
})
