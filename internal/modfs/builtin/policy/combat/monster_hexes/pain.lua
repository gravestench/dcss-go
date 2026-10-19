local calculators = require("policy.combat.monster_beams.calculators")
local component = require("constants.component")
local damage = require("policy.combat.monster_hexes.damage")
local enchantment = require("policy.combat.monster_beams.power")
local magic_damage = require("policy.magic.damage")
local resistances = require("constants.resistance_ids")
local agony = require("policy.combat.monster_hexes.agony")

local pain = {}

pain.viable = agony.viable

-- Source: zap-data.h:ZAP_PAIN and fight.cc:resist_adjust_damage.
function pain.amount(ctx, caster, defender, profile)
    local power = enchantment.caster_power(ctx, caster, profile)
    local dice = calculators.damage_dice(ctx, profile, power)
    local raw = calculators.roll_damage(ctx, dice)

    if ctx:has(defender, component.PLAYER) then
        return magic_damage.player_elemental(ctx, defender, raw,
            resistances.NEGATIVE_ENERGY)
    end

    return magic_damage.monster_elemental(ctx, defender, raw,
        resistances.NEGATIVE_ENERGY)
end

function pain.apply(ctx, caster, defender, profile)
    local amount = pain.amount(ctx, caster, defender, profile)

    damage.apply(ctx, caster, defender, amount)
end

return pain
