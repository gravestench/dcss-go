-- Ru's sacrifice timer and candidates survive floor travel and restoration.
-- A later sacrifice owner can resolve an offer without repeating join rules.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_RU,
    version = 1,
    fields = {
        sacrifice_progress = {
            type = "int64",
            default = 0,
        },
        sacrifice_delay = {
            type = "int64",
            default = 50,
        },
        sacrifice_penalty = {
            type = "int64",
            default = 0,
        },
        available = {
            type = "list<int64>",
        },
        health = {
            type = "list<int64>",
        },
        essence = {
            type = "list<int64>",
        },
        purity = {
            type = "list<int64>",
        },
        arcana = {
            type = "list<int64>",
        },
    },
}

register.component(schema)

return schema
