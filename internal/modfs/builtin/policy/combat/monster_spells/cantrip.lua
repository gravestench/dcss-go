local component = require("constants.component")
local display = require("policy.combat.monster_support.display")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local streams = require("constants.rng_streams")

local cantrip = {}

local endings = {
    " casts a cantrip, but nothing happens.",
    " begins to cast a cantrip, but forgets the words!",
    " miscasts a cantrip.",
    " looks braver for a moment.",
    " looks encouraged for a moment.",
}

-- mon-cast.cc marks this harmless spell useful only against a foe. The
-- self target still preserves a typed intent across the action boundary.
function cantrip.plan(ctx, caster, foe)
    if not foe or not ctx:get(foe, component.POSITION) then
        return nil
    end

    return self_target.plan(caster)
end

-- Cantrip deliberately changes no combat state in the source; its visible
-- cast line is the whole effect and consumes the saved monster-spell RNG.
function cantrip.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local ending = endings[ctx:random(streams.MONSTER_SPELL,
        #endings) + 1]

    if senses.player_sees_actor(ctx, caster) then
        ctx:emit("spell", "The " .. display.name(ctx, caster) .. ending)
    end
end

return cantrip
