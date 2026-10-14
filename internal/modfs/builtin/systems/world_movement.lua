local catalog = require("policy.catalog")
local constriction = require("policy.combat.constriction")

local function escape_grasp(ctx, actor, intent)
    local grip = ctx:get(actor, "core.constricted")

    if not grip then
        return true
    end

    local constrictor = ctx:get(grip.by, "core.actor")

    if not constrictor then
        error("constrictor " .. ctx:id(grip.by) .. " has no actor")
    end

    local definition = catalog.get("monsters", constrictor.kind_id)
    grip.escape_attempts = grip.escape_attempts + 1
    ctx:set(actor, "core.constricted", grip)

    if not constriction.escape(ctx, grip.escape_attempts, definition.hd) then
        intent.kind = 6
        ctx:set(actor, "core.intent", intent)
        ctx:emit("combat", "The " .. definition.name ..
            "'s grasp on you weakens, but your attempt to escape fails.")

        return false
    end

    ctx:remove(actor, "core.constricted")

    local energy = ctx:get(grip.by, "core.monster_energy")

    if not energy then
        error("constrictor " .. ctx:id(grip.by) .. " has no energy")
    end

    energy.points = energy.points - 5
    ctx:set(grip.by, "core.monster_energy", energy)
    ctx:emit("combat", "You escape the " .. definition.name .. "'s grasp.")

    return true
end

register.system({
    id = "world.movement",
    scope = "active",
    query = {},
    after = { "attack.spell" },
    before = { "attack.combat" },
    update = function(ctx, actor)
        local intent = ctx:get(actor, "core.intent")

        if not intent or intent.kind ~= 1 then
            return
        end

        local position = ctx:get(actor, "core.position")

        if not position then
            error("moving actor " .. ctx:id(actor) .. " has no position")
        end

        local x = position.x + intent.dx
        local y = position.y + intent.dy
        local occupied = ctx:actor_at(position.level_id, x, y)

        if occupied then
            intent.kind = 2
            ctx:set(actor, "core.intent", intent)

            return
        end

        if actor == ctx:player() and not escape_grasp(ctx, actor, intent) then
            return
        end

        ctx:move_actor(actor, position.level_id, x, y)
    end,
})
