-- Irradiate is an actor-centered burst shared by player and monster casts.
-- Each neighboring living body rolls its own three-die magical hit; a
-- surviving player gains contamination, and a surviving monster may gain
-- Wretched. The caster gains contamination only when it is the player.
-- Source: spl-damage.cc:irradiate_damage, _irradiate_cell, cast_irradiate.
-- Example: area.resolve(ctx, caster, 100, streams.MONSTER_SPELL) can hit
-- both a hostile player and a monster standing beside the same caster.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local defense = require("policy.combat.monster_defense")
local direct = require("policy.combat.monster_direct")
local flags = require("constants.monster_flags")
local magic_damage = require("policy.magic.damage")
local malmutation = require("policy.monsters.malmutation")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local zap_ids = require("policy.magic.effects.zaps.ids")

local irradiate = {}
local DICE = 3
local MAX_CONTAMINATION = 250000

-- Source lists and flags are optional on some monster definitions. Missing
-- lists grant no immunity to radiation or its Wretched consequence.
local function has(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Contamination is one saved player component regardless of whether a
-- monster hit, player cast, cloud, or trap caused the increase.
local function contaminate(ctx, player, added)
    local state = ctx:get(player, zap_ids.component.CONTAMINATION)
    local amount = math.min(MAX_CONTAMINATION,
        (state and state.amount or 0) + added)

    if state then
        state.amount = amount
        ctx:set(player, zap_ids.component.CONTAMINATION, state)
    else
        ctx:add(player, zap_ids.component.CONTAMINATION, {
            amount = amount,
        })
    end
end

-- Both commands and monster AI need the same live footprint. Terrain does
-- not remove a neighboring actor from the source's cell applicator.
function irradiate.victims(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)
    local found = {}

    if not origin then
        return found
    end

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local target = ctx:actor_at(origin.level_id,
                    origin.x + dx, origin.y + dy)
                local health = target and
                    ctx:get(target, component.HEALTH)

                if target and health and health.current > 0 then
                    found[#found + 1] = target
                end
            end
        end
    end

    return found
end

-- Source calc_dice(3, 35 + rounded(power/2)) yields three dice with
-- stochastically rounded sides. Roll each victim after geometry is fixed.
local function raw_damage(ctx, power, stream)
    local maximum = 35 + roll.random_divide(ctx,
        power, 2, stream)
    local sides = roll.random_divide(ctx, maximum, DICE, stream)
    local raw = DICE

    for _ = 1, DICE do
        raw = raw + ctx:random(stream, sides)
    end

    return raw
end

-- Apply current AC before HP, then give only surviving victims their
-- radiation consequence. Conjured monsters receive neither effect.
local function strike(ctx, caster, target, power, stream)
    local is_player = ctx:has(target, component.PLAYER)
    local definition

    if not is_player then
        local actor = ctx:get(target, component.ACTOR)

        if not actor then
            return
        end

        definition = catalog.get(categories.MONSTERS, actor.kind_id)

        if has(definition.flags, flags.CONJURED) then
            return
        end
    end

    local raw = raw_damage(ctx, power, stream)
    local after_ac

    if is_player then
        after_ac = magic_damage.player_armour(ctx,
            target, raw, nil, stream)
    else
        local ac = defense.armour(ctx, target, definition)

        after_ac = math.max(0,
            raw - ctx:random(stream, ac + 1))
    end

    if after_ac > 0 then
        direct.damage(ctx, caster, target, after_ac)
    end

    if is_player then
        ctx:emit(channels.SPELL,
            "You are blasted with magical radiation.")
    else
        ctx:emit(channels.SPELL, "The " .. definition.name ..
            " is blasted with magical radiation.")
    end

    local health = ctx:get(target, component.HEALTH)

    if not health or health.current <= 0 then
        return
    end

    if is_player then
        contaminate(ctx, target,
            2000 + ctx:random(stream, 1000))
    else
        malmutation.apply(ctx, target, definition, stream)
    end
end

-- The caster is excluded from its own burst, but a player caster still
-- receives the separate source self-contamination after all eight cells.
function irradiate.resolve(ctx, caster, power, stream)
    stream = stream or streams.SPELL

    for _, target in ipairs(irradiate.victims(ctx, caster)) do
        strike(ctx, caster, target, power, stream)
    end

    if ctx:has(caster, component.PLAYER) then
        contaminate(ctx, caster,
            1250 + ctx:random(stream, 750))
    end
end

return irradiate
