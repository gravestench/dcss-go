-- Source: mon-poly.cc:change_monster_type retains the original monster kind.
local schema = {
    id = "magic.monster_polymorph",
    version = 1,
    fields = {
        original_kind_id = {
            type = "string",
            default = "",
        },

    },
}

register.component(schema)

return schema
