-- A monster's sight is a property of its live body and worn items. The
-- catalog supplies innate sight, while equipment can change the next AI
-- or spell-targeting decision without mutating that shared definition.
local armour_egos = require("constants.armour_egos")
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local artefact_ids = require("ids.artefact_properties")
local item_ids = require("ids.items")
local object_classes = require("ids.object_classes")
local equipment = require("policy.combat.equipment")
local draconian_base = require("policy.monsters.draconian_base")
local beast_facets = require("policy.monsters.mutant_beast.facets")

local senses = {}

-- Catalog and colored-base flags express innate sight. A positive flag
-- ends the search before we need to inspect the monster's current gear.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Ghost-like player illusions snapshot their creator's sight. Other
-- monsters combine class, colored base, artefact, ring, and armour sight.
function senses.see_invisible(ctx, monster, definition)
    local illusion = ctx:get(monster, component.PLAYER_ILLUSION)

    if illusion then
        return illusion.see_invisible
    end

    if has_flag(definition, flags.SEE_INVISIBLE) then
        return true
    end

    if beast_facets.has(ctx, monster, beast_facets.WEIRD) then
        return true
    end

    if draconian_base.is_job(definition.id) then
        local saved = ctx:get(monster,
            component.MONSTER_DRACONIAN_BASE)
        local base_id = draconian_base.for_job(definition.id,
            saved and saved.base_id)
        local color = catalog.get("monsters", base_id)

        if has_flag(color, flags.SEE_INVISIBLE) then
            return true
        end
    end

    if equipment.monster_artefact_value(ctx, monster,
        definition, artefact_ids.SEE_INVISIBLE) > 0 then
        return true
    end

    local worn = equipment.worn(ctx, monster, {
        body = true,
        shield = true,
        jewellery = true,
    })

    for _, slot in ipairs({ "body", "shield" }) do
        local entry = worn[slot]

        if entry and entry.definition.class ==
            object_classes.OBJ_ARMOUR and
            entry.ego == armour_egos.SEE_INVISIBLE then
            return true
        end
    end

    local ring = worn.jewellery

    return ring ~= nil and ring.definition.class ==
        object_classes.OBJ_JEWELLERY and
        ring.item.kind_id == item_ids.RING_SEE_INVISIBLE
end

return senses
