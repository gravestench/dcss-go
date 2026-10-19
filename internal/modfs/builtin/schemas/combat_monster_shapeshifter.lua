-- The original species and rate survive every borrowed body. A natural
-- shapeshifter and a Chaos-created one use exactly the same ongoing rule.
local component = require("constants.component")
local monsters = require("ids.monsters")

local schema = {
    id = component.MONSTER_SHAPESHIFTER,
    version = 1,
    fields = {
        variant_id = {
            type = "string",
            default = monsters.MONS_SHAPESHIFTER,
        },
        original_kind_id = {
            type = "string",
            default = "",
        },
    },
}

register.component(schema)

return schema
