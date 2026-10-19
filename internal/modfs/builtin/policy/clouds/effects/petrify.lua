-- cloud.cc:CLOUD_PETRIFY. A player makes a level-dependent resistance roll;
-- monster enchantment uses the existing saved two-stage stasis state.
local categories = require("constants.catalog")
local component = require("constants.component")
local streams = require("constants.rng_streams")
local player_status = require("policy.combat.player_petrification")
local monster_status = require("policy.magic.effects.statuses.monster_stasis")
local resistance = require("policy.combat.player_resistance")
local monster_resistance = require("policy.clouds.effects.resistance")
local resistances = require("constants.resistance_ids")
local flags = require("constants.monster_flags")
local catalog = require("policy.catalog")

local petrify = {}

-- Check actor-specific petrification resistance before progressing the cloud effect.
function petrify.immune(ctx, actor)
    if actor == ctx:player() then
        return resistance.petrification(ctx, actor)
    end

    if monster_resistance.monster(ctx, actor,
        resistances.PETRIFY) > 0 then
        return true
    end

    local state = ctx:get(actor, component.ACTOR)

    if not state then
        return true
    end

    local definition = catalog.get(categories.MONSTERS, state.kind_id)

    for _, flag in ipairs(definition.flags or {}) do
        if flag == flags.INSUBSTANTIAL then
            return true
        end
    end

    return false
end

-- Level and immunity checks precede a saved stone status; contact itself deals no HP damage.
-- Example: petrifying cloud exposure can start a saved petrification state after its level check.
function petrify.apply(ctx, actor)
    if petrify.immune(ctx, actor) then
        return 0
    end

    if actor == ctx:player() then
        local progress = ctx:get(actor, component.PROGRESSION)

        if ctx:random(streams.CLOUDS, 55) - 13 >= progress.level then
            player_status.apply(ctx, actor)
        end

        return 0
    end

    monster_status.apply_petrify(ctx, actor)

    return 0
end

return petrify
