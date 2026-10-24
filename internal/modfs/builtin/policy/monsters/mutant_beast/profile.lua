-- A mutant beast's catalog entry is only its common body. Source tier and
-- facets live on the actor, so combat, defense, and AI need one projected
-- read view rather than private beast cases in each consumer.
local facets = require("policy.monsters.mutant_beast.facets")
local form_policy = require("policy.monsters.mutant_beast.form")
local attack_types = require("constants.monster_attack_types")
local attack_flavours = require("constants.attack_flavours")
local monster_flags = require("constants.monster_flags")
local resistances = require("constants.resistance_ids")
local spell_flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local profile = {}

local attack_facets = {
    [facets.STING] = {
        type_id = attack_types.STING,
        flavour_id = attack_flavours.REACH_STING,
    },
    [facets.OX] = {
        type_id = attack_types.TRAMPLE,
        flavour_id = attack_flavours.TRAMPLE,
    },
    [facets.WEIRD] = {
        type_id = attack_types.CONSTRICT,
        flavour_id = attack_flavours.CRUSH,
    },
}

local resistance_facets = {
    [facets.STING] = resistances.POISON,
    [facets.FIRE] = resistances.FIRE,
    [facets.SHOCK] = resistances.ELECTRICITY,
    [facets.OX] = resistances.COLD,
}

local spell_facets = {
    [facets.FIRE] = {
        spell_id = spells.SPELL_FIRE_BREATH,
        flags = {
            spell_flags.NATURAL,
            spell_flags.BREATH,
        },
    },
    [facets.SHOCK] = {
        spell_id = spells.SPELL_BLINKBOLT,
        flags = {
            spell_flags.NATURAL,
        },
    },
}

-- Bat multiplies speed once for each saved Bat facet, matching source
-- initialization. The actor stores this value for turn energy; projected
-- definitions expose the same value to observers and AI.
function profile.speed(base, form)
    local speed = base

    for _, facet in ipairs(form.facets) do
        if facet == facets.BAT then
            speed = speed * 2
        end
    end

    return speed
end

-- Project the first source hit and each attack-bearing facet in saved
-- order. Noncombat facets do not leave empty slots between contacts.
function profile.attacks(form)
    local rank = form_policy.rank(form.tier)
    local attacks = {
        {
            type_id = attack_types.HIT,
            flavour_id = attack_flavours.PLAIN,
            damage = rank * 7 + 5,
        },
    }

    for _, facet in ipairs(form.facets) do
        local source = attack_facets[facet]

        if source then
            attacks[#attacks + 1] = {
                type_id = source.type_id,
                flavour_id = source.flavour_id,
                damage = rank * 5,
            }
        end
    end

    return attacks
end

-- A source facet contributes one intrinsic resistance level; the generic
-- resistance owner still applies gear, timed status, and elemental caps.
function profile.project(definition, form)
    -- A defense caller may pass an already projected profile back through
    -- the generic owner. Reuse its intrinsic values rather than adding
    -- Ox armour or facet resistances a second time.
    if definition._mutant_beast_projected then
        return definition
    end

    local current = {}

    for key, value in pairs(definition) do
        current[key] = value
    end

    current.attacks = profile.attacks(form)
    current._mutant_beast_projected = true
    current.ac = definition.ac +
        (facets.contains(form, facets.OX) and 5 or 0)
    current.speed = profile.speed(definition.speed, form)
    current.flags = {}
    current.resistances = {}

    for _, flag in ipairs(definition.flags or {}) do
        current.flags[#current.flags + 1] = flag
    end

    if facets.contains(form, facets.BAT) then
        current.flags[#current.flags + 1] = monster_flags.BATTY
    end

    for _, entry in ipairs(definition.resistances or {}) do
        current.resistances[#current.resistances + 1] = entry
    end

    for _, facet in ipairs(form.facets) do
        local id = resistance_facets[facet]

        if id then
            current.resistances[#current.resistances + 1] = {
                id = id,
                level = 1,
            }
        end
    end

    return current
end

-- Source Fire and Shock facets append frequency-60 natural spell slots.
-- Returning ordinary slot records keeps AI prospect and casting generic.
function profile.spellbook(form)
    local slots = {}

    for _, facet in ipairs(form.facets) do
        local spell = spell_facets[facet]

        if spell then
            slots[#slots + 1] = {
                spell_id = spell.spell_id,
                frequency = 60,
                flags = spell.flags,
            }
        end
    end

    return #slots > 0 and { slots = slots } or nil
end

return profile
