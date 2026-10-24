-- One saved nexus anchors corruption's permanent level mark and its
-- remaining servant clock. A zero clock remains as a spent marker, so
-- the same floor cannot be corrupted a second time after reload.
local component = require("constants.component")

register.component({
    id = component.LUGONU_CORRUPTION_NEXUS,
    version = 1,
    fields = {
        level_id = {
            type = "int64",
            default = 0,
        },
        x = {
            type = "int64",
            default = 0,
        },
        y = {
            type = "int64",
            default = 0,
        },
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
})
