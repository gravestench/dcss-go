-- Jiyva feeding modifies monster maximum HP outside the source spawn roll.
-- This saved lineage is the evidence the restore validator needs to allow
-- ordinary growth and division without relaxing unrelated monster bounds.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local identity = require("policy.religion.jiyva.identity")

local growth = {}

-- The first meal records max HP before any healing or split. Later meals
-- retain that birth value so a save cannot invent a new initial roll.
function growth.start(ctx, monster, health)
    local state = ctx:get(monster, component.JIYVA_GROWTH)

    if state then
        return state
    end

    state = {
        birth_max = health.max,
        split_count = 0,
        born_from_split = false,
    }
    ctx:add(monster, component.JIYVA_GROWTH, state)

    return state
end

-- Parent and child keep separate saved records. Only a child can exceed
-- its original level population budget by being born on the floor.
function growth.split(ctx, parent, child)
    local parent_state = ctx:get(parent, component.JIYVA_GROWTH)

    if not parent_state then
        error("splitting slime has no saved growth history")
    end

    parent_state.split_count = parent_state.split_count + 1
    ctx:set(parent, component.JIYVA_GROWTH, parent_state)

    ctx:add(child, component.JIYVA_GROWTH, {
        birth_max = parent_state.birth_max,
        split_count = parent_state.split_count,
        born_from_split = true,
    })
end

-- A marker permits only the source's four-times-average fed HP ceiling.
-- An unsplit body cannot shrink below birth max; a split body may do so.
-- Original actors still must prove a legal initial spawn profile.
function growth.validate(ctx, monster, health, profile, fixed_hp)
    local state = ctx:get(monster, component.JIYVA_GROWTH)

    if not state then
        return false
    end

    local actor = ctx:get(monster, component.ACTOR)
    local definition = actor and
        catalog.get(categories.MONSTERS, actor.kind_id)
    local average = definition and
        math.floor(definition.average_hp_10x / 10) or 0
    local legal_birth = state.born_from_split or
        (fixed_hp and fixed_hp > 0 and
            state.birth_max == fixed_hp) or
        (profile and state.birth_max >= profile.minimum and
            state.birth_max <= profile.maximum)
    local ceiling = math.min(10000,
        math.max(state.birth_max, average * 4))

    if not definition or not identity.slime(definition) or
        not legal_birth or state.birth_max < 1 or
        state.birth_max > 10000 or state.split_count < 0 or
        (state.born_from_split and state.split_count == 0) or
        health.max < 1 or health.max > ceiling or
        health.current < 1 or health.current > health.max or
        (state.split_count == 0 and health.max < state.birth_max) then
        error("invalid Jiyva-fed monster " .. ctx:id(monster))
    end

    return true
end

return growth
