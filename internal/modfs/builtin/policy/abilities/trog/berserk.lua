-- Trog's one-star ability enters the same player Berserk state as a
-- potion. Trog changes the divine gate and cost, not the rage mechanics.
local abilities = require("ids.abilities")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local equipment = require("policy.inventory.equipment")
local identification = require("policy.items.identification")
local object_classes = require("ids.object_classes")
local skills = require("ids.skills")
local rage = require("policy.character.rage")
local registry = require("policy.abilities.registry")
local streams = require("constants.rng_streams")

local berserk = {}

-- A stale menu entry cannot bypass worship, penance, or rage exhaustion.
function berserk.available(ctx, player)
    return costs.available(ctx, player, gods.TROG, 1) and
        rage.can_begin(ctx, player, true, false)
end

-- All eligibility is free and must be checked before the timed intent.
function berserk.prepare(ctx, player, input)
    if not berserk.available(ctx, player) then
        return "You cannot go berserk right now."
    end

    -- Launchers and other non-melee wielded items must be confirmed before
    -- rage prevents a free weapon change. Replayed approval commits the turn.
    local weapon = equipment.in_slot(ctx, player, "weapon")
    local item = weapon and ctx:get(weapon, component.ITEM)
    local kind = item and catalog.get(categories.ITEMS, item.kind_id)

    if kind and (kind.class ~= object_classes.OBJ_WEAPONS or
        not kind.weapon or
        kind.weapon.skill_id == skills.SK_RANGED_WEAPONS) and
        not input.forced then
        return {
            confirmation = "Do you really want to go berserk while wielding " ..
                identification.name(ctx, player, weapon) .. "?",
        }
    end

    return nil
end

-- The source failure consumes a turn without piety. A successful power
-- starts ordinary rage, then pays Trog's one-point generic piety cost.
function berserk.resolve(ctx, player)
    if costs.failed(ctx, player, 45, 0, 2) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    if not rage.begin(ctx, player, streams.RELIGION, true, false) then
        return
    end

    costs.spend(ctx, player, 0, costs.piety_cost(ctx, 1))
end

registry.add(abilities.TROG_BERSERK, {
    name = "Berserk",
    available = berserk.available,
    prepare = berserk.prepare,
    resolve = berserk.resolve,
})

return berserk
