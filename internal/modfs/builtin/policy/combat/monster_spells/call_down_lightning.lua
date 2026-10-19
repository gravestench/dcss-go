-- Call Down Lightning places an ordinary electrical bolt at a distant
-- visible foe. It crosses no intervening cells, yet the target may dodge.
-- Source: mon-cast.cc:_foe_not_nearby and _cast_call_down_lightning.
local calculators = require("policy.combat.monster_beams.calculators")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local contact = require("policy.combat.monster_beams.contact")
local direct = require("policy.combat.monster_direct")
local power = require("policy.combat.monster_beams.power")
local spells = require("ids.spells")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_CALL_DOWN_LIGHTNING)
local MIN_DISTANCE = 3
local SIGHT_RADIUS = 7

-- The source declines this spell against a nearby or wall-hidden foe.
-- Keeping this check in planning avoids consuming a turn or RNG for a cast
-- that cannot help the monster.
function effect.plan(ctx, caster, foe)
    local source = ctx:get(caster, component.POSITION)
    local destination = foe and ctx:get(foe, component.POSITION)

    if not source or not destination or
        source.level_id ~= destination.level_id then
        return nil
    end

    local distance = math.max(math.abs(destination.x - source.x),
        math.abs(destination.y - source.y))

    if distance < MIN_DISTANCE or
        not ctx:visible_no_trans(source.level_id,
            source.x, source.y, SIGHT_RADIUS,
            destination.x, destination.y) then
        return nil
    end

    return direct.plan(ctx, caster, foe,
        spells.SPELL_CALL_DOWN_LIGHTNING)
end

-- The source beam begins and ends at the foe's cell. One contact uses the
-- existing zap dice, evasion, resistance, armour, and attributed HP owners.
function effect.resolve(ctx, caster, foe, _, plan)
    direct.require(ctx, caster, foe, plan)

    local spell_power = power.caster_power(ctx, caster, profile)
    local to_hit = calculators.to_hit(profile, spell_power)

    return contact.resolve(ctx, caster, foe,
        profile, spell_power, to_hit)
end

return effect
