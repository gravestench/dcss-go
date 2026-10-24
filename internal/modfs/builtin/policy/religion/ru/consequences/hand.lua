-- Losing a hand changes legal equipment immediately. The mutation owner
-- removes Shields training; this owner handles the physical items that can
-- no longer be held or worn. Items remain carried after they are unequipped.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local items = require("policy.inventory.items")
local jewellery = require("policy.inventory.jewellery")
local slots = require("constants.jewellery_slots")
local species_ids = require("ids.species")
local effects = require("policy.inventory.jewellery_effects")
local capabilities = require("constants.jewellery_capabilities")
local resources = require("policy.character.resources")

local hand = {}

-- Capture the old magical-power bonus before the mutation makes the lost
-- ring slot unusable to ordinary jewellery queries.
function hand.before(ctx, player)
    return effects.sum(ctx, player, capabilities.MAX_MP)
end

-- Source sacrifices the left ring slot, or the last tentacle ring slot for
-- an Octopode. If another legal slot is empty, move the ring there.
local function release_ring(ctx, player, identity)
    local sacrificed = identity.species_id == species_ids.SP_OCTOPODE and
        slots.OCTO[#slots.OCTO] or slots.LEFT
    local ring = jewellery.in_slot(ctx, player, sacrificed)

    if not ring then
        return
    end

    ctx:remove(ring, component.EQUIPPED)

    for _, slot in ipairs(jewellery.ring_slots(ctx, player)) do
        if not jewellery.in_slot(ctx, player, slot) then
            ctx:add(ring, component.EQUIPPED, { slot = slot })

            return
        end
    end
end

-- Source unequips a shield and a newly impossible two-handed weapon, then
-- moves or removes the ring on the lost arm. The catalog decides weapon
-- handedness for this species rather than relying on item-name guesses.
function hand.apply(ctx, player, old_magic_bonus)
    local identity = ctx:get(player, component.PLAYER)
    local species = catalog.get(categories.SPECIES,
        identity.species_id)
    local shield = equipment.in_slot(ctx, player, "shield")

    if shield then
        ctx:remove(shield, component.EQUIPPED)
    end

    local weapon = equipment.in_slot(ctx, player, "weapon")

    if weapon then
        local item = ctx:get(weapon, component.ITEM)
        local kind = items.kind(item)

        if equipment.needs_second_hand(ctx, player, kind, species) then
            ctx:remove(weapon, component.EQUIPPED)
        end
    end

    release_ring(ctx, player, identity)

    if old_magic_bonus and
        effects.sum(ctx, player,
            capabilities.MAX_MP) ~= old_magic_bonus then
        resources.refresh_mp(ctx, player)
    end
end

return hand
