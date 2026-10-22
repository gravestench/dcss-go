-- Example: No Love rejects a summoned ally even when the monster has no flag list.
local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flags = require("constants.monster_flags")
local attitude = require("constants.attitude")
local targets = require("policy.ai.targets")
local allegiance = require(
    "policy.magic.effects.statuses.monster_allegiance")

local allies = {}

-- Check catalog flags without assuming every monster definition has a flag list.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Exclude temporary conjurations and avatars from the ordinary allegiance rewrite.
local function conjured(definition)
    return has_flag(definition, flags.CONJURED) or
        has_flag(definition, flags.PROJECTILE) or
        has_flag(definition, flags.AVATAR)
end

-- Read the combined No Love capability before spawn or spell legality
-- chooses an ally.
function allies.forbidden(ctx, player)
    return effects.sum(ctx, player,
        capabilities.ALLIES_FORBIDDEN) > 0
end

-- Source SAME_ATTITUDE copies a monster caster's current side. The player's
-- No Love mutation is a separate rule for player-owned ordinary summons.
function allies.summoned_attitude(ctx, owner, definition)
    if owner ~= ctx:player() then
        return targets.attitude(ctx, owner)
    end

    -- Source mon-place.cc excludes conjurations and no-XP creatures from
    -- the player's No Love allegiance rewrite.
    if allies.forbidden(ctx, owner) and
        not conjured(definition) and
        not has_flag(definition, flags.NO_EXP_GAIN) then
        return attitude.HOSTILE
    end

    return attitude.FRIENDLY
end

-- Source: mon-act.cc:_update_monster_attitude. Existing allies change
-- allegiance when they next act after the player gains No Love.
-- Recheck allegiance on the monster turn because a new Lovelessness mutation can turn existing allies hostile.
function allies.on_monster_turn(ctx, entity)
    if not allies.forbidden(ctx, ctx:player()) then
        return false
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if conjured(definition) then
        return false
    end

    local changed = false
    local summon = ctx:get(entity, component.SUMMON)

    if summon and summon.owner == ctx:player() and
        summon.attitude ~= attitude.HOSTILE then
        summon.attitude = attitude.HOSTILE
        ctx:set(entity, component.SUMMON, summon)
        changed = true
    end

    if allegiance.clear_charm(ctx, entity) then
        changed = true
    end

    return changed
end

return allies
