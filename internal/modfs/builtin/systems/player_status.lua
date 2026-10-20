-- Theory of operation: Ordered player-only passes apply durations, poison, and regeneration after an action.
-- Player status rules run once after each player action. The engine provides
-- authoritative Akara components and named RNG; this file owns the policy.
local player_health_policy = require("policy.combat.player_health")
local damage_causes = require("constants.damage_causes")
local statuses = require("policy.magic.effects.statuses.player")
local regeneration = require("policy.character.regeneration")
local attunement = require("policy.jewellery.attunement")

local system = {}

-- Fail on absent core status data so a partial player cannot silently skip recovery.
local function required(ctx, entity, name)
    local component = ctx:get(entity, name)

    if not component then
        error("player is missing " .. name)
    end

    return component
end

-- Use the player intent to gate status work to completed actions.
local function player_action(ctx, entity)
    local player = ctx:player()

    if not player then
        error("player entity is unavailable")
    end

    if entity ~= player then
        return false
    end

    required(ctx, entity, "core.player")

    return true
end

-- Crossing the low-duration warning threshold makes one speed-stream draw for extra decay.
local function decay_haste(ctx, current, aut)
    if current == 0 or aut == 0 then
        return current, nil
    end

    if current <= 10 then
        return 0, "You feel yourself slow down."
    end

    local remaining = current - aut
    local message

    if current > 60 and remaining <= 60 then
        message = "Your extra speed is starting to run out."

        if ctx:random("speed", 2) == 0 then
            remaining = remaining - 10
        end
    end

    return math.max(1, remaining), message
end

-- Duration and regeneration passes are separate registrations so each owns its turn timing.
function system.duration(ctx, entity, aut)
    if not player_action(ctx, entity) then
        return
    end

    local durations = required(ctx, entity, "core.durations")

    if aut < 0 or durations.might_aut < 0 or
        durations.might_aut > 800 or durations.haste_aut < 0 or
        durations.haste_aut > 400 then
        error("invalid player durations")
    end

    local might = durations.might_aut

    if might > 0 and aut > 0 then
        durations.might_aut = math.max(0, might - aut)

        if durations.might_aut == 0 then
            ctx:emit("duration", "You feel a little less mighty now.")
        end
    end

    local haste, message = decay_haste(ctx, durations.haste_aut, aut)
    durations.haste_aut = haste

    if message then
        ctx:emit("duration", message)
    end

    ctx:set(entity, "core.durations", durations)
end

register.system({
    id = "status.duration",
    scope = "active",
    query = {},
    after = { "character.advancement" },
    update = system.duration,
})

-- Round fractional regeneration with the dedicated stream after integer progress is counted.
local function regeneration_count(ctx, rate, aut)
    local numerator = rate * aut
    local count = math.floor(numerator / 10)
    local remainder = numerator % 10

    if remainder > 0 and ctx:random("regeneration", 10) < remainder then
        count = count + 1
    end

    return count
end

-- Accumulate aut-scaled HP and MP recovery before clamping each resource to its cap.
function system.regeneration(ctx, entity, aut)
    if not player_action(ctx, entity) then
        return
    end

    local health = required(ctx, entity, "core.health")
    local magic = required(ctx, entity, "core.magic")
    local progress = required(ctx, entity, "core.regeneration")

    if aut < 0 or health.max <= 0 or health.current < 0 or
        health.current > health.max or magic.max < 0 or
        magic.current < 0 or magic.current > magic.max or
        progress.hp_progress < 0 or progress.hp_progress >= 100 or
        progress.mp_progress < 0 or progress.mp_progress >= 100 then
        error("invalid player regeneration state")
    end

    -- A death hook can kill the player earlier in this same action. The
    -- remaining status passes must not recover HP or consume recovery RNG.
    if health.current == 0 then
        return
    end

    local hp_rate, mp_rate = regeneration.rates(ctx, entity,
        health.max, magic.max)
    if statuses.hp_regen_allowed(ctx, entity) and
        regeneration.hp_allowed(ctx, entity) then
        progress.hp_progress = progress.hp_progress +
            regeneration_count(ctx, hp_rate, aut)
    end

    -- Powered by Death can redirect an HP recovery point into MP before HP is increased.
    while progress.hp_progress >= 100 do
        if regeneration.hp_restores_magic(ctx, entity, magic) then
            magic.current = math.min(magic.max, magic.current + 1)
        else
            health.current = math.min(health.max, health.current + 1)
        end

        progress.hp_progress = progress.hp_progress - 100
    end

    if magic.current < magic.max then
        progress.mp_progress = progress.mp_progress +
            regeneration_count(ctx, mp_rate, aut)
    end

    while progress.mp_progress >= 100 do
        magic.current = math.min(magic.max, magic.current + 1)
        progress.mp_progress = progress.mp_progress - 100
    end

    ctx:set(entity, "core.health", health)
    ctx:set(entity, "core.magic", magic)
    ctx:set(entity, "core.regeneration", progress)
    -- Resource recovery can activate regeneration jewellery, so attunement follows saved vitals.
    attunement.refresh(ctx, entity)
