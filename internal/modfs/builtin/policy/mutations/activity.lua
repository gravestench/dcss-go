local catalog = require("policy.catalog")
local forms = require("policy.magic.effects.forms.catalog")
local mutations = require("ids.mutations")
local component = require("constants.component")
local activity_levels = require("constants.mutation_activity")
local records = require("policy.mutations.records")
local water = require("policy.character.water")
local branches = require("ids.branches")
local species_ids = require("ids.species")
local species_traits = require("policy.character.species_traits")
local undead_states = require("constants.undead_states")

local activity = {}

local statue_inactive = {
    [mutations.MUT_GELATINOUS_BODY] = true,
    [mutations.MUT_TOUGH_SKIN] = true,
    [mutations.MUT_SHAGGY_FUR] = true,
    [mutations.MUT_FAST] = true,
    [mutations.MUT_SLOW] = true,
    [mutations.MUT_IRIDESCENT_SCALES] = true,
}

local statue_high_scales = {
    [mutations.MUT_YELLOW_SCALES] = true,
    [mutations.MUT_ICY_BLUE_SCALES] = true,
    [mutations.MUT_MOLTEN_SCALES] = true,
    [mutations.MUT_SLIMY_GREEN_SCALES] = true,
    [mutations.MUT_THIN_METALLIC_SCALES] = true,
}

local statue_partial = {
    [mutations.MUT_RUGGED_BROWN_SCALES] = true,
    [mutations.MUT_SHARP_SCALES] = true,
    [mutations.MUT_ROUGH_BLACK_SCALES] = true,
}

-- Source: species.cc:dragon_form and mutation.cc:mutation_activity_level.
-- The draconian's own dragon traits survive its matching Dragon Form.
local dragon_traits = {
    [species_ids.SP_BLACK_DRACONIAN] = {
        [mutations.MUT_SHOCK_RESISTANCE] = true,
    },
    [species_ids.SP_YELLOW_DRACONIAN] = {
        [mutations.MUT_ACIDIC_BITE] = true,
        [mutations.MUT_ACID_RESISTANCE] = true,
    },
    [species_ids.SP_GREEN_DRACONIAN] = {
        [mutations.MUT_STINGER] = true,
    },
    [species_ids.SP_PALE_DRACONIAN] = {
        [mutations.MUT_STEAM_RESISTANCE] = true,
    },
}

-- Return nil for a nonplayer owner so species-gated activity checks can use their fallback path.
local function origin_species(ctx, owner)
    local origin = ctx:get(owner, component.PLAYER)

    if not origin then
        return nil
    end

    return catalog.get("species", origin.species_id)
end

-- Lich form, undead species, and bloodless Vampire state all suppress living-only mutation effects.
local function lifeless(ctx, owner, form, species)
    if form and form.id == "lich" then
        return true
    end

    if species and species.undead_type == undead_states.UNDEAD then
        return true
    end

    local blood = ctx:get(owner, component.VAMPIRE)

    return blood ~= nil and not blood.alive
end

-- Species stasis and Abyss position suppress Teleport without deleting its recorded rank.
local function no_teleport(ctx, owner, species)
    if species and species_traits.stasis(species) then
        return true
    end

    local position = ctx:get(owner, component.POSITION)

    return position ~= nil and
        ctx:level_branch(position.level_id) == branches.BRANCH_ABYSS
end

-- Ignore expired form components; an unknown active form is corrupt state, not a normal fallback.
local function active_form(ctx, owner)
    local state = ctx:get(owner, component.PLAYER_FORM)

    if not state or state.remaining_aut <= 0 then
        return nil
    end

    for _, profile in pairs(forms) do
        if profile.id == state.form_id then
            return profile
        end
    end

    error("unknown player mutation form " .. state.form_id)
end

-- Example: a form can suppress a base mutation level while the saved record remains intact.
-- Source: mutation.cc:mutation_activity_level. The ordinary mutation query
-- accepts partial activity, which retains resistance but may suppress AC.
function activity.level(ctx, owner, mutation_id, base_level)
    if mutation_id == mutations.MUT_DEMONIC_GUARDIAN then
        local love = records.find(ctx, owner, mutations.MUT_NO_LOVE)

        if love then
            local state = love.state

            if state.innate + state.acquired + state.temporary > 0 then
                return activity_levels.INACTIVE
            end
        end
    end

    if mutation_id == mutations.MUT_NIMBLE_SWIMMER and
        not water.at(ctx, owner) then
        return activity_levels.INACTIVE
    end

    local form = active_form(ctx, owner)

    if mutation_id == mutations.MUT_SANGUINE_ARMOUR and
        form and not form.can_bleed then
        return activity_levels.INACTIVE
    end

    if mutation_id == mutations.MUT_BERSERK and
        lifeless(ctx, owner, form, origin_species(ctx, owner)) then
        return activity_levels.INACTIVE
    end

    if mutation_id == mutations.MUT_TELEPORT and
        no_teleport(ctx, owner, origin_species(ctx, owner)) then
        return activity_levels.INACTIVE
    end

    if not form then
        return activity_levels.FULL
    end

    if not form.keeps_mutations then
        if form.id == "dragon" then
            local species = origin_species(ctx, owner)
            local allowed = species and dragon_traits[species.id]

            if allowed and allowed[mutation_id] then
                return activity_levels.FULL
            end
        end

        if form.id == "bat" and mutation_id == mutations.MUT_FANGS then
            local vampirism = records.find(ctx, owner,
                mutations.MUT_VAMPIRISM)

            if vampirism and vampirism.state.innate > 0 then
                return activity_levels.FULL
            end
        end

        if mutation_id == mutations.MUT_RUGGED_BROWN_SCALES or
            mutation_id == mutations.MUT_ROUGH_BLACK_SCALES then
            return activity_levels.PARTIAL
        end

        local definition = catalog.get("mutations", mutation_id)

        if definition.form_based then
            return activity_levels.INACTIVE
        end
    end

    if form.id == "statue" then
        if statue_inactive[mutation_id] then
            return activity_levels.INACTIVE
        end

        if statue_partial[mutation_id] then
            return activity_levels.PARTIAL
        end

        if statue_high_scales[mutation_id] and base_level < 3 then
            return activity_levels.INACTIVE
        end

        if statue_high_scales[mutation_id] then
            return activity_levels.PARTIAL
        end
    end

    if form.id == "blade_hands" and mutation_id == mutations.MUT_PAWS then
        return activity_levels.INACTIVE
    end

    return activity_levels.FULL
end

return activity
