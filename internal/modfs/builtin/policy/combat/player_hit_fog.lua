-- Theory of operation: surviving HP loss may release exactly one fog
-- family. Source ouch.cc first offers Dithmenos's dark smoke, next the
-- equipped cloak of the Thief, then Xom's colourful condensation. A
-- successful earlier gate suppresses later gates even if cells are full.
local artefacts = require("ids.artefacts")
local channels = require("constants.message_channels")
local cloud_ids = require("ids.clouds")
local component = require("constants.component")
local forms = require("constants.form_ids")
local gods = require("constants.gods")
local order = require("constants.damage_reaction_order")
local piety = require("policy.religion.piety")
local reactions = require("policy.combat.player_damage_reactions")
local streams = require("constants.rng_streams")

local fog = {}

-- DCSS x_chance_in_y has exact false/true fast paths. They also avoid
-- shifting the saved religion RNG on impossible or guaranteed reactions.
local function chance(ctx, numerator, denominator)
    if numerator <= 0 then
        return false
    end

    if numerator >= denominator then
        return true
    end

    return ctx:random(streams.RELIGION, denominator) < numerator
end

-- Rank three unlocks Hit Smoke, and its ramp starts at 75 piety.
-- Shadow Form makes every positive hit qualify.
local function dithmenos_triggered(ctx, player, damage, health, worship)
    if not worship or worship.god_id ~= gods.DITHMENOS or
        (worship.penance[gods.DITHMENOS] or 0) > 0 or
        piety.rank(gods.DITHMENOS, worship.piety) < 3 then
        return false
    end

    local active_form = ctx:get(player, component.PLAYER_FORM)

    if active_form and active_form.form_id == forms.SHADOW and
        active_form.remaining_aut > 0 then
        return true
    end

    local upper = math.floor(health.max / 2)
    local minimum = piety.breakpoint(3)
    local lower = upper - math.floor(upper *
        (worship.piety - minimum) / (200 - minimum))

    return chance(ctx, damage - lower, upper - lower)
end

-- Read the actual equipped and usable cloak, not any carried copy of a
-- unique artefact. The equipment owner already enforces slot and form rules.
local function wears_thief(ctx, player)
    local equipment = require("policy.combat.equipment")
    local worn = equipment.worn(ctx, player, { cloak = true })
    local cloak = worn.cloak
    local artefact = cloak and ctx:get(cloak.entity,
        component.ITEM_ARTEFACT)

    return artefact and artefact.unique_id ==
        artefacts.UNRAND_THIEF or false
end

-- A fog burst uses the common saved ECS cloud path. The source prints its
-- message before attempting cell placement, so an obstructed map still
-- reports a triggered reaction.
local function emit_cloud(ctx, player, kind, count, channel, message)
    local origin = ctx:get(player, component.POSITION)

    if not origin then
        error("hit fog requires player position")
    end

    ctx:emit(channel, message)

    local area = require("policy.clouds.area")

    area.place(ctx, kind, player, origin.level_id,
        origin.x, origin.y, 50, count, streams.CLOUDS)
end

-- Only one branch runs for each surviving hit. The source does not require
-- a monster damager here: poison, hazards, and self-harm can all make fog.
function fog.on_damage(ctx, player, damage)
    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        error("hit fog requires player health")
    end

    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if dithmenos_triggered(ctx, player, damage, health, worship) then
        emit_cloud(ctx, player, cloud_ids.CLOUD_BLACK_SMOKE,
            4 + ctx:random(streams.CLOUDS, 5),
            channels.COMBAT, "You emit a cloud of dark smoke.")

        return "dithmenos"
    end

    if damage * 10 > health.max and wears_thief(ctx, player) and
        ctx:random(streams.DAMAGE_REACTION, 2) == 0 then
        local placement = require("policy.clouds.placement")
        local kind = placement.random_smoke_kind(ctx)
        local count = 8 + ctx:random(streams.CLOUDS, 8)

        emit_cloud(ctx, player, kind, count,
            channels.COMBAT,
            "With a swish of your cloak, you release a cloud of fog.")

        return "thief"
    end

    local upper = math.floor(health.max / 2)

    if worship and worship.god_id == gods.XOM and
        chance(ctx, damage, 30 * upper) then
        emit_cloud(ctx, player, cloud_ids.CLOUD_XOM_TRAIL,
            4 + ctx:random(streams.CLOUDS, 5),
            channels.RELIGION,
            "You emit a cloud of colourful smoke!")

        return "xom"
    end

    return nil
end

-- Preserve the source position between guardian and Powered by Pain;
-- callback sorting prevents a mod's file name from changing that order.
function fog.register()
    reactions.add("combat.player_hit_fog", order.HIT_FOG,
        fog.on_damage)
end

return fog
