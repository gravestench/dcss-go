-- Vehumet's temporary spell access and lifetime offer history belong to
-- the player, independently of ordinary book discoveries. Old offers remain
-- remembered after renunciation, while current access ends immediately.
local component = require("constants.component")

local schema = {
    id = component.RELIGION_VEHUMET,
    version = 1,
    fields = {
        offer_ids = {
            type = "list<string>",
        },

        old_ids = {
            type = "map<string,bool>",
        },

        -- Source DUR_VEHUMET_GIFT blocks replacement offers until elapsed.
        -- The current offers remain memorisable during that cooldown.
        cooldown_end_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
