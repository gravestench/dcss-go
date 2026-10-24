local catalog = require("policy.catalog")
local component = require("constants.component")
local forms = require("policy.magic.effects.forms.player")
local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")
local jewellery_effects = require("policy.inventory.jewellery_effects")
local jewellery_capabilities = require("constants.jewellery_capabilities")
local armour_egos = require("constants.armour_egos")
local artefact_ids = require("ids.artefact_properties")
local item_ids = require("ids.items")
local monster_flags = require("constants.monster_flags")
local object_classes = require("ids.object_classes")
local equipment = require("policy.combat.equipment")
local draconian_base = require("policy.monsters.draconian_base")
local beast_facets = require("policy.monsters.mutant_beast.facets")
local monster_ids = require("ids.monsters")

local flight = {}

-- Only these corpse-derived kinds borrow a base monster's movement traits.
-- A DES base on an unrelated monster must not grant that monster flight.
local derived_undead = {
    [monster_ids.MONS_ZOMBIE] = true,
    [monster_ids.MONS_SKELETON] = true,
    [monster_ids.MONS_SIMULACRUM] = true,
    [monster_ids.MONS_SPECTRAL_THING] = true,
    [monster_ids.MONS_BOUND_SOUL] = true,
}

-- Temporary flight from a potion or vortex is a single actor-owned timer.
-- The caster and displaced victims share this state rather than relying
-- on the vortex module to age only its own caster.
function flight.tick(ctx, actor, elapsed_aut)
    local state = ctx:get(actor, component.ZAP_FLIGHT)

    if not state or elapsed_aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0,
        state.remaining_aut - elapsed_aut)

    if state.remaining_aut == 0 then
        ctx:remove(actor, component.ZAP_FLIGHT)
    else
        ctx:set(actor, component.ZAP_FLIGHT, state)
    end
end

-- Form restrictions override innate and jewelry flight when deciding permanence.
function flight.permanent(ctx, player)
    return forms.modifiers(ctx, player).flight ~= "forbid" and
        (effects.sum(ctx, player, capabilities.PERMANENT_FLIGHT) > 0 or
            jewellery_effects.has(ctx, player,
                jewellery_capabilities.PERMANENT_FLIGHT))
end

-- Monster flight may come from catalog flags instead of a player status component.
local function has_flag(flags, wanted)
    for _, flag in ipairs(flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Example: flight.active(ctx, actor) with active flight form -> true while its duration lasts
-- Flight is a projection of saved actor state, never a second position type.
-- The player can fly through a spell duration or a form. A monster's
-- saved base, worn gear, and enchantment can change its current flight.
function flight.active(ctx, actor)
    local is_player = ctx:has(actor, component.PLAYER)

    if is_player then
        local form = forms.modifiers(ctx, actor).flight

        if form == "forbid" then
            return false
        end

        if form == "enable" then
            return true
        end

        if flight.permanent(ctx, actor) then
            return true
        end
    end

    local wind = ctx:get(actor, component.ZAP_FLIGHT)

    if wind and wind.remaining_aut > 0 then
        return true
    end

    if is_player then
        return false
    end

    local identity = ctx:get(actor, component.ACTOR)

    if not identity then
        return false
    end

    -- A random Pan lord owns this trait per actor. The shared habitat and
    -- flight rules must read its saved roll instead of the static species.
    local definition = catalog.get("monsters", identity.kind_id)

    if not definition then
        return false
    end

    local lord = ctx:get(actor, component.PANDEMONIUM_LORD)

    if (lord and lord.flies) or has_flag(definition.flags,
        monster_flags.FLIES) then
        return true
    end

    if beast_facets.has(ctx, actor, beast_facets.BAT) then
        return true
    end

    -- A draconian job borrows innate flight from its saved color while
    -- keeping the job's own speed, HD, and equipment.
    if draconian_base.is_job(identity.kind_id) then
        local saved = ctx:get(actor,
            component.MONSTER_DRACONIAN_BASE)
        local base_id = draconian_base.for_job(identity.kind_id,
            saved and saved.base_id)
        local color = catalog.get("monsters", base_id)

        if has_flag(color.flags, monster_flags.FLIES) then
            return true
        end
    end

    -- Source `mons_base_type` returns the corpse's species for derived
    -- undead; a flying dragon remains airborne after zombification.
    if derived_undead[definition.genus_id] or
        derived_undead[identity.kind_id] then
        local override = ctx:get(actor,
            component.VAULT_ACTOR_OVERRIDES)
        local base_id = override and override.base_id
        local base = base_id and base_id ~= "" and
            catalog.get("monsters", base_id)

        if base and has_flag(base.flags, monster_flags.FLIES) then
            return true
        end
    end

    local worn = equipment.worn(ctx, actor, {
        body = true,
        jewellery = true,
    })
    local body = worn.body

    if body and body.definition.class ==
        object_classes.OBJ_ARMOUR and
        body.ego == armour_egos.FLYING then
        return true
    end

    local ring = worn.jewellery

    if ring and ring.definition.class ==
        object_classes.OBJ_JEWELLERY and
        ring.item.kind_id == item_ids.RING_FLIGHT then
        return true
    end

    return equipment.monster_artefact_value(ctx, actor,
        definition, artefact_ids.FLY) > 0
end

-- Tengu's flight perk only applies while flight is active, regardless of its source.
function flight.tengu_perk(ctx, player)
    return flight.active(ctx, player) and
        effects.sum(ctx, player, capabilities.TENGU_FLIGHT_PERK) > 0
end

return flight
