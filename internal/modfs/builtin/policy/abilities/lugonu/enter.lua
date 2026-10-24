-- Theory of operation: Lugonu opens an Abyss visit from the player's
-- current floor cell. The Abyss owner creates the region and keeps that
-- exact return site; this ability owns rank, failure, HP deflation,
-- and the source MP and piety costs.
local abilities = require("ids.abilities")
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local unsafe_move = require("policy.character.unsafe_move")

local enter = {}

-- The fifth-star gate disappears inside the Abyss, where Depart has
-- the opposite direction and source Enter cannot be used.
function enter.available(ctx, player)
    local position = ctx:get(player, component.POSITION)

    return costs.available(ctx, player, gods.LUGONU, 5) and
        position ~= nil and position.level_id ~= abyss.level_id
end

-- Lack of MP rejects for free before the player starts a timed action.
function enter.prepare(ctx, player, input)
    if not costs.enough_magic(ctx, player, 10) then
        return "You do not have enough magic."
    end

    local warning = unsafe_move.warning(ctx, player)

    if warning and not input.forced then
        return { confirmation = warning }
    end

    return nil
end

-- Source random2avg(current HP, 2) reduces HP before banishment, but
-- its maximum result leaves at least one HP. This direct dec_hp-style
-- change does not pretend that a hostile attack hit the player.
function enter.resolve(ctx, player)
    if costs.failed(ctx, player, 80, 4, 25) then
        ctx:emit("religion", "You fail to use your ability.")

        return
    end

    local health = ctx:get(player, component.HEALTH)
    local loss = roll.average_two(ctx, streams.RELIGION,
        health.current)
    local position = ctx:get(player, component.POSITION)
    local site = {
        level_id = position.level_id,
        x = position.x,
        y = position.y,
    }

    health.current = health.current - loss
    ctx:set(player, component.HEALTH, health)
    abyss.enter(ctx, player, site)
    unsafe_move.break_ice(ctx, player)
    costs.spend(ctx, player, 10, costs.piety_cost(ctx, 28))
    ctx:emit("religion", "You enter the Abyss!")
end

registry.add(abilities.LUGONU_ABYSS_ENTER, {
    name = "Enter the Abyss",
    available = enter.available,
    confirmation_needed = function(ctx, player)
        return unsafe_move.warning(ctx, player) ~= nil
    end,
    confirmation_message = unsafe_move.warning,
    prepare = enter.prepare,
    resolve = enter.resolve,
})

return enter
