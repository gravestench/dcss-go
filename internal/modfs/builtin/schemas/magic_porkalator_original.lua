-- Kirke's death restores the saved body with the hog's current HP ratio.
local schema = {
    id = "magic.porkalator_original",
    version = 1,
    fields = {
        kind_id = { type = "string", default = "" },
        speed = { type = "int64", default = 10 },
        max_hp = { type = "int64", default = 1 },
        polymorph_original_kind_id = { type = "string", default = "" },
    },
}

register.component(schema)

return schema
