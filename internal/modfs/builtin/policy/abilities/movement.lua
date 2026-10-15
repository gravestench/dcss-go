local catalog = require("policy.catalog")
local component = require("constants.component")
local constriction = require("policy.combat.constriction")

local movement = {}

-- Source: player-act.cc:attempt_escape. A movement ability spends its action
-- even when the constrictor keeps its grip.
function movement.escape_grasp(ctx, player, attempts)
    local grip = ctx:get(player, component.CONSTRICTION)

    if not grip then
        return true
    end

    local actor = ctx:get(grip.by, component.ACTOR)

    if not actor then
        error("movement ability constrictor has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    grip.escape_attempts = grip.escape_attempts + attempts
    ctx:set(player, component.CONSTRICTION, grip)

    if not constriction.escape(ctx, grip.escape_attempts, definition.hd) then
        ctx:emit("mutation", "You cannot escape the " ..
            definition.name .. "'s grasp.")
        return false
    end

    ctx:remove(player, component.CONSTRICTION)

    local energy = ctx:get(grip.by, component.MONSTER_ENERGY)

    if energy then
        energy.points = energy.points - 5
        ctx:set(grip.by, component.MONSTER_ENERGY, energy)
    end

    ctx:emit("mutation", "You escape the " .. definition.name ..
        "'s grasp.")

    return true
end

return movement
