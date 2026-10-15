local capabilities = require("constants.mutation_capabilities")
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local flags = require("constants.monster_flags")

local allies = {}

local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

local function conjured(definition)
    return has_flag(definition, flags.CONJURED) or
        has_flag(definition, flags.PROJECTILE) or
        has_flag(definition, flags.AVATAR)
end

function allies.forbidden(ctx, player)
    return effects.sum(ctx, player,
        capabilities.ALLIES_FORBIDDEN) > 0
end

-- Source: mon-place.cc:mons_can_hate and check_lovelessness. Summons with
-- no XP, including conjured creatures, keep their ordinary allegiance.
function allies.hostile_spawn(ctx, player, definition)
    return allies.forbidden(ctx, player) and
        not conjured(definition) and
        not has_flag(definition, flags.NO_EXP_GAIN)
end

-- Source: mon-act.cc:_update_monster_attitude. Existing allies change
-- allegiance when they next act after the player gains No Love.
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

    if summon and not summon.hostile then
        summon.hostile = true
        ctx:set(entity, component.SUMMON, summon)
        changed = true
    end

    local allegiance = ctx:get(entity, component.MONSTER_ALLEGIANCE)

    if allegiance and allegiance.charm_aut > 0 then
        allegiance.charm_aut = 0

        if allegiance.frenzy_aut > 0 or allegiance.fatigue_aut > 0 then
            ctx:set(entity, component.MONSTER_ALLEGIANCE, allegiance)
        else
            ctx:remove(entity, component.MONSTER_ALLEGIANCE)
        end

        changed = true
    end

    return changed
end

return allies
