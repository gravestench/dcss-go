local component = require("constants.component")
local spells = require("ids.spells")
local defense = require("policy.combat.monster_defense")
local catalog = require("policy.catalog")
local damage = require("policy.magic.damage")
local registry = require("policy.magic.effects.registry")
local cold_exposure = require("policy.magic.effects.statuses.monster_cold_exposure")
local streams = require("constants.rng_streams")

local refrigeration = {}

-- Missing species flags grant no conjured or cold-blooded trait.
local function has_flag(definition, wanted)
    for _, value in ipairs(definition.flags or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Spell-stream remainder draws avoid flooring fractional die sizes.
local function random_divide(ctx, numerator, denominator)
    local quotient = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and ctx:random("spell", denominator) < remainder then
        quotient = quotient + 1
    end

    return quotient
end

-- Cap spell power before converting source's four-die maximum to die sides.
local function base_sides(ctx, power)
    -- zap-data.h:ZAP_REFRIGERATE, calcdice<4,30,4,9>, cap 200.
    local maximum = 30 + math.floor(math.min(power, 200) * 4 / 9)

    return random_divide(ctx, maximum, 4)
end

-- Use a pre-damage snapshot so kills earlier in iteration do not alter chill dilution.
local function adjacent_count(ctx, target, snapshot)
    local center = ctx:get(target, component.POSITION)
    local count = 0

    for _, entry in ipairs(snapshot) do
        if entry.entity ~= target and
            entry.position.level_id == center.level_id and
            math.max(math.abs(entry.position.x - center.x),
                math.abs(entry.position.y - center.y)) <= 1 and
            not entry.conjured then
            count = count + 1
        end
    end

    return count
end

-- Nearby nonconjured actors divide the target's die size as source refrigeration does.
local function chilled_sides(ctx, base, adjacent)
    -- spl-damage.cc:_ozo_adj_dam reduces die size near other actors.
    if adjacent == 1 then
        return random_divide(ctx, 2 * base, 3)
    elseif adjacent > 1 then
        return random_divide(ctx, base, 3)
    end

    return base
end

-- Example: Ozocubu’s Refrigeration rolls cold damage for visible monsters within seven cells.
-- Snapshot all actors before damage, then process visible victims without order-dependent adjacency.
function refrigeration.resolve(ctx, player, _, _, power)
    local origin = ctx:get(player, component.POSITION)
    -- spl-damage.cc:_cast_los_attack_spell uses actor_near_iterator with
    -- LOS_NO_TRANS; the spell catalog's -1 denotes an untargeted spell.
    local reach = 7
    local sides = base_sides(ctx, power)
    local snapshot = {}
    local targets = {}

    for _, entity in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)

        if health.current > 0 and position.level_id == origin.level_id then
            local actor = ctx:get(entity, component.ACTOR)
            local definition

            if entity ~= player then
                definition = catalog.get("monsters", actor.kind_id)
            end

            snapshot[#snapshot + 1] = {
                entity = entity,
                position = position,
                conjured = definition and has_flag(definition, "M_CONJURED"),
            }

            local distance = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if entity ~= player and distance <= reach and
                ctx:visible(origin.level_id, origin.x, origin.y, reach,
                    position.x, position.y) then
                targets[#targets + 1] = {
                    entity = entity,
                    definition = definition,
                }
            end
        end
    end

    ctx:emit("spell", "The heat is drained from your surroundings.")

    for _, hit in ipairs(targets) do
        local target = hit.entity
        local health = ctx:get(target, component.HEALTH)

        if health.current > 0 then
            local definition = hit.definition
            local nearby = adjacent_count(ctx, target, snapshot)
            local die_size = chilled_sides(ctx, sides, nearby)
            local raw = 4

            for _ = 1, 4 do
                raw = raw + ctx:random("spell", die_size)
            end

            local ac = defense.armour(ctx, target, definition)
            local after_ac = math.max(0,
                raw - ctx:random("spell", ac + 1))
            local amount = damage.elemental(after_ac, definition,
                "MR_RES_COLD")

            local remaining = damage.apply(ctx, target, amount)
            ctx:emit("spell", "The refrigeration chills the " ..
                definition.name .. ".")

            if remaining > 0 then
                cold_exposure.apply(ctx, target, definition, 5,
                    streams.SPELL)
            end
        end
    end
end

registry.add(spells.SPELL_OZOCUBUS_REFRIGERATION, refrigeration)

return refrigeration
