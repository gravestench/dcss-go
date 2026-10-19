-- Monster Chain Lightning uses the source thunder zap and actor-neutral
-- jump policy. It is reckless: the nearest valid body may be an ally,
-- and a later arc may return to its caster at reduced damage.
-- Source: mon-cast.cc and spl-damage.cc:_chain_lightning_to.
-- Example: a hostile caster with one foe in sight can start an arc even
-- when another body is nearer to the eventual jump path.
local actors = require("policy.combat.monster_area.actors")
local area = require("policy.combat.monster_area.chain_lightning")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local display = require("policy.combat.monster_support.display")
local power = require("policy.combat.monster_beams.power")
local self_target = require("policy.combat.monster_support.self_target")
local senses = require("policy.character.senses")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local effect = {}
local SIGHT_RADIUS = 7
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CHAIN_LIGHTNING)

-- Friendly casters refuse to arc in the player's sight. Otherwise the
-- source AI needs a possible hostile in LOS but does not protect friends
-- along the actual nearest-body chain.
function effect.plan(ctx, caster)
    if targets.allied(ctx, caster) and
        senses.player_sees_actor(ctx, caster) then
        return nil
    end

    for _, victim in ipairs(actors.los(ctx,
        caster, SIGHT_RADIUS)) do
        if targets.enemy(ctx, caster, victim) then
            return self_target.plan(caster)
        end
    end

    return nil
end

-- Save only the self target; the source chooses its nearest live body when
-- the cast resolves, then recalculates each wave from the previous target.
function effect.resolve(ctx, caster, _, _, plan)
    self_target.require_caster(plan, caster)

    local spell_power = power.caster_power(ctx,
        caster, profile)
    local message

    if senses.player_sees_actor(ctx, caster) then
        message = "Lightning arcs from the " ..
            display.name(ctx, caster) .. "!"
    end

    area.resolve(ctx, caster, spell_power,
        profile, streams.MONSTER_SPELL, message)
end

return effect
