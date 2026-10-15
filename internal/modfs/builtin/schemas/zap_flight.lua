-- spl-vortex.cc gives the caster 60 aut of flight and refreshes victims.
local component = require("constants.component")

local flight = {}

register.component{
    id = component.ZAP_FLIGHT,
    version = 1,
    fields = {
        remaining_aut = {
            type = "int64",
            default = 0,
        },
    },
}

return flight
