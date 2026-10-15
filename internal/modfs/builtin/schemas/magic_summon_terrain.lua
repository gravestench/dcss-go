-- A temporary feature change is a saveable world entity, not a glyph shadow.
local schema = {
    id = "magic.summon_terrain",
    version = 1,
    fields = {
        owner = { type = "entity" },
        spell_id = { type = "string", default = "" },
        level_id = { type = "int64", default = 0 },
        x = { type = "int64", default = 0 },
        y = { type = "int64", default = 0 },
        original_feature = { type = "string", default = "" },
        changed_feature = { type = "string", default = "" },
        expires_aut = { type = "int64", default = 0 },
    },
}

register.component(schema)

return schema
