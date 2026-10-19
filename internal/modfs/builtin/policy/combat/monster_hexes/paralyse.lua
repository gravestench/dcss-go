local catalog = require("policy.catalog")
local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local monster_paralysis = require("policy.magic.effects.zaps.paralysis")
local monsters = require("ids.monsters")

local paralyse = {}

-- Floating Eye paralysis bypasses the ordinary enchantment saving throw.
function paralyse.resisted(ctx, caster, defender, profile)
    local actor = ctx:get(caster, component.ACTOR)

    if actor and actor.kind_id == monsters.MONS_FLOATING_EYE then
        return false
    end

    return enchantment.resisted(ctx, caster, defender, profile)
end

-- Example: paralyse.apply(ctx, caster, defender, profile) with player with zero RNG -> 20 aut paralysis
-- Source: beam.cc:BEAM_PARALYSIS. Player duration is 2..5 turns.
function paralyse.apply(ctx, caster, defender, profile, arc_power)
    if ctx:get(defender, component.PLAYER) then
        local turns = 2 + ctx:random("monster_spell", 4)
        local existing = ctx:get(defender, component.PLAYER_PARALYSIS)
        local remaining = math.max(existing and existing.remaining_aut or 0,
            turns * 10)
        local status = {
            remaining_aut = remaining,
        }

        if existing then
            ctx:set(defender, component.PLAYER_PARALYSIS, status)
        else
            ctx:add(defender, component.PLAYER_PARALYSIS, status)
        end

        ctx:emit("combat", "You are paralysed!")

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local power = enchantment.enchantment_power(ctx, caster,
        profile, arc_power)

    monster_paralysis.apply_unresisted(ctx, defender, definition, power)
end

return paralyse
