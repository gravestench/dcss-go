-- Nemelex's card counts and uncancelled choices belong to the player.
-- Keeping sampled IDs here makes restored actions use the same cards.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_NEMELEX_DECKS,
    version = 4,
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
        -- Source rolls invocation failure before opening deck prompts.
        -- Saving the result prevents a restored choice from rerolling it.
        pending_failed = {
            type = "bool",
            default = false,
        },
        -- A targeted card's source tier is rolled before its aim prompt.
        -- Minus one means that this card has not sampled a tier yet.
        pending_tier = {
            type = "int64",
            default = -1,
        },
        -- A friendly-fire prompt is postcommit. Store its selected ray so
        -- accepting after a save cannot aim somewhere else by accident.
        pending_dx = {
            type = "int64",
            default = 0,
        },
        pending_dy = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
