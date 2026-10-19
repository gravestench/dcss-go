local component = require("constants.component")
local intent_ids = require("constants.intent")
local vampire = require("policy.character.vampire")

local system = {}

-- Theory of operation: Only WAIT actions spend ritual progress, preventing unrelated abilities from advancing the rite.
-- Blood rituals advance only on WAIT intents, before active abilities resolve.
function system.update(ctx, player, aut)
    local intent = ctx:get(player, component.INTENT)

    if intent and intent.kind == intent_ids.WAIT then
        vampire.advance(ctx, player, aut)
    end
end

register.system({
    id = "character.vampire_ritual",
    scope = "active",
    query = { component.PLAYER, component.VAMPIRE },
    before = { "attack.player_ability" },
    update = system.update,
})

return system
