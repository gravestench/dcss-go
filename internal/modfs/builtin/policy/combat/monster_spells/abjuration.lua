-- Abjuration shortens hostile summons' existing saved lifetimes. The summon
-- expiry owner then performs teardown, including source-specific effects.
-- Source: mon-cast.cc:_monster_abjuration and _monster_abjure_target.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local actors = require("policy.combat.monster_area.actors")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local self_target = require("policy.combat.monster_support.self_target")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7
local POWER_PER_HD = 12
local LOWER_FUZZ_PERCENT = 40
local UPPER_FUZZ_PERCENT = 25
local MIN_POWER = 20

-- Only an enemy's timed summon is susceptible. A permanent creature or
-- aligned summon must not make the caster spend an Abjuration action.
local function vulnerable(ctx, caster, target)
    if not targets.enemy(ctx, caster, target) then
        return false
    end

    local summon = ctx:get(target, component.SUMMON)

    return summon ~= nil and summon.expires_aut > ctx:aut()
end

-- This is a self-centered LOS spell. Keep target selection free of rolls;
-- the actual abjuration power is fuzzed only after the action commits.
function effect.plan(ctx, caster)
    for _, target in ipairs(actors.los(ctx, caster, SIGHT_RADIUS)) do
        if vulnerable(ctx, caster, target) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Source spell power is twelve per effective spell HD, with asymmetric
-- forty-percent lower and twenty-five-percent upper fuzz on two draws.
local function abjuration_power(ctx, caster)
    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local raw = hd * POWER_PER_HD
    local lower = math.floor(raw * LOWER_FUZZ_PERCENT / 100)
    local upper = math.floor(raw * UPPER_FUZZ_PERCENT / 100)
    local fuzz = roll.average_two(ctx, streams.MONSTER_SPELL,
        lower + upper + 1)

    return math.max(MIN_POWER, raw + fuzz - lower)
end

-- A dispelled summon expires at the normal action barrier. Updating the
-- existing record preserves its owner, attitude, source, and save identity.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local victims = actors.los(ctx, caster, SIGHT_RADIUS)

    if #victims == 0 then
        return
    end

    local affected = false

    for _, target in ipairs(victims) do
        if vulnerable(ctx, caster, target) then
            local summon = ctx:get(target, component.SUMMON)
            local power = abjuration_power(ctx, caster)

            summon.expires_aut = math.max(ctx:aut(),
                summon.expires_aut - power)
            ctx:set(target, component.SUMMON, summon)
            affected = true
        end
    end

    if affected then
        ctx:emit(channels.SPELL, "Send 'em back where they came from!")
    end
end

return effect
