-- Starting item and spell usability derives from the species definition.
-- Fake mutations such as Formicid stasis are gameplay rules, not HUD text.
local traits = {}

function traits.mutation_level(species, id)
    local level = 0

    for _, mutation in ipairs(species.mutations or {}) do
        if mutation.id == id and mutation.level <= 1 then
            level = level + mutation.amount
        end
    end

    return level
end

function traits.stasis(species)
    if traits.mutation_level(species, "MUT_STASIS") > 0 then
        return true
    end

    for _, mutation in ipairs(species.fake_mutations or {}) do
        if mutation.short == "permanent stasis" then
            return true
        end
    end

    return false
end

function traits.start_spell_usable(species, spell_id)
    if traits.stasis(species) and
        (spell_id == "SPELL_BLINK" or spell_id == "SPELL_TELEPORT_SELF" or
            spell_id == "SPELL_SWIFTNESS") then
        return false
    end

    local forms = {
        SPELL_STATUE_FORM = true,
        SPELL_BEASTLY_APPENDAGE = true,
        SPELL_BLADE_HANDS = true,
        SPELL_DRAGON_FORM = true,
        SPELL_ICE_FORM = true,
        SPELL_STORM_FORM = true,
        SPELL_SPIDER_FORM = true,
        SPELL_WEREBLOOD = true,
    }

    if forms[spell_id] and species.undead_type == "US_UNDEAD" then
        return false
    end

    if spell_id == "SPELL_STATUE_FORM" and species.id == "SP_GARGOYLE" then
        return false
    end

    if spell_id == "SPELL_PORTAL_PROJECTILE" and
        traits.mutation_level(species, "MUT_NO_GRASPING") > 0 then
        return false
    end

    if (spell_id == "SPELL_BORGNJORS_REVIVIFICATION" or
        spell_id == "SPELL_DEATHS_DOOR" or
        spell_id == "SPELL_NECROMUTATION") and
        species.undead_type == "US_UNDEAD" then
        return false
    end

    return true
end

return traits
