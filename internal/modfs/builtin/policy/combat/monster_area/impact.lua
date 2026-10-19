-- Area spells roll one impact per live victim. Keep armour, beam flavour,
-- and attributed HP loss in their existing owners so each spell file can
-- describe its source dice and secondary cell effect clearly.
-- Source: beam.cc:bolt::apply_AC and bolt::affect_actor.
-- Example: a rubble hit rolls AC three times before the fragment damage
-- reaches the monster or player health owner.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local beam_damage = require("policy.combat.monster_beams.damage")
local direct = require("policy.combat.monster_direct")
local fighter = require("policy.combat.fighter")
local monster_defense = require("policy.combat.monster_defense")

local impact = {}

-- Read current equipment after earlier area contacts may have broken it.
-- This is live defence, not a species-only catalog value.
local function armour(ctx, victim)
    if ctx:has(victim, component.PLAYER) then
        return fighter.defense(ctx).ac
    end

    local state = ctx:get(victim, component.ACTOR)
    local definition = catalog.get(categories.MONSTERS,
        state.kind_id)

    return monster_defense.armour(ctx, victim, definition)
end

-- The profile's flavour decides source AC and resistance treatment;
-- health owners receive only the final positive amount with caster credit.
function impact.hit(ctx, caster, victim, raw, profile)
    local after_ac = beam_damage.armour(ctx, raw,
        armour(ctx, victim), profile)
    local amount = beam_damage.resisted(ctx, victim,
        after_ac, profile)

    if amount > 0 then
        direct.damage(ctx, caster, victim, amount)
    end

    return amount
end

return impact
