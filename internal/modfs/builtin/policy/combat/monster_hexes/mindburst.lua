local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local component = require("constants.component")
local damage = require("policy.combat.monster_hexes.damage")
local intelligence = require("constants.monster_intelligence")
local power = require("policy.combat.monster_beams.power")

local mindburst = {}

function mindburst.viable(ctx, _, defender)
    if ctx:has(defender, component.PLAYER) then
        return true
    end

    local actor = ctx:get(defender, component.ACTOR)
    local definition = catalog.get("monsters", actor.kind_id)

    return definition.intelligence_id ~= intelligence.BRAINLESS
end

-- Source: zap-data.h:ZAP_MINDBURST rolls one monster damage die.
function mindburst.amount(ctx, caster, _, profile)
    local caster_power = power.caster_power(ctx, caster, profile)
    local dice = calculators.damage_dice(ctx, profile, caster_power)

    return calculators.roll_damage(ctx, dice)
end

function mindburst.apply(ctx, caster, defender, profile)
    local amount = mindburst.amount(ctx, caster, defender, profile)

    damage.apply(ctx, caster, defender, amount)
end

return mindburst
