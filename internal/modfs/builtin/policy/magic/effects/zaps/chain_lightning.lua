local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local player_health = require("policy.combat.player_health")
local registry = require("policy.magic.effects.registry")

local chain_lightning = {}

-- Use Chebyshev distance for both initial reach and later three-cell jumps.
local function distance(a, b)
    return math.max(math.abs(a.x - b.x), math.abs(a.y - b.y))
end

-- Skip dead, conjured, and no-threat monsters while allowing a later arc to hit the caster.
local function worth_targeting(ctx, player, target)
    if target == player then
        return true
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)

    if not actor or not health or health.current <= 0 then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == "M_NO_THREAT" or flag == "M_CONJURED" then
            return false
        end
    end

    return true
end

-- Each jump excludes already struck actors so the chain advances to a new target.
local function candidates(ctx, player, source, radius, seen)
    local origin = ctx:get(player, component.POSITION)
    local found = {}

    for _, target in ipairs(ctx:query({ component.POSITION, component.HEALTH })) do
        if not seen[target] and worth_targeting(ctx, player, target) then
            local position = ctx:get(target, component.POSITION)

            if position.level_id == source.level_id and
                distance(source, position) <= radius and
                distance(origin, position) <= 7 and
                ctx:visible(origin.level_id, origin.x, origin.y, 7,
                    position.x, position.y) and
                ctx:projectile_clear(source.level_id, source.x, source.y,
                    position.x, position.y) then
                found[#found + 1] = {
                    entity = target,
                    position = position,
                }
            end
        end
    end

    return found
end

-- Break nearest-target ties with the spell RNG stream after collecting all equal-distance actors.
local function initial(ctx, player)
    local origin = ctx:get(player, component.POSITION)
    local found = candidates(ctx, player, origin, 7, {
        [player] = true,
    })
    local nearest = {}
    local nearest_distance = 8

    for _, entry in ipairs(found) do
        local reach = distance(origin, entry.position)

        if reach < nearest_distance then
            nearest = { entry }
            nearest_distance = reach
        elseif reach == nearest_distance then
            nearest[#nearest + 1] = entry
        end
    end

    if #nearest == 0 then
        return nil, 0
    end

    return nearest[1 + ctx:random("spell", #nearest)], nearest_distance
end

-- Cap power then stochastically round the three-die side count on the spell stream.
local function sides(ctx, power)
    local maximum = 2 * math.min(power, 200)
    local value = math.floor(maximum / 3)
    local remainder = maximum % 3

    if remainder > 0 and ctx:random("spell", 3) < remainder then
        value = value + 1
    end

    return value
end

-- Zero sides consume no RNG; otherwise each strike rolls three independent lightning dice.
local function roll(ctx, side)
    if side <= 0 then
        return 0
    end

    return 3 + ctx:random("spell", side) +
        ctx:random("spell", side) + ctx:random("spell", side)
end

-- Only half the raw arc is resistible electricity; the other half bypasses rElec.
local function resist_monster(raw, definition)
    local resistible = math.floor(raw / 2)

    return raw - resistible +
        damage.elemental(resistible, definition, "MR_RES_ELEC")
end

-- Self-hit arcs use player resistance on half the damage after player armour.
local function resist_player(ctx, player, raw)
    local resistible = math.floor(raw / 2)

    return raw - resistible +
        damage.player_elemental(ctx, player, resistible, "MR_RES_ELEC")
end

-- Resolve armour and half-resistible electricity separately for player and monster targets.
local function strike(ctx, player, target, side)
    local raw = roll(ctx, side)

    if target == player then
        local after_ac = damage.player_armour(ctx, player, raw)
        player_health.damage(ctx, player,
            resist_player(ctx, player, after_ac))
        ctx:emit("spell", "An arc of lightning strikes you!")
        return
    end

    local definition, health = damage.monster(ctx, target)

    if not definition or health.current <= 0 then
        return
    end

    local ac = defense.armour(ctx, target, definition)
    local after_ac = math.max(0, raw - ctx:random("spell", ac + 1))

    damage.apply(ctx, target, resist_monster(after_ac, definition))
    ctx:emit("spell", "An arc of lightning strikes the " ..
        definition.name .. "!")
end

-- Example: After striking one monster, Chain Lightning recalculates its next target from that contact.
-- Successive strikes recalculate candidates from the latest contact point.
function chain_lightning.resolve(ctx, player, _, _, power)
    local first, initial_range = initial(ctx, player)

    if not first then
        ctx:emit("spell", "Nothing happens.")
        return
    end

    local side = math.floor(sides(ctx, power) *
        0.6 ^ ((initial_range - 1) / 3))
    local seen = { [first.entity] = true }
    local wave = { first }

    while #wave > 0 do
        local next_wave = {}

        for _, entry in ipairs(wave) do
            local adjusted = entry.entity == player and
                math.floor(side / 6) or side

            strike(ctx, player, entry.entity, adjusted)

            for _, candidate in ipairs(candidates(ctx, player,
                entry.position, 3, seen)) do
                seen[candidate.entity] = true
                next_wave[#next_wave + 1] = candidate
            end
        end

        wave = next_wave
        side = math.floor(side * 3 / 5)
    end
end

registry.add(spells.SPELL_CHAIN_LIGHTNING, chain_lightning)

return chain_lightning
