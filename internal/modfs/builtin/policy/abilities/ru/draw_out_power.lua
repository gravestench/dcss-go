-- Theory of operation: Ru lets a wounded or restrained worshipper recover
-- immediately at the price of temporary maximum-HP drain and exhaustion.
-- Preparation is free; only the paid ability resolution rolls piety healing.
local abilities = require("ids.abilities")
local component = require("constants.component")
local costs = require("policy.abilities.god_costs")
local drain = require("policy.combat.player_drain")
local exhaustion = require("policy.character.exhaustion")
local gods = require("constants.gods")
local held = require("policy.traps.held")
local registry = require("policy.abilities.registry")
local roll = require("policy.combat.roll")
local powers = require("constants.ru_powers")
local streams = require("constants.rng_streams")
local zap = require("policy.magic.effects.zaps.ids").component

local draw = {}

-- Rank and the shared Exhausted duration are live menu gates.
function draw.available(ctx, player)
    return costs.available(ctx, player, gods.RU,
        powers.DRAW_RANK) and
        not exhaustion.active(ctx, player)
end

-- Source allows the power while confused, but refuses an uninjured player
-- who has full MP and none of the named restraints or ailments to clear.
function draw.needed(ctx, player)
    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)
    local stone = ctx:get(player, component.PLAYER_PETRIFICATION)

    return (health and health.current < health.max) or
        (magic and magic.current < magic.max) or
        ctx:has(player, component.TRAP_HELD) or
        ctx:has(player, component.CONSTRICTION) or
        ctx:has(player, component.PLAYER_SLOW) or
        ctx:has(player, zap.PLAYER_CONFUSION) or
        (stone and stone.petrifying_aut > 0) or false
end

-- Free preflight leaves the resource pools and RNG untouched.
function draw.prepare(ctx, player)
    if not draw.needed(ctx, player) then
        return "You have no need to draw out power."
    end
end

-- Restraints are released through their owner; simple durations can be
-- removed directly because no other state depends on their expiry.
local function cure(ctx, player)
    held.break_free(ctx, player)

    if ctx:has(player, component.CONSTRICTION) then
        ctx:remove(player, component.CONSTRICTION)
    end

    for _, id in ipairs({
        zap.PLAYER_CONFUSION,
        component.PLAYER_SLOW,
    }) do
        if ctx:has(player, id) then
            ctx:remove(player, id)
        end
    end

    local stone = ctx:get(player, component.PLAYER_PETRIFICATION)

    if stone and stone.petrifying_aut > 0 then
        ctx:remove(player, component.PLAYER_PETRIFICATION)
    end
end

-- Source order: free the body, cure statuses, restore HP/MP from piety,
-- drain maximum HP with power 30, then start 12–16 turns of exhaustion.
function draw.resolve(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local health = ctx:get(player, component.HEALTH)
    local magic = ctx:get(player, component.MAGIC)

    ctx:emit("religion",
        "You are restored by drawing out deep reserves of power within.")
    cure(ctx, player)

    local hp_base = roll.random_divide(ctx, worship.piety,
        powers.DRAW_HP_DIVISOR, streams.RELIGION)
    local hp_dice = roll.random_divide(ctx, worship.piety,
        powers.DRAW_HP_DICE_DIVISOR, streams.RELIGION)
    local hp = hp_base +
        roll.dice(ctx, streams.RELIGION, hp_dice,
            powers.DRAW_HP_DIE_SIDES)
    local mp_base = roll.random_divide(ctx, worship.piety,
        powers.DRAW_MP_DIVISOR, streams.RELIGION)
    local mp_dice = roll.random_divide(ctx, worship.piety,
        powers.DRAW_MP_DICE_DIVISOR, streams.RELIGION)
    local mp = mp_base +
        roll.dice(ctx, streams.RELIGION, mp_dice,
            powers.DRAW_MP_DIE_SIDES)

    health.current = math.min(health.max, health.current + hp)
    magic.current = math.min(magic.max, magic.current + mp)
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.MAGIC, magic)

    drain.apply(ctx, player, powers.DRAW_DRAIN_POWER,
        streams.RELIGION)
    exhaustion.apply(ctx, player,
        powers.DRAW_EXHAUST_TURNS +
        ctx:random(streams.RELIGION,
            powers.DRAW_EXHAUST_SPAN))
end

registry.add(abilities.RU_DRAW_OUT_POWER, {
    name = "Draw Out Power",
    confusion_ok = true,
    available = draw.available,
    prepare = draw.prepare,
    resolve = draw.resolve,
})

return draw
