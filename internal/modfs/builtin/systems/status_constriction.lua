local catalog = require("policy.catalog")
local constriction = require("policy.combat.constriction")
local fighter = require("policy.combat.fighter")

local function adjacent(a, b)
    return a.level_id == b.level_id and
        math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and
        (a.x ~= b.x or a.y ~= b.y)
end

register.system({
    id = "status.constriction",
    scope = "active",
    query = {},
    after = { "attack.combat" },
    before = { "actor.death" },
    update = function(ctx, active)
        local player = ctx:player()
        local grip = ctx:get(player, "core.constricted")

        if not grip then
            return
        end

        local player_health = ctx:get(player, "core.health")
        local attacker_health = ctx:get(grip.by, "core.health")
        local player_pos = ctx:get(player, "core.position")
        local attacker_pos = ctx:get(grip.by, "core.position")

        if not player_health or not attacker_health or player_health.current <= 0 or
            attacker_health.current <= 0 or not player_pos or not attacker_pos or
            not adjacent(player_pos, attacker_pos) then
            ctx:remove(player, "core.constricted")

            return
        end

        if active ~= grip.by then
            return
        end

        local actor = ctx:get(grip.by, "core.actor")

        if not actor then
            error("constrictor has no actor")
        end

        local definition = catalog.get("monsters", actor.kind_id)
        local defense = fighter.defense(ctx)
        local amount = constriction.damage(ctx, definition.attacks[2].damage,
            defense.ac, actor.speed)
        player_health.current = math.max(0, player_health.current - amount)
        ctx:set(player, "core.health", player_health)
        ctx:emit("combat", "The " .. definition.name .. " constricts you.")

        if player_health.current == 0 then
            ctx:remove(player, "core.constricted")
        end
    end,
})