end

register.system({
    id = "status.regeneration",
    scope = "active",
    query = {},
    after = { "status.duration" },
    update = system.regeneration,
})

-- Poison values are thousandths of eventual HP damage. These conversions
-- follow player.cc's three rate bands and truncate like the C++ integer cast.
local function duration_to_aut(amount)
    local denominator = 5
    local minimum_rate = 100
    local maximum_rate = 5000
    local minimum = denominator * minimum_rate * 10
    local maximum = denominator * maximum_rate * 10
    local decay = math.log(denominator / (denominator - 1))

    if amount < minimum then
        return amount / minimum_rate
    end

    if amount < maximum then
        return 10 * (denominator + math.log(amount / minimum) / decay)
    end

    local maximum_aut = 10 *
        (denominator + math.log(maximum_rate / minimum_rate) / decay)

    return maximum_aut + (amount - maximum) / maximum_rate
end

-- Round remaining aut for a duration message without changing the stored timer.
local function aut_to_duration(remaining)
    local denominator = 5
    local minimum_rate = 100
    local maximum_rate = 5000
    local minimum_aut = denominator * 10

    if remaining < minimum_aut then
        return remaining * minimum_rate
    end

    local decay = math.log(denominator / (denominator - 1))
    local maximum_aut = 10 *
        (denominator + math.log(maximum_rate / minimum_rate) / decay)

    if remaining < maximum_aut then
        return 10 * denominator * minimum_rate *
            math.exp(decay / 10 * (remaining - minimum_aut))
    end

    return denominator * 10 * maximum_rate +
        maximum_rate * (remaining - maximum_aut)
end

-- Choose the poison damage message after the amount is known.
local function sickness_message(damage)
    if damage > 6 then
        return "You feel extremely sick."
    end

    if damage > 2 then
        return "You feel very sick."
    end

    return "You feel sick."
end

-- Apply poison damage and age its timer before regeneration handles the surviving player.
function system.poison(ctx, entity, aut)
    if not player_action(ctx, entity) then
        return
    end

    local poison = ctx:get(entity, "core.poison")

    if not poison then
        return
    end

    if poison.amount_scaled < 1000 or
        poison.amount_scaled > 2147483647 or aut <= 0 then
        error("invalid player poison state")
    end

    local health = required(ctx, entity, "core.health")
    local before = health.current
    -- Convert poison to its source-equivalent time before subtracting elapsed aut.
    local remaining = duration_to_aut(poison.amount_scaled) - aut
    local remaining_duration = aut_to_duration(remaining)

    if remaining_duration < -2147483647 or
        remaining_duration > 2147483647 then
        error("poison decay exceeded source integer range")
    end

    local next_amount = math.modf(remaining_duration)
    -- Poison damage is the lost whole-HP portion of the decaying scaled amount.
    local damage = math.floor(poison.amount_scaled / 1000) -
        math.modf(next_amount / 1000)

    health = player_health_policy.damage(ctx, entity, damage,
        false, nil, damage_causes.POISON)

    if health.current < before then
        ctx:emit("poison", sickness_message(damage))
    end

    if next_amount < 1000 then
        ctx:remove(entity, "core.poison")

        if health.current > 0 then
            ctx:emit("poison", "You are no longer poisoned.")
        end
    else
        poison.amount_scaled = next_amount
        ctx:set(entity, "core.poison", poison)
    end

    if health.current == 0 then
        ctx:emit("death", "You die.")
    end
end

register.system({
    id = "status.poison",
    scope = "active",
    query = {},
    after = { "status.regeneration" },
    update = system.poison,
})

return system
