local ids = require("constants.monster_construct_components")

register.component({
    id = ids.TENTACLE,
    version = 1,
    fields = {
        move_spurt = { type = "int64", default = 0 },
        parent = { type = "entity" },
    },
})
