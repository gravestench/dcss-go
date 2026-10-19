local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local monster_status = require(
    "policy.magic.effects.statuses.lowered_will")
local player_status = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")

local strip = {}

function strip.resisted(ctx, caster, defender, profile)
    -- Source: beam.cc:bolt::has_saving_throw ignores will one third
    -- of the time for BEAM_VULNERABILITY.
    if ctx:random(streams.MONSTER_SPELL, 3) == 0 then
        return false
    end

    return enchantment.resisted(ctx, caster, defender, profile)
end

function strip.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        local state = ctx:get(defender, component.PLAYER_STATUS)

        return not state or state.lowered_will_aut <= 0
    end

    return not monster_status.active(ctx, defender)
end

-- Source: beam.cc:BEAM_VULNERABILITY. Players receive 12..29 turns;
-- monsters receive 20..30 turns on their own saved status clock.
function strip.apply(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        local turns = 12 + ctx:random(streams.MONSTER_SPELL, 18)

        player_status.lower_will(ctx, defender, turns * 10)
        ctx:emit("combat", "Your willpower is stripped away!")

        return
    end

    local turns = 20 + ctx:random(streams.MONSTER_SPELL, 11)

    monster_status.apply(ctx, defender, turns * 10)
end

return strip
