-- Fire Storm is a selected-cell lava blast. Source setup rolls a radius
-- of two or three before its tracer and keeps that footprint for the cast.
-- Source: mon-cast.cc:setup_mons_cast and spl-damage.cc:setup_fire_storm.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local clouds = require("ids.clouds")
local component = require("constants.component")
local magic_damage = require("policy.magic.damage")
local monsters = require("ids.monsters")
local placement = require("policy.clouds.placement")
local power = require("policy.combat.monster_beams.power")
local roll = require("policy.combat.roll")
local resistances = require("constants.resistance_ids")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targeting = require("policy.combat.monster_area.targeting")
local terrain = require("constants.terrain")

local effect = {}
local base = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_FIRE_STORM)
local MIN_RADIUS = 2
local RADIUS_ROLL = 1000
local MIN_FOE_RATIO = 40
local FOE_RATIO_SPAN = 16
local LAVA_RESISTIBLE_PERCENT = 55

-- Source lava damage keeps 45 percent beyond fire resistance. Estimate
-- that split without triggering the player's damage-time reactions during
-- AI planning; monster resistance calculation is already read-only.
local function expected_impact(ctx, victim)
    local resistible = LAVA_RESISTIBLE_PERCENT
    local irresistible = 100 - resistible

    if not ctx:has(victim, component.PLAYER) then
        return irresistible + magic_damage.monster_elemental(ctx,
            victim, resistible, resistances.FIRE)
    end

    local level = magic_damage.player_resistance(ctx, victim,
        resistances.FIRE)

    if level > 0 then
        return irresistible + math.floor(resistible /
            math.floor((3 * level + 1) / 2))
    end

    if level < 0 then
        return irresistible + math.floor(resistible * 3 / 2)
    end

    return 100
end

-- Each reached cell catches fire. Empty ordinary floor may also release a
-- one-turn fire vortex, matching the source's one-in-four cell roll.
local function after_cell(ctx, caster, _, cell)
    local feature = ctx:cell(cell.level_id, cell.x, cell.y)

    -- Source explosion clouds convert fiery contact with water to steam
    -- before considering the ordinary fire cloud or a fire vortex.
    if feature == terrain.DNGN_SHALLOW_WATER or
        feature == terrain.DNGN_DEEP_WATER then
        placement.place(ctx, clouds.CLOUD_STEAM, caster,
            cell.level_id, cell.x, cell.y,
            (2 + ctx:random(streams.MONSTER_SPELL, 5)) * 10)

        return
    end

    local duration = 2 + roll.average_two(ctx,
        streams.MONSTER_SPELL, 5)

    placement.place(ctx, clouds.CLOUD_FIRE, caster,
        cell.level_id, cell.x, cell.y, duration * 10)

    if feature ~= terrain.DNGN_FLOOR or
        ctx:actor_at(cell.level_id, cell.x, cell.y) or
        ctx:random(streams.MONSTER_SPELL, 4) ~= 0 then
        return
    end

    local health = caster and ctx:get(caster, component.HEALTH)

    if not caster or health and health.current <= 0 then
        return
    end

    summons.spawn(ctx, caster, spells.SPELL_FIRE_STORM,
        monsters.MONS_FIRE_VORTEX, 1, nil, {
            exact = {
                x = cell.x,
                y = cell.y,
            },
        })
end

-- Creeping inferno death uses the same Fire Storm cell aftermath; export the
-- focused operation without duplicating cloud and vortex terrain policy.
effect.after_cell = after_cell

-- Give the existing beam owners a per-cast footprint without mutating the
-- registered catalog fact shared by every Fire Storm caster.
local function with_radius(radius)
    local profile = {}

    for key, value in pairs(base) do
        profile[key] = value
    end

    profile.explosion_radius = radius

    return profile
end

-- The source's one-in-a-thousand-per-power roll belongs to the saved plan;
-- resolution must not reroll a larger or smaller explosion later.
function effect.plan(ctx, caster, foe)
    local chance = math.min(base.cap,
        power.caster_power(ctx, caster, base))
    local extra = ctx:random(streams.MONSTER_SPELL,
        RADIUS_ROLL) < chance and 1 or 0
    local radius = MIN_RADIUS + extra
    local ratio = MIN_FOE_RATIO +
        ctx:random(streams.MONSTER_SPELL, FOE_RATIO_SPAN)
    local plan = targeting.plan(ctx, caster, foe,
        with_radius(radius), radius, ratio, expected_impact)

    if plan then
        plan.radius = radius
    end

    return plan
end

-- A corrupt or unrelated target plan cannot widen the blast arbitrarily.
-- The shared beam contact owner applies lava resistance to each victim.
function effect.resolve(ctx, caster, foe, _, plan)
    if not plan or plan.radius < MIN_RADIUS or
        plan.radius > MIN_RADIUS + 1 then
        error("Fire Storm has no valid saved radius")
    end

    return beam.resolve(ctx, caster, foe,
        with_radius(plan.radius), plan, {
            after_cell = after_cell,
        })
end

return effect
