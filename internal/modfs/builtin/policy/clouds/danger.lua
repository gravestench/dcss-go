local categories = require("constants.catalog")
local component = require("constants.component")
local intelligence = require("constants.monster_intelligence")
local catalog = require("policy.catalog")
local placement = require("policy.clouds.placement")
local immunity = require("policy.clouds.immunity")
local damage = require("policy.magic.damage")
local streams = require("constants.rng_streams")

local danger = {}

-- The same resistance and adjustment hooks used by exposure inform a monster's risk estimate.
local function estimated_damage(ctx, monster, definition, effect)
    local source = definition.damage
    local amount = source.base

    if source.random > 0 then
        local trials = math.max(1, math.floor(source.random / 9))
        local total = 0

        for _ = 1, trials do
            total = total + ctx:random(streams.CLOUDS, source.random)
        end

        amount = amount + math.floor(total / trials)
    end

    if effect.risk_extra then
        amount = amount + effect.risk_extra(ctx, monster)
    end

    if effect.risk_resistance then
        amount = damage.monster_elemental(ctx, monster,
            amount, effect.risk_resistance)
    end

    if effect.risk_adjust then
        amount = effect.risk_adjust(ctx, monster, amount)
    end

    return amount
end

-- Harmless clouds can still supply an avoid hook for monster-specific behavior.
local function risky(ctx, monster, state, careful)
    local definition = catalog.get(categories.CLOUDS, state.kind_id)
    local effect = require(definition.effect)

    if definition.harmless then
        if effect.avoid then
            return effect.avoid(ctx, monster, state, careful) or false
        end

        return false
    end

    if immunity.all(ctx, monster) or
        effect.immune and effect.immune(ctx, monster, state) then
        return false
    end

    local allegiance = ctx:get(monster, component.MONSTER_ALLEGIANCE)

    if not careful and allegiance and allegiance.frenzy_aut > 0 then
        return false
    end

    if effect.avoid then
        local decision = effect.avoid(ctx, monster, state, careful)

        if decision ~= nil then
            return decision
        end
    end

    if careful then
        return true
    end

    local actor = ctx:get(monster, component.ACTOR)
    local health = ctx:get(monster, component.HEALTH)
    local monster_type = catalog.get(categories.MONSTERS, actor.kind_id)
    local brainless = monster_type.intelligence_id == intelligence.BRAINLESS

    if brainless then
        return false
    end

    local margin = 3

    if monster_type.intelligence_id ~= intelligence.ANIMAL then
        margin = margin * 2
    end

    return health.current <= margin *
        estimated_damage(ctx, monster, definition, effect)
end

-- Monster avoidance estimates cloud harm from the same effect hooks that apply exposure.
-- Example: a monster already in a dangerous cloud may leave it through another risky cell.
function danger.avoids(ctx, monster, destination, careful)
    local _, destination_cloud = placement.at(ctx,
        destination.level_id, destination.x, destination.y)

    if not destination_cloud or
        not risky(ctx, monster, destination_cloud, careful) then
        return false
    end

    if careful then
        return true
    end

    local origin = ctx:get(monster, component.POSITION)

    if not origin or
        origin.level_id ~= destination.level_id or
        (origin.x == destination.x and origin.y == destination.y) then
        return true
    end

    local _, origin_cloud = placement.at(ctx,
        origin.level_id, origin.x, origin.y)

    if not origin_cloud then
        return true
    end

    return not risky(ctx, monster, origin_cloud, true)
end

return danger
