-- Weakening Gaze is a direct status spell. The player's penalty and the
-- monster's weak enchantment keep separate source damage multipliers.
local catalog = require("policy.catalog")
local component = require("constants.component")
local gazes = require("policy.combat.monster_gazes")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local player_weakness = require("policy.combat.player_weakness")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")

local effect = {}

-- A blocked sightline rejects the spell before its status draws any RNG.
function effect.plan(ctx, caster, foe)
    return gazes.plan(ctx, caster, foe,
        spells.SPELL_WEAKENING_GAZE)
end

-- Source uses ordinary current HD, then adds `HD + random2(HD + 3)`
-- turns. The player caps its cumulative timer at fifty turns.
-- Example: a ten-HD tyrant adds at least ten turns of weakness.
function effect.resolve(ctx, caster, foe, _, plan)
    gazes.require(ctx, caster, foe, plan)

    local power = gazes.hit_dice(ctx, caster, false)

    if ctx:has(foe, component.PLAYER) then
        player_weakness.apply(ctx, foe, power)

        return
    end

    local actor = ctx:get(foe, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    enfeeble.apply_weak(ctx, foe, definition, power,
        streams.MONSTER_SPELL)
end

return effect
