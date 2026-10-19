local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local brilliance = require("policy.potions.brilliance")

local resources = {}

-- Source: spl-util.cc:spell_mana. Only ordinary spell casts use this
-- reduction; evocations and other spell-like sources keep their own costs.
function resources.spell_cost(ctx, player, level)
    if brilliance.active(ctx, player) then
        return math.floor((level + 1) / 2)
    end

    return level
end

-- Djinni-style HP casting changes the resource pool but still requires both health and magic state.
local function state(ctx, player)
    local health = ctx:get(player, "core.health")
    local magic = ctx:get(player, "core.magic")

    if not health or not magic then
        error("player lacks spell resource state")
    end

    local from_hp = mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_CASTING) > 0

    return health, magic, from_hp
end

-- Source: spl-util.cc:casting_uselessness_reason and player.cc:pay_mp.
-- Djinni's spell cost is paid from HP and must leave at least one HP.
function resources.cannot_pay(ctx, player, cost)
    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        if health.current <= cost then
            return "You don't have enough health to cast this spell."
        end
    elseif magic.current < cost then
        return "You don't have enough magic to cast this spell."
    end

    return nil
end

-- Example: a Djinni cast costing three points debits HP only if more than three HP remain.
-- Recheck affordability at payment time, then debit the HP or MP pool selected by mutation.
function resources.pay(ctx, player, cost)
    local rejection = resources.cannot_pay(ctx, player, cost)

    if rejection then
        error(rejection)
    end

    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        health.current = health.current - cost
        ctx:set(player, "core.health", health)
    else
        magic.current = magic.current - cost
        ctx:set(player, "core.magic", magic)
    end
end

-- Refund the pool used for payment and clamp to its current maximum after interrupted casts.
function resources.refund(ctx, player, cost)
    local health, magic, from_hp = state(ctx, player)

    if from_hp then
        health.current = math.min(health.max, health.current + cost)
        ctx:set(player, "core.health", health)
    else
        magic.current = math.min(magic.max, magic.current + cost)
        ctx:set(player, "core.magic", magic)
    end
end

return resources
