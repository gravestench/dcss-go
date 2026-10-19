local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local defense = require("policy.combat.monster_defense")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local trajectory = require("policy.combat.trajectory")
local targets = require("policy.ai.targets")
local monster_health = require("policy.combat.monster_health")

local sphere = {}

-- The owner may have one active sphere; recasting recharges that entity.
local function active(ctx, player)
    for _, entity in ipairs(ctx:query({
        component.SUMMON,
        component.SUMMON_BATTLESPHERE,
    })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == player then
            return entity
        end
    end

    return nil
end

-- Roll the sphere's nominal life in aut, then cap it so repeated casts cannot extend it without bound.
local function duration(ctx, power)
    local rolled = 7 + 1 + summons.roll(ctx, math.max(1, power)) +
        1 + summons.roll(ctx, math.max(1, power))

    return math.min(rolled * 10, 500)
end

-- Keep charge rolls tied to spell power while leaving at least four shots at low power.
local function charge(ctx, power)
    return 4 + math.floor(summons.roll(ctx, power + 10) / 10)
end

-- Pick the nearest visible hostile with a clear projectile path so a blocked
-- shot does not spend charge on a farther actor.
local function target(ctx, entity, origin)
    local closest = math.huge
    local chosen = nil

    for _, hostile in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if targets.enemy(ctx, entity, hostile) then
            local position = ctx:get(hostile, component.POSITION)
            local health = ctx:get(hostile, component.HEALTH)
            local range = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and health.current > 0 and
                range <= 7 and range < closest and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    7, position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                chosen = hostile
                closest = range
            end
        end
    end

    return chosen
end

-- Example: sphere.fire(ctx, player) after a player spell spends one charge
-- only if its traced ray still contacts the selected hostile.
function sphere.fire(ctx, player)
    local entity = active(ctx, player)

    if not entity then
        return
    end

    local state = ctx:get(entity, component.SUMMON_BATTLESPHERE)

    if state.charge <= 0 then
        return
    end

    local origin = ctx:get(entity, component.POSITION)
    local hostile = target(ctx, entity, origin)

    if not hostile then
        return
    end

    local destination = ctx:get(hostile, component.POSITION)
    local impact = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, destination.x, destination.y, 7)
    local contact = impact.contacts[1]

    if not contact or contact.actor ~= hostile then
        return
    end

    local health = ctx:get(hostile, component.HEALTH)
    local hd = 1 + math.floor(state.power / 11)
    local sides = 5 + hd
    local damage = 2 + summons.roll(ctx, sides) + summons.roll(ctx, sides)
    local definition = catalog.get("monsters",
        ctx:get(hostile, component.ACTOR).kind_id)

    local ac = defense.armour(ctx, hostile, definition)
    damage = math.max(0, damage - summons.roll(ctx, ac + 1))
    health = monster_health.damage(ctx, hostile, damage, entity)

    if health.current == 0 then
        ctx:signal("player_kill", hostile)
    end

    state.charge = state.charge - 1
    ctx:set(entity, component.SUMMON_BATTLESPHERE, state)
    ctx:emit("combat", "Your battlesphere fires at the " .. definition.name .. ".")

    if state.charge == 0 then
        summons.expire(ctx, entity)
    end
end

-- Source: spl-summoning.cc:cast_battlesphere and
-- battlesphere_damage (2d(5 + HD)).
-- Recast caps both charge and remaining lifetime, preventing indefinite
-- accumulation while preserving an existing sphere's ECS identity.
function sphere.resolve(ctx, player, _, _, power)
    local existing = active(ctx, player)

    if existing then
        local state = ctx:get(existing, component.SUMMON_BATTLESPHERE)
        local summon = ctx:get(existing, component.SUMMON)
        local remaining = math.max(0, summon.expires_aut - ctx:aut())

        state.charge = math.min(20, state.charge + charge(ctx, power))
        state.power = power
        summon.expires_aut = ctx:aut() + math.min(500,
            remaining + duration(ctx, power))
        ctx:set(existing, component.SUMMON_BATTLESPHERE, state)
        ctx:set(existing, component.SUMMON, summon)
        ctx:emit("spell", "You imbue your battlesphere with additional charge.")

        return
    end

    local creature = summons.spawn(ctx, player,
        spells.SPELL_BATTLESPHERE, monsters.MONS_BATTLESPHERE, 0, 1, {
            expires_aut = ctx:aut() + duration(ctx, power),
        })

    if creature then
        ctx:add(creature, component.SUMMON_BATTLESPHERE, {
            power = power,
            charge = charge(ctx, power),
        })
        ctx:emit("spell", "You conjure a globe of magical energy.")
    end
end

registry.add(spells.SPELL_BATTLESPHERE, {
    resolve = sphere.resolve,
})

return sphere
