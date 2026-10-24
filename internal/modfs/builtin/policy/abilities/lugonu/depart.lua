-- Theory of operation: Lugonu's first power leaves the Abyss through the
-- same world transition as an exit portal. The saved return site belongs
-- to the Abyss owner, so this ability only checks worship, resources,
-- and the source invocation failure before asking that owner to escape.
local abilities = require("ids.abilities")
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local unsafe_move = require("policy.character.unsafe_move")

local depart = {}

-- The source offers this power at one star only while the player is
-- standing in the Abyss and remains in Lugonu's good graces.
function depart.available(ctx, player)
    local position = ctx:get(player, component.POSITION)

    return costs.available(ctx, player, gods.LUGONU, 1) and
        position ~= nil and position.level_id == abyss.level_id
end

-- An insufficient MP pool rejects before a timed intent is made.
function depart.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 1) then
        return "You do not have enough magic."
    end

    local warning = unsafe_move.warning(ctx, player)

    if warning and not input.forced then
        return { confirmation = warning }
    end

    return nil
end

-- A failed invocation uses the action without travel or payment.
-- Successful travel and its resource cost belong to one action barrier.
function depart.resolve(ctx, player)
    if costs.failed(ctx, player, 30, 6, 20) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    abyss.escape(ctx, player)
    unsafe_move.break_ice(ctx, player)
    costs.spend(ctx, player, 1, costs.piety_cost(ctx, 10))
end

registry.add(abilities.LUGONU_ABYSS_EXIT, {
    name = "Depart the Abyss",
    available = depart.available,
    confirmation_needed = function(ctx, player)
        return unsafe_move.warning(ctx, player) ~= nil
    end,
    confirmation_message = unsafe_move.warning,
    prepare = depart.prepare,
    resolve = depart.resolve,
})

return depart
