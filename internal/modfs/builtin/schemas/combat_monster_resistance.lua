local ids = require("constants.monster_construct_components")

register.component({
    id = ids.RESISTANCE,
    version = 1,
    fields = {
        remaining_aut = { type = "int64", default = 0 },
    },
})
