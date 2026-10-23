-- Theory of operation: DES `useful` is a filter on a rolled item, not a
-- quality tier. A candidate that the live character cannot use is omitted
-- from the vault, as source item placement does after its usefulness check.
-- This owner uses existing equipment and mutation rules so new species and
-- item definitions follow those policies instead of a Trove-only list.
-- Example: `any armour useful good_item` may yield no item for a Felid
-- when its rolled armour cannot be worn; the source ITEM record remains.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local gods = require("constants.gods")
local ids = require("ids.items")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local species_ids = require("ids.species")

local usefulness = {}

-- This is the portable subset of source `is_useless_item`: anatomy,
-- artifice, spellbooks, and potion restrictions. Unknown item classes
-- remain eligible until their domain supplies a more specific rule.
function usefulness.eligible(ctx, player, rolled)
    local kind = catalog.get("items", rolled.kind_id)
    local character = ctx:get(player, component.PLAYER)
    local species = catalog.get("species", character.species_id)

    if kind.class == classes.OBJ_ARMOUR then
        return equipment.can_wear(ctx, player, species, kind)
    end

    if kind.class == classes.OBJ_WEAPONS then
        return equipment.can_wield(ctx, player, species, kind) and
            equipment.weapon_supported(kind.weapon.skill_id)
    end

    local no_grasp = mutation_levels.effective(ctx, player,
        mutations.MUT_NO_GRASPING) > 0
    local no_artifice = mutation_levels.effective(ctx, player,
        mutations.MUT_NO_ARTIFICE) > 0

    if kind.class == classes.OBJ_MISSILES then
        return not no_grasp
    end

    if kind.class == classes.OBJ_WANDS or
        kind.class == classes.OBJ_MISCELLANY then
        return not no_artifice
    end

    if kind.class == classes.OBJ_POTIONS then
        if character.species_id == species_ids.SP_MUMMY then
            return false
        end

        if kind.id == ids.POT_HEAL_WOUNDS and
            character.species_id == species_ids.SP_VINE_STALKER then
            return false
        end

        if kind.id == ids.POT_HASTE and
            character.species_id == species_ids.SP_FORMICID then
            return false
        end
    end

    if kind.class == classes.OBJ_BOOKS and
        kind.id ~= ids.BOOK_MANUAL then
        local worship = ctx:get(player, component.RELIGION_WORSHIP)

        if worship and worship.god_id == gods.TROG then
            return false
        end
    end

    return true
end

return usefulness
