-- Nemelex's card counts and uncancelled choices belong to the player.
-- Keeping sampled IDs here makes restored actions use the same cards.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_NEMELEX_DECKS,
    version = 1,
    fields = {
        counts = {
            type = "map<string,int64>",
        },
        stack = {
            type = "list<string>",
        },
        pending_kind = {
            type = "string",
            default = "",
        },
        pending_phase = {
            type = "string",
            default = "",
        },
        pending_deck = {
            type = "string",
            default = "",
        },
        pending_cards = {
            type = "list<string>",
        },
        pending_target_count = {
            type = "int64",
            default = 0,
        },
        pending_selected = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
