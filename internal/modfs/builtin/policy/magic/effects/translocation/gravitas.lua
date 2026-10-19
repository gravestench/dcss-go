local spells = require("ids.spells")
local component = require("constants.component")
local common = require("policy.magic.effects.translocation.common")
local habitat = require("policy.combat.monster_habitat")
local defense = require("policy.combat.monster_defense")
local net = require("policy.combat.net")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

-- Pull nearer monsters first so occupied cells become blockers in a deterministic order.
local function closer_to_caster(left, right)
    return left.caster_distance < right.caster_distance
end

-- Gravitas resolves damage when pulled monsters collide instead of stacking occupants.
local function collision(ctx, monster, other, power)
    local sides = 1 + math.floor(power / 10)
    local amount = 2 + ctx:random("spell", sides) +
        ctx:random("spell", sides)
    local armour = defense.armour(ctx, monster.entity,
        monster.definition)
    local damage = math.max(0, amount - ctx:random("spell", armour + 1))
    common.hit(ctx, monster.entity, damage)

    if other and other ~= ctx:player() then
        local health = ctx:get(other, component.HEALTH)

        if health and health.current > 0 then
            common.hit(ctx, other, amount)
        end
    end

    ctx:emit("spell", "The " .. monster.definition.name ..
        " slams into something!")
end

-- Pull each monster toward the target cell one step at a time, stopping at an
-- occupant and resolving collision damage instead of stacking actors.
local function attract(ctx, monster, center, power)
    local distance = common.distance(monster.position, center)
    local strength = math.floor(((power + 100) / 20) /
        (distance * distance))
    local ray = trajectory.to_target(ctx, center.level_id,
        monster.position.x, monster.position.y, center.x, center.y,
        distance)

    if #ray.path == 0 then
        collision(ctx, monster, nil, power)
        return
    end

    for index = 1, strength do
        local cell = ray.path[index]

        if not cell then
            if ray.blocked then
                collision(ctx, monster, nil, power)
            end
            break
        end

        local occupied = ctx:actor_at(center.level_id, cell.x, cell.y)

        if occupied and occupied ~= monster.entity then
            collision(ctx, monster, occupied, power)
            break
        end

        if not habitat.at(ctx, monster.entity, center.level_id,
            cell.x, cell.y) then
            break
        end

        net.release(ctx, monster.entity)
        ctx:move_actor(monster.entity, center.level_id, cell.x, cell.y)

        if cell.x == center.x and cell.y == center.y then
            break
        end
    end
end

-- Source: spl-transloc.cc:fatal_attraction and cast_gravitas.
local spell_effects = {}

-- An impassable gravity center is rejected before paying the spell cost.
function spell_effects.prepare(ctx, player, _, dx, dy)
    local position = ctx:get(player, component.POSITION)

    if not ctx:walkable(position.level_id,
        position.x + dx, position.y + dy) then
        return "You cannot reorient gravity there."
    end
end

-- Example: resolve(ctx, player, intent, spell, 60) attracts actors around the
-- selected cell; processing order keeps nearer blockers in place.
function spell_effects.resolve(ctx, player, intent, _, power)
    local position = ctx:get(player, component.POSITION)
    local center = {
        level_id = position.level_id,
        x = position.x + intent.dx,
        y = position.y + intent.dy,
    }
    local radius = power >= 80 and 3 or 2
    local monsters = {}

    for _, monster in ipairs(common.monsters(ctx, center.level_id)) do
        if common.distance(monster.position, center) <= radius and
            common.distance(monster.position, center) > 0 and
            not common.flag(monster.definition, "M_STATIONARY") then
            monster.caster_distance = common.distance(position,
                monster.position)
            monsters[#monsters + 1] = monster
        end
    end

    table.sort(monsters, closer_to_caster)

    for _, monster in ipairs(monsters) do
        attract(ctx, monster, center, power)
    end

    ctx:emit("spell", "Gravity reorients around the target.")
end

registry.add(spells.SPELL_GRAVITAS, {
    prepare = spell_effects.prepare,

    resolve = spell_effects.resolve,
})

return spell_effects
