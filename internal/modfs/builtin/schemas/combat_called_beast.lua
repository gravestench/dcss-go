local ids = require("constants.monster_construct_components")

register.component({
    id = ids.CALLED_BEAST,
    version = 1,
    fields = {
        -- The foe may die before this beast acts; its ID is not an owning link.
        target_id = { type = "int64", default = 0 },
        x = { type = "int64", default = 0 },
        y = { type = "int64", default = 0 },
    },
})
