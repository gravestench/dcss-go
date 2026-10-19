-- Example: A species that cannot use a starting spell is rejected before its gift is added.
-- Starting item and spell usability derives from the species definition.
-- Fake mutations such as Formicid stasis are gameplay rules, not HUD text.
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local species_traits = require("policy.character.species_traits")

local traits = {}

traits.stasis = species_traits.stasis

-- Starting spell legality uses species form and mutation restrictions before a spell record is granted.
function traits.start_spell_usable(ctx, player, species, spell_id)
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
        mutation_levels.effective(ctx, player,
            mutations.MUT_NO_GRASPING) > 0 then
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
