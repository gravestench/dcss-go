local melee = require("policy.combat.melee_actions")
local ranged = require("policy.combat.ranged_actions")
local player_projectiles = require("policy.combat.player_projectiles")

register.system({
    id = "attack.combat",
    scope = "active",
    query = {},
    after = { "world.movement" },
    before = { "status.constriction" },
    update = function(ctx, attacker)
        local intent = ctx:get(attacker, "core.intent")

        if not intent then
            return
        end

        if intent.kind == 13 then
            if attacker == ctx:player() then
                player_projectiles.resolve(ctx, attacker, intent)

                return
            end

            local actor = ctx:get(attacker, "core.actor")

            if not actor then
                error("ranged attacker has no actor")
            end

            if actor.kind_id == "MONS_GOBLIN" then
                ranged.goblin(ctx, attacker, intent)
            elseif actor.kind_id == "MONS_KOBOLD" then
                ranged.kobold(ctx, attacker, intent)
            else
                error("unsupported ranged attacker " .. actor.kind_id)
            end

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

        if attacker == ctx:player() then
            melee.player(ctx, target)
        elseif target == ctx:player() then
            melee.monster(ctx, attacker)
        else
            error("unsupported non-player melee defender")
        end
    end,
})
