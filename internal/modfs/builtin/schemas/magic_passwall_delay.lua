-- Source: spl-other.cc:passwall_path and delay.cc:PasswallDelay.
local schema = {
    id = "magic.passwall_delay",
    version = 1,
    -- Destination and started aut are fixed at cast time; remaining aut resumes wall travel after restore.
    fields = {
        level_id = { type = "int64" },
        dest_x = { type = "int64" },
        dest_y = { type = "int64" },
        started_aut = { type = "int64" },
        remaining_aut = { type = "int64" },
    },
}

register.component(schema)

return schema
