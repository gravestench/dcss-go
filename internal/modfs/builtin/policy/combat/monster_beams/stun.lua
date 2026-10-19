local catalog = require("policy.catalog")
local component = require("constants.component")
local magic_damage = require("policy.magic.damage")
local monster_flags = require("constants.monster_flags")
local resistances = require("constants.resistance_ids")

local stun = {}

-- Monster stasis flags prevent the one-turn stun from taking hold.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- An explicit electricity resistance level changes stun eligibility.
local function electric_resistance(definition)
    for _, entry in ipairs(definition.resistances or {}) do
        if entry.id == resistances.ELECTRICITY then
            return entry.level
        end
    end

    return 0
end

-- Store one baseline-delay stun using the defender's component type.
local function paralyse(ctx, defender, component_id)
    ctx:add(defender, component_id, {
        remaining_aut = 10,
    })
end

-- Example: stun.after_hit(ctx, nil, defender) with electric-immune monster -> no new stun component
-- beam.cc:BEAM_STUN_BOLT paralyzes a hit monster for one baseline delay
-- unless it resists electricity or has stasis. Players get a coin flip
-- with positive electrical resistance.
function stun.after_hit(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        if ctx:has(defender, component.PLAYER_PARALYSIS) then
            return
        end

        local resistance = magic_damage.player_resistance(ctx,
            defender, resistances.ELECTRICITY)

        if resistance > 0 and ctx:random("monster_spell", 2) == 0 then
            return
        end

        paralyse(ctx, defender, component.PLAYER_PARALYSIS)
        ctx:emit("combat", "You are paralysed by the burst!")

        return
    end

    if ctx:has(defender, component.PARALYSIS) then
        return
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        error("stunning beam defender has no actor")
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if electric_resistance(definition) > 0 or
        has_flag(definition, monster_flags.STASIS) then
        return
    end

    paralyse(ctx, defender, component.PARALYSIS)
    ctx:emit("combat", "The " .. definition.name .. " is paralysed.")
end

return stun
