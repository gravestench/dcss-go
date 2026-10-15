-- Playable potion effects from potion.cc. The item-use system handles the
-- shared transaction; each handler owns one source effect and its RNG draws.

local potions = {}
local player_health = require("policy.combat.player_health")
local potion_rules = require("policy.character.potion_rules")
local might = require("policy.character.might")

local function required(ctx, entity, name)
    local component = ctx:get(entity, name)

    if not component then
        error("potion target is missing " .. name)
    end

    return component
end

function potions.POT_CURING(ctx, player)
    local health = required(ctx, player, "core.health")

    if player_health.can_heal(ctx, player) and
        potion_rules.can_heal(ctx, player) then
        local amount = 5 + ctx:random("potion", 7)

        health.current = math.min(health.max,
            health.current + potion_rules.scale_healing(ctx, player, amount))
    end

    ctx:set(player, "core.health", health)

    if ctx:has(player, "core.poison") then
        ctx:remove(player, "core.poison")
    end

    return "You feel better."
end

function potions.POT_HEAL_WOUNDS(ctx, player)
    local health = required(ctx, player, "core.health")

    if health.current == health.max then
        error("player cannot use heal wounds at current health")
    end

    local total = ctx:random("potion", 28) +
        ctx:random("potion", 29) +
        ctx:random("potion", 29)

    local amount = 10 + math.floor(total / 3)

    health.current = math.min(health.max,
        health.current + potion_rules.scale_healing(ctx, player, amount))

    ctx:set(player, "core.health", health)

    return "You feel much better."
end

function potions.POT_MIGHT(ctx, player)
    return might.apply(ctx, player, 40, "potion")
end

local function rounded_two_thirds(ctx, value)
    local numerator = value * 2
    local whole = math.floor(numerator / 3)
    local remainder = numerator % 3

    if remainder > 0 and ctx:random("potion", 3) < remainder then
        return whole + 1
    end

    return whole
end

function potions.POT_HASTE(ctx, player)
    local durations = required(ctx, player, "core.durations")
    local previous = durations.haste_aut
    local roll = ctx:random("potion", 40)
    local turns = rounded_two_thirds(ctx, 40 + roll)

    durations.haste_aut = math.min(400, previous + turns * 10)

    ctx:set(player, "core.durations", durations)

    if previous > 0 then
        return "You feel as though your hastened speed will last longer."
    end

    return "You feel yourself speed up."
end

return potions
