-- Theory of operation: Makhleb's destruction powers target before time,
-- draw their source failure and power before tracing, then pick one zap.
-- The projectile owner resolves contact; this file owns only invocation.
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local magic_power = require("policy.magic.power")
local projectile = require("policy.magic.effects.zaps.projectile")
local choices = require("policy.religion.makhleb.destruction")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local vision = require("policy.character.vision")
local zaps = require("constants.zap_ids")

require("policy.magic.effects.zaps.makhleb_missing")

local destruction = {}

-- Only the live patron and source rank grant this power; a saved menu row
-- does not survive conversion or penance.
function destruction.available(ctx, player, rank)
    return costs.available(ctx, player, gods.MAKHLEB, rank)
end

-- Source ability_range clamps both nominal ranges to current vision.
-- Nightstalker therefore changes the power's prompt as well as its trace.
function destruction.range(ctx, player, nominal)
    return math.min(nominal, vision.radius(ctx, player))
end

-- Two random2(1 + skill) draws vary the beam while the training scale
-- distinguishes Minor from Major without duplicating the formula.
function destruction.power(ctx, player, scale)
    local trained = magic_power.training(ctx, player,
        skills.SK_INVOCATIONS, scale)

    return trained +
        ctx:random(streams.RELIGION, trained + 1) +
        ctx:random(streams.RELIGION, trained + 1)
end

-- Refuse the last HP, self-direction, out-of-sight aim, and an ally on
-- the debug ray before a timed intent exists. On an unsafe ray, draw the
-- source failure and power in their source order even though time is free.
function destruction.prepare(ctx, player, input, hp, reach,
    fail_base, fail_scale, fail_divisor, power_scale)
    if not costs.enough_health(ctx, player, hp) then
        return "You do not have enough health."
    end

    local dx = input.dx or 0
    local dy = input.dy or 0

    if dx == 0 and dy == 0 then
        return "Okay, then."
    end

    local origin = ctx:get(player, component.POSITION)
    local range = destruction.range(ctx, player, reach)

    if math.max(math.abs(dx), math.abs(dy)) > range or
        not ctx:visible(origin.level_id, origin.x, origin.y,
            range, origin.x + dx, origin.y + dy) then
        return "That is beyond your range."
    end

    if not projectile.safe_aim(ctx, player, input, range) then
        costs.failed(ctx, player, fail_base,
            fail_scale, fail_divisor)
        destruction.power(ctx, player, power_scale)

        return "You cannot fire through an ally."
    end

    return nil
end

-- Draw failure and power before the source tracer. A failed power spends
-- its action without choosing a zap; success pays HP and optional piety.
function destruction.resolve(ctx, player, intent, tier, hp,
    fail_base, fail_scale, fail_divisor, power_scale, nominal)
    local failed = costs.failed(ctx, player, fail_base,
        fail_scale, fail_divisor)
    local power = destruction.power(ctx, player, power_scale)
    local range = destruction.range(ctx, player, nominal)

    if not projectile.safe_aim(ctx, player, intent, range) then
        return
    end

    if failed then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    local tier_choices = choices[tier]
    local id = tier_choices[ctx:random(streams.RELIGION,
        #tier_choices) + 1]
    local spec = projectile.specs[id]

    if not spec then
        error("Makhleb has no player zap profile for " .. id)
    end

    local zap_power = id == zaps.ZAP_BREATHE_ACID and
        math.floor(power / 7) or power

    projectile.fire(ctx, player, intent, nil, spec, zap_power, range)
    costs.spend_health(ctx, player, hp)

    if tier == "major" then
        costs.spend(ctx, player, 0,
            ctx:random(streams.RELIGION, 2))
    end
end

return destruction
