-- Power retained for the stationary spire's electrical bolt.
local schema = {
    id = "magic.summon_spire",
    version = 1,
    -- The stationary spire retains cast power for every later electrical bolt.
    fields = {
        power = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
