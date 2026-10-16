local component = require("constants.component")
local capabilities = require("constants.jewellery_capabilities")
local effects = require("policy.inventory.jewellery_effects")
local monster_defense = require("policy.combat.monster_defense")
local monster_health = require("policy.combat.monster_health")

local reflection = {}

-- Source: actor.cc:276-283 and ranged-attack.cc:154-193. Only a
-- successful block can reverse the current projectile toward its source.
function reflection.active(ctx, defender)
    return ctx:has(defender, component.PLAYER) and
        effects.has(ctx, defender, capabilities.REFLECTION)
end

function reflection.return_defense(ctx, shooter, definition,
    self_missile)
    local health = ctx:get(shooter, component.HEALTH)
    local origin = ctx:get(ctx:player(), component.POSITION)
    local target = ctx:get(shooter, component.POSITION)

    if not health or health.current <= 0 or not origin or not target or
        origin.level_id ~= target.level_id or
        not ctx:projectile_clear(origin.level_id, origin.x, origin.y,
            target.x, target.y) then
        return nil
    end

    local combat = ctx:get(shooter, component.COMBAT)

    if not combat then
        error("reflected projectile target has no combat state")
    end

    return {
        ev = monster_defense.evasion(ctx, shooter, definition),
        ac = monster_defense.armour(ctx, shooter, definition),
        gdr = 0,
        shield_class = 0,
        shield_blocks = combat.shield_blocks,
        monster_shield = monster_defense.shield(ctx, shooter, definition),
        skip_shield = self_missile or false,
    }
end

function reflection.begin(ctx, name)
    ctx:emit("combat", "You reflect the " .. name .. "!")
end

function reflection.return_outcome(ctx, player, shooter, definition,
    name, outcome)
    if outcome.kind == "block" then
        monster_defense.register_block(ctx, shooter)
        ctx:emit("combat", "The " .. definition.name ..
            " blocks the reflected " .. name .. ".")

        return nil
    end

    if outcome.kind ~= "hit" then
        ctx:emit("combat", "The reflected " .. name ..
            " misses the " .. definition.name .. ".")

        return nil
    end

    local health = monster_health.damage(ctx, shooter,
        outcome.damage, player)

    ctx:emit("combat", "The reflected " .. name .. " hits the " ..
        definition.name .. ".")

    if health.current == 0 then
        ctx:signal("player_kill", shooter)
    end

    return health
end

function reflection.extra_damage(ctx, player, shooter, amount)
    if amount <= 0 then
        return
    end

    local health = monster_health.damage(ctx, shooter, amount, player)

    if health.current == 0 then
        ctx:signal("player_kill", shooter)
    end
end

return reflection
