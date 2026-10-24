-- Source: mon-poly.cc retains the first class for corpses. A draconian job
-- uses its colored base there, while roster validation still needs the job.
local schema = {
    id = "magic.monster_polymorph",
    version = 2,
    fields = {
        -- Spawn lineage stays as a class for population and authored vaults.
        original_kind_id = {
            type = "string",
            default = "",
        },
        -- The first corpse class may instead be a colored draconian base.
        corpse_kind_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
