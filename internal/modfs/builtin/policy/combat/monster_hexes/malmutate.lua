-- Source: beam.cc:BEAM_MALMUTATE. The enchantment has no willpower saving
-- throw; mutable monsters gain Wretched and players gain a mutation roll.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local malmutation = require("policy.monsters.malmutation")
local player_malmutation = require("policy.mutations.malmutate")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local rule = {
    saving_throw = false,
}

-- Source excludes undead, nonliving, tentacles, and Chaos Spawn from
-- monster malmutation. The player's own mutation owner checks protection.
function rule.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return true
    end

    local actor = ctx:get(defender, component.ACTOR)

    if not actor then
        return false
    end

    return malmutation.can_mutate(catalog.get(categories.MONSTERS,
        actor.kind_id))
end

-- The common beam owner already resolved contact; no damage or will roll
-- belongs between the hit and the target's mutation transition.
function rule.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        ctx:emit(channels.SPELL,
            "Strange energies course through your body.")
        player_malmutation.apply(ctx, defender,
            spells.SPELL_MALMUTATE)

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS, actor.kind_id)

    malmutation.apply(ctx, defender, definition,
        streams.MONSTER_SPELL)
end

return rule
