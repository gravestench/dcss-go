-- Source: player.cc durations and mon-ench.cc enchantments created by
-- targeted monster hexes. One actor state owns the related expiry clocks.
local component = require("constants.component")

local schema = {
    id = component.HEX_STATUS,
    version = 1,
    fields = {
        corona_aut = {
            type = "int64",
            default = 0,
        },

        anchor_aut = {
            type = "int64",
            default = 0,
        },

        poison_vuln_aut = {
            type = "int64",
            default = 0,
        },

        sap_aut = {
            type = "int64",
            default = 0,
        },

        no_cast_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
