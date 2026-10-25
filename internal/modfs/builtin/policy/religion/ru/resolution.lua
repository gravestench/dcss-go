-- Theory of operation: accepting or rejecting one saved Ru offer closes
-- the entire set and resets the saved progress clock. The ability command
-- confirms first, so this owner runs only after a paid player intent.
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local jewellery = require("policy.inventory.jewellery_effects")
local capabilities = require("constants.jewellery_capabilities")
local mutations = require("ids.mutations")
local classes = require("constants.mutation_classes")
local levels = require("policy.mutations.levels")
local transition = require("policy.mutations.transition")
local piety = require("policy.religion.piety")
local pricing = require("policy.religion.ru.pricing")
local streams = require("constants.rng_streams")
local timing = require("constants.ru_timing")
local limits = require("constants.piety")
local sacrifice_ids = require("ids.ru_sacrifices")

local resolution = {}

-- A saved ability ID is valid only while Ru still owns this exact choice.
-- Both menu availability and paid resolution use this predicate, so stale
-- commands cannot select a different set after god time changes the state.
function resolution.offered(ctx, player, offer_id)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local state = ctx:get(player, component.RELIGION_RU)

    if not worship or worship.god_id ~= gods.RU or not state then
        return false
    end

    for _, id in ipairs(state.available) do
        if id == offer_id then
            return true
        end
    end

    return false
end

-- Source ability validation withholds Sacrifice Experience at XL1, even
-- when an older saved offer still contains it. The set can still be rejected.
function resolution.acceptable(ctx, player, offer_id)
    if not resolution.offered(ctx, player, offer_id) then
        return false
    end

    if offer_id ~= sacrifice_ids.EXPERIENCE then
        return true
    end

    local progress = ctx:get(player, component.PROGRESSION)

    return progress and progress.level > 1 or false
end

-- Drop all choices and mutation variants together. A rejected Health offer
-- must never leave a Frail choice for a later set to accidentally reuse.
local function clear(state)
    state.available = {}
    state.health = {}
    state.essence = {}
    state.purity = {}
    state.arcana = {}
    state.quoted_piety = {}
end

-- Match source div_rand_round without drawing when the division is exact.
local function round_ratio(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder == 0 then
        return whole
    end

    return whole + (ctx:random(streams.RELIGION,
        denominator) < remainder and 1 or 0)
end

-- Acceptance resets the base clock and accumulated penalty. Rejection
-- raises both; the source's ordinary reject call also selects its extra
-- Faith-removal branch, adding two more penalties before the Faith scale.
local function reset_timer(ctx, player, state, worship, accepted)
    local delay = timing.BASE_DELAY

    if accepted then
        state.sacrifice_penalty = 0
    else
        local new_penalty = math.floor(math.max(
            timing.MIN_PENALTY_PIETY, worship.piety) /
            timing.PENALTY_DIVISOR)
        local accumulated = state.sacrifice_penalty + new_penalty

        state.sacrifice_penalty = accumulated
        delay = delay + accumulated +
            new_penalty * timing.FAITH_MULTIPLIER
    end

    local has_faith = jewellery.has(ctx, player,
        capabilities.FAITH)
    local multiplier = has_faith and
        timing.FAITH_MULTIPLIER or timing.NORMAL_MULTIPLIER

    state.sacrifice_delay = round_ratio(ctx,
        delay * multiplier, timing.NORMAL_MULTIPLIER)
    state.sacrifice_progress = 0
end

-- A rejected set is meaningful only for the current Ru worshipper. This
-- check prevents a stale ability command from modifying a later patron.
function resolution.reject(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local state = ctx:get(player, component.RELIGION_RU)

    if not worship or worship.god_id ~= gods.RU or
        not state or #state.available == 0 then
        error("Ru rejection requires a current saved offer")
    end

    reset_timer(ctx, player, state, worship, false)
    clear(state)
    ctx:set(player, component.RELIGION_RU, state)
end

-- Source requests three minus the current safety rank; the mutation owner
-- clamps it at its two-rank catalog cap and can convert acquired ranks to
-- innate ones. Ordinary sacrifices grant one rank, including Arcana schools.
local function grant_mutation(ctx, player, mutation_id)
    local count = 1

    if mutation_id == mutations.MUT_READ_SAFETY or
        mutation_id == mutations.MUT_DRINK_SAFETY then
        count = 3 - levels.base(ctx, player, mutation_id)
    end

    for _ = 1, count do
        -- A forced conflict can trade an opposing acquired rank before
        -- this rank can be installed. Source retries that transition.
        for _ = 1, 100 do
            local outcome = transition.grant(ctx, player, mutation_id,
                classes.INNATE, true)

            if outcome.kind ~= "traded" then
                break
            end
        end
    end
end

-- The quoted amount was saved when offers were generated. Only the named
-- skill value is recomputed now; sacrifice effects may erase that skill.
function resolution.accept(ctx, player, offer_id)
    if not resolution.acceptable(ctx, player, offer_id) then
        error("Ru acceptance requires a current saved offer")
    end

    local state = ctx:get(player, component.RELIGION_RU)
    local definition = catalog.get(categories.RU_SACRIFICES, offer_id)
    local selected = definition.variant_pool and
        state[definition.variant_pool] or { definition.mutation_id }
    local quoted = state.quoted_piety[offer_id]

    if type(quoted) ~= "number" or quoted <= 0 or
        #selected == 0 then
        error("Ru offer has an invalid saved price or mutation")
    end

    local gain = quoted + pricing.skill_value(ctx, player, definition)
    local consequence = definition.accept_module and
        require(definition.accept_module) or nil
    local previous = consequence and consequence.before and
        consequence.before(ctx, player) or nil

    for _, mutation_id in ipairs(selected) do
        grant_mutation(ctx, player, mutation_id)
    end

    if consequence then
        consequence.apply(ctx, player, previous)
    end

    -- The source records the number of mutation grants in this choice.
    -- Arcana is one menu acceptance but contributes three schools.
    state.sacrifice_mutations = state.sacrifice_mutations + #selected

    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local points = piety.award_ru_sacrifice(ctx, player, gain)

    if points == limits.RU_MAX then
        ctx:emit("religion",
            "Ru indicates that your awakening is complete.")
    end

    reset_timer(ctx, player, state, worship, true)
    clear(state)
    ctx:set(player, component.RELIGION_RU, state)
    ctx:emit("religion", "You have " .. definition.milestone_text .. ".")

    return points
end

return resolution
