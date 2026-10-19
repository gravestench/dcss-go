-- Theory of operation: A rolling actor ages its enchantment before AI
-- chooses a spell or route; stalled movement is checked after movement.
local component = require("constants.component")
local intent_ids = require("constants.intent")
local roll = require("policy.combat.monster_roll")

local system = {}

-- Age only the active rolling actor on its own action clock.
function system.tick(ctx, actor, elapsed_aut)
    roll.tick(ctx, actor, elapsed_aut)
end

-- A WAIT after route or failed movement has no forward momentum to keep.
function system.stalled(ctx, actor)
    local intent = ctx:get(actor, component.INTENT)

    if intent and intent.kind == intent_ids.WAIT then
        roll.stalled(ctx, actor)
    end
end

register.system({
    id = "combat.monster_rolling.tick",
    scope = "active",
    query = { component.MONSTER_ROLLING },
    after = { "monster.regeneration" },
    before = { "monster.decision" },
    update = system.tick,
})

register.system({
    id = "combat.monster_rolling.stalled",
    scope = "active",
    query = { component.MONSTER_ROLLING },
    after = { "world.movement" },
    before = { "attack.combat" },
    update = system.stalled,
})

return system
