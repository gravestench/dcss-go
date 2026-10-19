local component = require("constants.component")
local liquefaction = require("policy.magic.effects.translocation.liquefaction")

local system = {}

-- Theory of operation: One pass rewrites fumbled intents before movement; another ages liquefaction after actions.
-- Liquefaction can turn a chosen move into a fumble before movement commits it.
function system.update_liquefaction_fumble(ctx, actor)
    if actor == ctx:player() or
        not liquefaction.floundering(ctx, actor) then
        return
    end

    local intent = ctx:get(actor, component.INTENT)

    -- Source: monster.cc, a grounded floundering monster fumbles
    -- one quarter of its melee attacks.
    if intent and intent.kind == 2 and ctx:random("melee", 4) == 0 then
        intent.kind = 6
        ctx:set(actor, component.INTENT, intent)
        ctx:emit("combat", "The monster flounders in the liquefied ground.")
    end
end

register.system({
    id = "magic.liquefaction.fumble",
    scope = "active",
    query = {},
    after = { "monster.decision" },
    before = { "world.movement" },
    update = system.update_liquefaction_fumble,
})

-- Age liquefied terrain after actions so a fumble is still charged to the current turn.
function system.update_liquefaction_tick(ctx, actor, aut)
    if actor == ctx:player() then
        liquefaction.tick(ctx, actor, aut)
    end
end

register.system({
    id = "magic.liquefaction.tick",
    scope = "active",
    query = {},
    after = { "attack.player_spell" },
    before = { "status.duration" },
    update = system.update_liquefaction_tick,
})

return system
