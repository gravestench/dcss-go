local ids = require("constants.monster_construct_components")

register.component({
    id = ids.DANCING_WEAPON,
    version = 1,
    fields = {
        speed = { type = "int64", default = 0 },
        ac = { type = "int64", default = 0 },
        ev = { type = "int64", default = 0 },
        damage = { type = "int64", default = 0 },
    },
})
