-- Source: mon-poly.cc:change_monster_type retains the original monster kind.
local schema = {
    id = "magic.monster_polymorph",
    version = 1,
    -- Original kind ID preserves the source monster identity across a temporary polymorph.
    fields = {
        original_kind_id = {
            type = "string",
            default = "",
        },

    },
}

register.component(schema)

return schema
