-- Waterstrike hits one visible foe without a projectile ray. Drowning
-- resistance protects part of the water damage before armour is rolled.
local catalog = require("policy.catalog")
local component = require("constants.component")
local direct = require("policy.combat.monster_direct")
local flight = require("policy.combat.flight")
local monster_stats = require("policy.combat.monster_stats")
local roll = require("policy.combat.roll")
local spells = require("ids.spells")
local water = require("policy.combat.monster_beams.water")
local senses = require("policy.character.senses")

local effect = {}

-- Water can rise directly at a visible actor within LOS range.
function effect.plan(ctx, caster, foe)
    return direct.plan(ctx, caster, foe, spells.SPELL_WATERSTRIKE)
end

-- Source waterstrike_damage is 3d(7 + spell HD), followed by drowning
-- resistance and AC. Example: an unbreathing monster keeps impact damage.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    local actor = ctx:get(caster, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.spell_hit_dice(ctx, caster, definition)
    local raw = 0

    for _ = 1, 3 do
        raw = raw + 1 + roll.spell(ctx, 7 + hd)
    end

    local resisted = water.damage(ctx, foe, raw)
    local amount = direct.armour(ctx, foe, resisted)

    direct.damage(ctx, caster, foe, amount)
    local motion = flight.active(ctx, foe) and "rises up" or "swirls"

    -- Water motion only enters the log when its victim is observable.
    if ctx:has(foe, component.PLAYER) or
        senses.player_sees_actor(ctx, foe) then
        ctx:emit("spell", "The water " .. motion ..
            " and strikes the target!")
    end
end

return effect
