-- Theory of operation: Kiku invokes the existing Torment area effect around
-- the player. The source tag lets the resistance owner grant Kiku's partial
-- self protection, while ordinary LOS and monster resistance remain shared.
local abilities = require("ids.abilities")
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local costs = require("policy.abilities.god_costs")
local gods = require("constants.gods")
local kiku = require("constants.kikubaaqudgha")
local registry = require("policy.abilities.registry")
local sources = require("constants.torment_sources")
local spell_range = require("constants.spell_range")

local torment = {}

-- Source grants Torment at five piety stars. Worship, penance, and silence
-- are checked at both menu display and resolution by the shared registry.
function torment.available(ctx, player)
    return costs.available(ctx, player, gods.KIKUBAAQUDGHA,
        kiku.TORMENT_RANK)
end

-- Insufficient MP is a free refusal, before the action enters the turn queue.
function torment.prepare(ctx, player)
    if not costs.enough_magic(ctx, player, kiku.TORMENT_MP) then
        return "You do not have enough magic."
    end

    return nil
end

-- A failed invocation costs time alone. On success, the area affects every
-- living target (including the invoker) before the ordinary divine cost.
function torment.resolve(ctx, player)
    if costs.failed(ctx, player, kiku.TORMENT_FAIL_BASE,
        kiku.TORMENT_FAIL_SCALE, kiku.TORMENT_FAIL_PIETY) then
        ctx:emit(channels.RELIGION, "You fail to use your ability.")

        return
    end

    ctx:emit(channels.RELIGION,
        "Kikubaaqudgha torments the living!")
    area.apply(ctx, player, channels.RELIGION,
        nil, sources.KIKU_INVOKED)
    costs.spend(ctx, player, kiku.TORMENT_MP,
        costs.piety_cost(ctx, kiku.TORMENT_PIETY))
end

-- The ability menu shows the same full LOS radius used by area.apply.
function torment.range()
    return spell_range.LOS_RADIUS
end

registry.add(abilities.KIKU_TORMENT, {
    name = "Torment",
    available = torment.available,
    prepare = torment.prepare,
    resolve = torment.resolve,
    range = torment.range,
})

return torment
