local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local corpse_chunks = require("policy.combat.corpse_chunks")
local damage = require("policy.magic.damage")
local habitat = require("policy.combat.monster_habitat")
local range = require("policy.magic.range")
local registry = require("policy.magic.effects.registry")
local trajectory = require("policy.combat.trajectory")

local mystic = {}

function mystic.farther(a, b)
    return a.distance > b.distance
end

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function random_round(ctx, numerator, denominator)
    local value = math.floor(numerator / denominator)

    if ctx:random("spell", denominator) < numerator % denominator then
        value = value + 1
    end

    return value
end

local function targets(ctx, player, spell)
    local origin = ctx:get(player, component.POSITION)
    local reach = range.for_spell(ctx, player, spell)
    local found = {}

    for _, target in ipairs(ctx:query({
        component.ACTOR, component.HEALTH, component.POSITION,
    })) do
        if target ~= player then
            local position = ctx:get(target, component.POSITION)
            local health = ctx:get(target, component.HEALTH)
            local actor = ctx:get(target, component.ACTOR)
            local definition = require("policy.catalog").get(
                "monsters", actor.kind_id)
            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if health.current > 0 and not has_flag(definition, "M_CONJURED") and
                position.level_id == origin.level_id and
                distance >= 1 and distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) then
                found[#found + 1] = {
                    entity = target,
                    position = position,
                    definition = definition,
                    distance = distance,
                }
            end
        end
    end

    table.sort(found, mystic.farther)

    return found
end

local function knockback(ctx, origin, target, position, definition, power)
    if has_flag(definition, "M_STATIONARY") or
        ctx:has(target, "projectile.held") then
        return
    end

    local ray = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, position.x, position.y, 7)
    local index

    for i, cell in ipairs(ray.path) do
        if cell.x == position.x and cell.y == position.y then
            index = i
            break
        end
    end

    if not index then
        return
    end

    local steps = 2 + random_round(ctx, power, 50)
    local weight = corpse_chunks.maximum(definition)
    local moved = false
    local next_index = index

    for _ = 1, steps do
        if ctx:random("spell", 17) < weight then
            -- beam.cc:knockback_actor skips this individual movement roll.
        else
            next_index = next_index + 1
            local cell = ray.path[next_index]

            if not cell or
                ctx:actor_at(origin.level_id, cell.x, cell.y) or
                not habitat.at(ctx, target, origin.level_id,
                    cell.x, cell.y) then
                break
            end

            ctx:move_actor(target, origin.level_id, cell.x, cell.y)
            moved = true
        end
    end

    if moved then
        ctx:emit("spell", "The " .. definition.name ..
            " is knocked back by the mystic blast.")
    end
end

function mystic.resolve(ctx, player, _, spell, power)
    local origin = ctx:get(player, component.POSITION)

    ctx:emit("spell", "You erupt in a blast of force!")

    for _, entry in ipairs(targets(ctx, player, spell)) do
        local target = entry.entity
        local position = ctx:get(target, component.POSITION)
        local health = ctx:get(target, component.HEALTH)

        if position and health and health.current > 0 and
            ctx:visible(origin.level_id, origin.x, origin.y, 7,
                position.x, position.y) then
            -- zap-data.h:ZAP_MYSTIC_BLAST is calcdice<2,6,1,3>.
            local sides = random_round(ctx,
                6 + math.floor(math.min(power, 100) / 3), 2)
            local raw = 2 + ctx:random("spell", sides) +
                ctx:random("spell", sides)
            local ac = defense.armour(ctx, target, entry.definition)
            local amount = math.max(0, raw - ctx:random("spell", ac + 1))

            damage.apply(ctx, target, amount)

            if amount > 0 and ctx:get(target, component.HEALTH).current > 0 then
                knockback(ctx, origin, target, position,
                    entry.definition, power)
            end
        end
    end
end

registry.add(spells.SPELL_ISKENDERUNS_MYSTIC_BLAST, mystic)

return mystic
