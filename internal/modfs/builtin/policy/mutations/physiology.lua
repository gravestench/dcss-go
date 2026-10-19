local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.species_flags")
local mutations = require("ids.mutations")
local species_ids = require("ids.species")
local records = require("policy.mutations.records")
local levels = require("policy.mutations.levels")
local traits = require("policy.character.traits")
local undead_states = require("constants.undead_states")

local physiology = {}

-- Source: player.cc:player::can_safely_mutate. Semi-undead species remain
-- eligible, while lifeless undead and lich form cannot safely mutate.
function physiology.can_safely_mutate(ctx, owner, temporary)
    local character = ctx:get(owner, component.PLAYER)

    if not character then
        error("mutation physiology requires a player")
    end

    local species = catalog.get("species", character.species_id)
    local form = ctx:get(owner, component.PLAYER_FORM)

    local living = species.undead_type == undead_states.ALIVE or
        species.undead_type == undead_states.SEMI_UNDEAD

    return living and not (temporary ~= false and form and
        form.form_id == "lich")
end

local body_facets = {
    { mutations.MUT_HORNS, mutations.MUT_ANTENNAE },
    { mutations.MUT_CLAWS, mutations.MUT_DEMONIC_TOUCH },
    { mutations.MUT_HOOVES },
    { mutations.MUT_WEAKNESS_STINGER },
}

local demonspawn_scales = {
    mutations.MUT_DISTORTION_FIELD,
    mutations.MUT_ICY_BLUE_SCALES,
    mutations.MUT_LARGE_BONE_PLATES,
    mutations.MUT_MOLTEN_SCALES,
    mutations.MUT_RUGGED_BROWN_SCALES,
    mutations.MUT_SLIMY_GREEN_SCALES,
    mutations.MUT_THIN_METALLIC_SCALES,
    mutations.MUT_THIN_SKELETAL_STRUCTURE,
    mutations.MUT_YELLOW_SCALES,
    mutations.MUT_STURDY_FRAME,
    mutations.MUT_SANGUINE_ARMOUR,
    mutations.MUT_BIG_BRAIN,
    mutations.MUT_SHARP_SCALES,
}

-- Treat absent species flag lists as empty when applying body restrictions.
local function has_flag(species, wanted)
    for _, flag in ipairs(species.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Distinguish an inherited body facet from the same acquired mutation rank.
local function innate(ctx, owner, id)
    local entry = records.find(ctx, owner, id)

    return entry and entry.state.innate > 0 or false
end

-- Accept draconian ancestry or a saved tail mutation before allowing a Stinger grant.
local function has_tail(ctx, owner, species)
    return species.id:find("^SP_.*DRACONIAN") ~= nil or
        levels.base(ctx, owner, mutations.MUT_CONSTRICTING_TAIL) > 0 or
        levels.base(ctx, owner, mutations.MUT_ARMOURED_TAIL) > 0 or
        levels.base(ctx, owner, mutations.MUT_STINGER) > 0 or
        levels.base(ctx, owner, mutations.MUT_WEAKNESS_STINGER) > 0
end

-- Only innate tail, float, paws, or tentacles remove the foot anatomy needed by Hooves.
local function has_feet(ctx, owner)
    return not innate(ctx, owner, mutations.MUT_CONSTRICTING_TAIL) and
        not innate(ctx, owner, mutations.MUT_FLOAT) and
        not innate(ctx, owner, mutations.MUT_PAWS) and
        not innate(ctx, owner, mutations.MUT_TENTACLE_ARMS)
end

-- Reject another member of a mutually exclusive body group before a rank is recorded.
local function body_facet_conflict(ctx, owner, id)
    for _, group in ipairs(body_facets) do
        for _, member in ipairs(group) do
            if member == id then
                for _, other in ipairs(group) do
                    if other ~= id and levels.base(ctx, owner, other) > 0 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

-- Example: a species with incompatible body facets rejects a mutation before it can be recorded.
-- Source: mutation.cc:physiology_mutation_conflict. This checks the body
-- before weighted selection accepts a mutation and before direct grants.
function physiology.permitted(ctx, owner, id)
    local character = ctx:get(owner, component.PLAYER)

    if not character then
        error("mutation physiology requires a player")
    end

    local species = catalog.get("species", character.species_id)
    local draconian = species.id:find("^SP_.*DRACONIAN") ~= nil

    if id == mutations.MUT_IRIDESCENT_SCALES then
        if draconian then
            return false
        end

        if species.id == species_ids.SP_DEMONSPAWN then
            for _, scale in ipairs(demonspawn_scales) do
                if levels.base(ctx, owner, scale) > 0 then
                    return false
                end
            end
        end
    end

    if id == mutations.MUT_STINGER and
        (not has_tail(ctx, owner, species) or
            innate(ctx, owner, mutations.MUT_MERTAIL) or
            levels.base(ctx, owner, mutations.MUT_WEAKNESS_STINGER) > 0) then
        return false
    end

    if id == mutations.MUT_TENTACLE_SPIKE and
        not innate(ctx, owner, mutations.MUT_TENTACLE_ARMS) then
        return false
    end

    if has_flag(species, flags.NO_BONES) and
        (id == mutations.MUT_THIN_SKELETAL_STRUCTURE or
            id == mutations.MUT_HORNS) then
        return false
    end

    if (id == mutations.MUT_HOOVES or id == mutations.MUT_TALONS) and
        (not has_feet(ctx, owner) or
            innate(ctx, owner, mutations.MUT_MERTAIL)) then
        return false
    end

    if (id == mutations.MUT_SPIT_POISON or id == mutations.MUT_ROLL) and
        not innate(ctx, owner, id) then
        return false
    end

    if id == mutations.MUT_BIG_WINGS and not draconian and
        species.id ~= species_ids.SP_GARGOYLE then
        return false
    end

    if levels.base(ctx, owner, mutations.MUT_VAMPIRISM) > 0 and
        (id == mutations.MUT_REGENERATION or
            id == mutations.MUT_INHIBITED_REGENERATION) then
        return false
    end

    if id == mutations.MUT_CLAWS and
        (innate(ctx, owner, mutations.MUT_PAWS) or
            innate(ctx, owner, mutations.MUT_TENTACLE_ARMS)) then
        return false
    end

    if traits.stasis(species) and
        (id == mutations.MUT_BERSERK or id == mutations.MUT_TELEPORT) then
        return false
    end

    if id == mutations.MUT_ACUTE_VISION and
        innate(ctx, owner, mutations.MUT_ACUTE_VISION) then
        return false
    end

    if id == mutations.MUT_POISON_RESISTANCE and
        (species.undead_type == "US_UNDEAD" or
            species.id == species_ids.SP_GARGOYLE) then
        return false
    end

    if (id == mutations.MUT_DEFORMED or id == mutations.MUT_STURDY_FRAME) and
        not species.aptitudes.SK_ARMOUR.allowed then
        return false
    end

    return not body_facet_conflict(ctx, owner, id)
end

return physiology
