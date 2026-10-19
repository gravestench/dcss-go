local catalog = require("policy.catalog")
local component = require("constants.component")
local enchantment = require("policy.combat.monster_spells.hex")
local monster_antimagic = require(
    "policy.magic.effects.statuses.enfeeble")
local monsters = require("ids.monsters")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")

local drain = {}

local function heal_ghost_moth(ctx, caster, amount)
    local actor = ctx:get(caster, component.ACTOR)

    if not actor or actor.kind_id ~= monsters.MONS_GHOST_MOTH or
        amount <= 0 then
        return
    end

    local health = ctx:get(caster, component.HEALTH)

    if health then
        health.current = math.min(health.maximum,
            health.current + amount)
        ctx:set(caster, component.HEALTH, health)
    end
end

-- Source: beam.cc:BEAM_DRAIN_MAGIC. Only drained MP or a monster's
-- antimagic duration heals the ghost moth caster.
function drain.apply(ctx, caster, defender, profile)
    local power = enchantment.enchantment_power(ctx, caster, profile)

    if ctx:has(defender, component.PLAYER) then
        local magic = ctx:get(defender, component.MAGIC)
        local upper = math.floor(power / 8)
        local amount = math.min(magic.current,
            roll.average_three(ctx, streams.MONSTER_SPELL, upper))

        if amount <= 0 then
            return
        end

        magic.current = magic.current - amount
        ctx:set(defender, component.MAGIC, magic)
        heal_ghost_moth(ctx, caster, amount)
        ctx:emit("combat", "You feel your power leaking away.")

        return
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local duration = monster_antimagic.apply_drain_magic(ctx, defender,
        definition, power)

    heal_ghost_moth(ctx, caster, math.floor(duration / 10))
end

return drain
