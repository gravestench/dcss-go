-- Glaciate sweeps a 90-degree cone from the caster's saved aim. Each
-- reached cell rolls its own ten-die cold hit and places freezing vapour;
-- outer rings have weaker damage and shorter clouds.
-- Source: spl-damage.cc:cast_glaciate and mon-cast.cc:_glaciate_tracer.
-- Example: an allied nondemon refuses when the cone includes the player.
local catalog = require("policy.catalog")
local calculators = require("policy.combat.monster_beams.calculators")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local clouds = require("ids.clouds")
local component = require("constants.component")
local cone = require("policy.combat.monster_area.cone")
local decision = require("policy.combat.monster_area.decision")
local display = require("policy.combat.monster_support.display")
local flavours = require("constants.beam_flavours")
local holiness = require("constants.monster_holiness")
local impact = require("policy.combat.monster_area.impact")
local monster_stats = require("policy.combat.monster_stats")
local placement = require("policy.clouds.placement")
local range = require("policy.magic.range")
local roll = require("policy.combat.roll")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")

local effect = {}
local spell = catalog.get(categories.SPELLS, spells.SPELL_GLACIATE)
local POWER_PER_HD = 12
local SIGHT_RADIUS = 7
local MIN_EFFECTIVE_RANGE = 3
local DAMAGE_DICE = 10
local CLOUD_TURN_AUT = 10

-- Spell HD includes temporary brilliance. The source Glaciate has the
-- ordinary twelve power per HD, not an Iceblast zap profile.
local function spell_power(ctx, caster)
    local state = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    return POWER_PER_HD *
        monster_stats.spell_hit_dice(ctx, caster, definition)
end

-- Demonic allied casters may risk the player; other allies never do.
local function demonic(ctx, caster)
    local state = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    for _, kind in ipairs(definition.holiness or {}) do
        if kind == holiness.DEMONIC then
            return true
        end
    end

    return false
end

-- Preserve the source aim cell while evaluating every actor in the cone.
-- A cast is worthwhile only if enemy experience outweighs friendly power.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)
    local reach = range.for_power(spell, 0)

    if not source or not destination or
        source.level_id ~= destination.level_id or
        math.max(math.abs(destination.x - source.x),
            math.abs(destination.y - source.y)) > reach or
        not ctx:visible_no_trans(source.level_id,
            source.x, source.y, SIGHT_RADIUS,
            destination.x, destination.y) then
        return nil
    end

    local victims = {}

    for _, cell in ipairs(cone.cells(ctx, source.level_id,
        source.x, source.y, destination.x, destination.y, reach)) do
        local actor = ctx:actor_at(cell.level_id, cell.x, cell.y)
        local health = actor and ctx:get(actor, component.HEALTH)

        if health and health.current > 0 then
            if actor == ctx:player() and
                targets.aligned(ctx, caster, actor) and
                not demonic(ctx, caster) then
                return nil
            end

            victims[#victims + 1] = actor
        end
    end

    local foes, friends = decision.weights(ctx, caster, victims)

    if foes <= friends then
        return nil
    end

    return {
        kind = target_kind.CELL,
        level_id = destination.level_id,
        x = destination.x,
        y = destination.y,
        dx = destination.x - source.x,
        dy = destination.y - source.y,
    }
end

-- Source calc_dice rounds its die size separately for each cell, including
-- empty ones. Cold-cloud duration is also rolled per reached cell.
local function cell_dice(ctx, power, ring)
    local effective = math.max(MIN_EFFECTIVE_RANGE,
        math.floor(6 * ring / SIGHT_RADIUS))
    local maximum = math.floor(
        (54 + math.floor(3 * power / 2)) / effective)
    local count = DAMAGE_DICE
    local sides

    if maximum <= count then
        count = maximum
        sides = 1
    else
        sides = roll.random_divide(ctx, maximum,
            count, streams.MONSTER_SPELL)
    end

    return {
        count = count,
        sides = sides,
    }, effective
end

-- The saved aim fixes cone geometry even if the original foe moves before
-- resolution. Terrain and actor state are read live at each swept cell.
function effect.resolve(ctx, caster, _, _, plan)
    local source = ctx:get(caster, component.POSITION)

    if not plan or plan.kind ~= target_kind.CELL or
        not source or source.level_id ~= plan.level_id then
        error("Glaciate has no valid saved aim")
    end

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit(channels.SPELL, "The " ..
            display.name(ctx, caster) ..
            " conjures a mighty blast of ice!")
    end

    local power = spell_power(ctx, caster)
    local reach = range.for_power(spell, 0)
    local profile = {
        flavour = flavours.BEAM_ICE,
        rng_stream = streams.MONSTER_SPELL,
    }

    for _, cell in ipairs(cone.cells(ctx, plan.level_id,
        source.x, source.y, plan.x, plan.y, reach)) do
        local dice, effective = cell_dice(ctx, power, cell.ring)
        local actor = ctx:actor_at(cell.level_id, cell.x, cell.y)
        local health = actor and ctx:get(actor, component.HEALTH)

        if health and health.current > 0 then
            local raw = calculators.roll_damage(ctx, dice,
                streams.MONSTER_SPELL)

            impact.hit(ctx, caster, actor, raw, profile)
        end

        local duration = math.floor(
            (18 + roll.average_two(ctx,
                streams.MONSTER_SPELL, 45)) / effective)
        placement.place(ctx, clouds.CLOUD_COLD, caster,
            cell.level_id, cell.x, cell.y,
            duration * CLOUD_TURN_AUT)
    end
end

return effect
