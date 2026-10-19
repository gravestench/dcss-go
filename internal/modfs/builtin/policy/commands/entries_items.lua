local commands = require("policy.input.commands")
local equipment = require("policy.inventory.equipment")
local items = require("policy.inventory.items")
local projectiles = require("policy.commands.projectiles")
local quaff = require("policy.commands.quaff")
local registry = require("policy.commands.registry")
local wands = require("policy.inventory.wands")
local jewellery = require("policy.inventory.jewellery")
local classes = require("ids.object_classes")

local entries = {}

-- These entries bind item command IDs to preparation functions used by the command dispatcher.
-- Example: entries.quaff(ctx, player, { item_id = potion_id }) prepares a potion use command.
function entries.quaff(ctx, player, input)
    return quaff.prepare(ctx, player, input.item_id or 0, input.forced)
end

-- Reject inventory changes before dispatch builds a timed drop intent.
function entries.drop(ctx, player, input)
    return items.prepare_drop(ctx, player, input.item_id or 0,
        input.quantity or 0)
end

-- Prepare a weapon swap through equipment delay so action time is charged once.
function entries.wield(ctx, player, input)
    return equipment.prepare_wield(ctx, player, input.item_id or 0)
end

-- Check armour slot and restrictions before starting a wear delay.
function entries.wear(ctx, player, input)
    local entity = input.item_id and ctx:entity(input.item_id)
    local item = entity and ctx:get(entity, "core.item")

    if item and items.kind(item).class == classes.OBJ_JEWELLERY then
        return jewellery.prepare_put_on(ctx, player, input)
    end

    return equipment.prepare_armour(ctx, player, input.item_id or 0, false)
end

-- Route removal through the same delayed equipment state as wearing.
function entries.take_off(ctx, player, input)
    local entity = input.item_id and ctx:entity(input.item_id)
    local item = entity and ctx:get(entity, "core.item")

    if item and items.kind(item).class == classes.OBJ_JEWELLERY then
        return jewellery.prepare_remove(ctx, player, input)
    end

    return equipment.prepare_armour(ctx, player, input.item_id or 0, true)
end

-- Use the shared projectile preflight for the wielded launcher.
function entries.fire(ctx, player, input)
    return projectiles.prepare(ctx, player, true, input.item_id or 0,
        input.dx or 0, input.dy or 0)
end

-- Use the shared projectile preflight for a carried throwable.
function entries.throw(ctx, player, input)
    return projectiles.prepare(ctx, player, false, input.item_id or 0,
        input.dx or 0, input.dy or 0)
end

-- Validate a wand and target before its charge can be consumed.
function entries.evoke_wand(ctx, player, input)
    return wands.prepare(ctx, player, input.item_id or 0,
        input.dx or 0, input.dy or 0)
end

registry.register(commands.quaff, entries.quaff)
registry.register(commands.drop, entries.drop)
registry.register(commands.wield, entries.wield)
registry.register(commands.wear, entries.wear)
registry.register(commands.take_off, entries.take_off)
registry.register(commands.fire, entries.fire)
registry.register(commands.throw, entries.throw)
registry.register(commands.evoke_wand, entries.evoke_wand)

return entries
