local commands = require("policy.input.commands")
local equipment = require("policy.inventory.equipment")
local items = require("policy.inventory.items")
local projectiles = require("policy.commands.projectiles")
local quaff = require("policy.commands.quaff")
local registry = require("policy.commands.registry")
local wands = require("policy.inventory.wands")

local entries = {}

function entries.quaff(ctx, player, input)
    return quaff.prepare(ctx, player, input.item_id or 0, input.forced)
end

function entries.drop(ctx, player, input)
    return items.prepare_drop(ctx, player, input.item_id or 0,
        input.quantity or 0)
end

function entries.wield(ctx, player, input)
    return equipment.prepare_wield(ctx, player, input.item_id or 0)
end

function entries.wear(ctx, player, input)
    return equipment.prepare_armour(ctx, player, input.item_id or 0, false)
end

function entries.take_off(ctx, player, input)
    return equipment.prepare_armour(ctx, player, input.item_id or 0, true)
end

function entries.fire(ctx, player, input)
    return projectiles.prepare(ctx, player, true, input.item_id or 0,
        input.dx or 0, input.dy or 0)
end

function entries.throw(ctx, player, input)
    return projectiles.prepare(ctx, player, false, input.item_id or 0,
        input.dx or 0, input.dy or 0)
end

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
