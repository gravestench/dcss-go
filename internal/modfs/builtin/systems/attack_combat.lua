local melee = require("policy.combat.melee_actions")
local ranged = require("policy.combat.ranged_actions")
local player_projectiles = require("policy.combat.player_projectiles")
local roll = require("policy.combat.monster_roll")
local reach = require("policy.combat.monster_reach")

local system = {}

-- Theory of operation: The intent gate dispatches ranged and melee attacks against positions fixed by movement.
-- Ranged intent 13 and melee intent 2 split here; movement has already resolved target positions.
function system.update(ctx, attacker)
    local intent = ctx:get(attacker, "core.intent")

    if not intent then
        return
    end

    if intent.kind == 13 then
        if attacker == ctx:player() then
            player_projectiles.resolve(ctx, attacker, intent)

            return
        end

        ranged.monster(ctx, attacker, intent)

        return
    end

    if intent.kind ~= 2 then
        return
    end

    local position = ctx:get(attacker, "core.position")

    if not position then
        error("melee attacker has no position")
    end

    local target = ctx:actor_at(position.level_id,
        position.x + intent.dx, position.y + intent.dy)

    if not target or target == attacker then
        error("melee attacker has no target")
    end

    -- Distant intents need a live reaching body and clear middle cell at
    -- execution time. Adjacent contacts keep their ordinary route.
    if math.max(math.abs(intent.dx), math.abs(intent.dy)) > 1 and
        (attacker == ctx:player() or
            not reach.can(ctx, attacker, position,
                ctx:get(target, "core.position"))) then
        return
    end

    if attacker == ctx:player() then
        melee.player(ctx, target)
    elseif target == ctx:player() then
        melee.monster(ctx, attacker)
    else
        melee.monster_target(ctx, attacker, target)
    end

    -- Source melee always removes ENCH_ROLLING after contact, including a
    -- miss or shield block. The attack used the doubled damage above.
    if attacker ~= ctx:player() then
        roll.finish_attack(ctx, attacker)
    end
end

register.system({
    id = "attack.combat",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "status.constriction" },
    update = system.update,
})

return system
