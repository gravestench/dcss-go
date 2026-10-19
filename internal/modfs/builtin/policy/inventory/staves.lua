local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local roll = require("policy.combat.roll")

local staves = {}

-- Reuse the ordinary staff melee profile after validating modded staff
-- metadata; this avoids copying weapon rules into every magical staff file.
-- Example: staves.weapon(staff_definition) returns its attack profile.
function staves.weapon(definition)
    if definition.class ~= object_classes.OBJ_STAVES then
        if definition.class == object_classes.OBJ_WEAPONS then
            return definition.weapon
        end

        return nil
    end

    local staff = definition.staff

    if definition.slot ~= "weapon" or
        type(staff) ~= "table" or
        type(staff.school) ~= "string" or staff.school == "" or
        type(staff.skill_id) ~= "string" or staff.skill_id == "" or
        type(staff.message) ~= "string" or staff.message == "" or
        (not staff.resistance_id and not staff.ac_rolls) then
        error("staff " .. definition.id .. " lacks melee rules")
    end

    if staff.resistance_id and staff.ac_rolls then
        error("staff " .. definition.id .. " mixes resistance and armour")
    end

    if staff.resistance_id and type(staff.resistance_id) ~= "string" then
        error("staff " .. definition.id .. " has invalid resistance")
    end

    if staff.ac_rolls and
        (type(staff.ac_rolls) ~= "number" or
            staff.ac_rolls < 1 or staff.ac_rolls > 3) then
        error("staff " .. definition.id .. " has invalid armour rule")
    end

    if staff.damage_denominator and
        staff.damage_denominator <= 0 then
        error("staff " .. definition.id .. " has invalid damage rules")
    end

    return catalog.get(categories.ITEMS, item_ids.WPN_STAFF).weapon
end

-- A staff enhances a spell only when one of that spell's schools matches
-- the staff's declared school, so dual-school spells need no special list.
function staves.enhances(definition, spell)
    local staff = definition.staff

    if not staff then
        return 0
    end

    for _, school in ipairs(spell.schools) do
        if school == staff.school then
            return 1
        end
    end

    return 0
end

-- Grant the staff's one-step resistance only for its declared element;
-- non-staff weapons never inherit this metadata by accident.
function staves.resistance(definition, resistance_id)
    if definition.class ~= object_classes.OBJ_STAVES or
        not definition.staff then
        return 0
    end

    return definition.staff.resistance_id == resistance_id and 1 or 0
end

-- Source: melee-attack.cc. The two skill scales are deliberate.
-- First roll determines whether the proc fires, then a separate roll sets
-- damage. Both use the melee RNG stream to preserve combat sequencing.
function staves.roll_damage(ctx, school100, evocations200, evocations50)
    if roll.melee(ctx, 3000) >= evocations200 + school100 then
        return 0
    end

    local bound = math.floor((school100 + evocations50) / 80)

    return roll.melee(ctx, bound)
end

return staves
