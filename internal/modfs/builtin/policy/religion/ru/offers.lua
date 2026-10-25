-- Theory of operation: a saved progress counter is checked only at god
-- time. Eligible definitions are visited in stable ID order, then three
-- distinct choices are selected with the source cap-aware reservoir rule.
-- The whole choice set is saved together so inspecting it never rerolls.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local limits = require("constants.piety")
local pricing = require("policy.religion.ru.pricing")
local streams = require("constants.rng_streams")
local variants = require("policy.religion.ru.variants")

local offers = {}

-- The source chooses variable mutations before a sacrifice's custom
-- validity check. Arcana therefore spends its school draws even when a
-- prior Arcana sacrifice rules it out afterward.
local function candidate_mutations(ctx, player, definition)
    if not variants.possible(ctx, player, definition) then
        return nil
    end

    local selected = definition.variant_pool and
        variants.choose(ctx, player, definition.variant_pool) or
        { definition.mutation_id }

    if definition.offer_rule_module then
        local rule = require(definition.offer_rule_module)

        if not rule.eligible(ctx, player) then
            return nil
        end
    end

    return selected
end

-- The source recalculates a blurred price at every comparison. Retaining
-- those draws matters near Ru's piety cap, where a newly sampled price can
-- admit or exclude a candidate on the very next pass.
local function choose(ctx, player, possible, piety)
    local cheapest

    for _, candidate in ipairs(possible) do
        if not cheapest then
            pricing.quote(ctx, player, candidate.definition,
                candidate.selected)
            cheapest = candidate
        else
            local left = pricing.quote(ctx, player,
                cheapest.definition, cheapest.selected)
            local right = pricing.quote(ctx, player,
                candidate.definition, candidate.selected)

            if right < left then
                cheapest = candidate
            end
        end
    end

    local minimum = pricing.quote(ctx, player,
        cheapest.definition, cheapest.selected)
    local cap = math.max(179, piety + minimum)
    local seen = 0
    local chosen

    for index, candidate in ipairs(possible) do
        local price = pricing.quote(ctx, player,
            candidate.definition, candidate.selected)

        if piety + price <= cap then
            seen = seen + 1

            if ctx:random(streams.RELIGION, seen) == 0 then
                chosen = index
            end
        end
    end

    if chosen then
        return chosen
    end

    -- Preserve the source fallback's running threshold and reservoir draw.
    local threshold = 999
    local cheap_seen = 0

    for index, candidate in ipairs(possible) do
        local price = pricing.quote(ctx, player,
            candidate.definition, candidate.selected)

        if price < threshold then
            cheap_seen = cheap_seen + 1

            if ctx:random(streams.RELIGION, cheap_seen) == 0 then
                chosen = index
                threshold = price
            end
        end
    end

    return chosen
end

-- Roll variable mutations only for selected candidates. Store each pool in
-- its matching saved field, and keep the quote apart from changeable skills.
local function save_choice(ctx, player, state, candidate)
    local definition = candidate.definition

    if definition.variant_pool then
        state[definition.variant_pool] = candidate.selected
    end

    state.available[#state.available + 1] = definition.id
    state.quoted_piety[definition.id] = pricing.quote(ctx, player,
        definition, candidate.selected, false)
end

-- Collect and commit three offers. Fewer than three candidates leaves the
-- current saved state untouched, as in wizard-mode source edge cases.
function offers.new(ctx, player, piety)
    local possible = {}

    for _, definition in ipairs(catalog.all(categories.RU_SACRIFICES)) do
        local selected = candidate_mutations(ctx, player,
            definition)

        if selected then
            -- Source chooses variable mutations while inspecting the full
            -- possible set, even when this offer is not finally shown.
            possible[#possible + 1] = {
                definition = definition,
                selected = selected,
            }
        end
    end

    local state = ctx:get(player, component.RELIGION_RU)
    local pending = {
        sacrifice_progress = state.sacrifice_progress,
        sacrifice_delay = state.sacrifice_delay,
        sacrifice_penalty = state.sacrifice_penalty,
        sacrifice_mutations = state.sacrifice_mutations,
        available = {},
        health = {},
        essence = {},
        purity = {},
        arcana = {},
        quoted_piety = {},
    }

    -- Source clears the old vectors before trying to assemble a set.
    -- Fewer than three candidates cannot leave stale variants behind.
    if #possible < 3 then
        ctx:set(player, component.RELIGION_RU, pending)

        return false
    end

    for _ = 1, 3 do
        local selected = choose(ctx, player, possible, piety)
        local candidate = table.remove(possible, selected)

        save_choice(ctx, player, pending, candidate)
    end

    ctx:set(player, component.RELIGION_RU, pending)

    return true
end

-- The source does not expire an outstanding offer at the next clock tick.
-- Six stars closes Ru's bargain, even when saved progress remains high.
function offers.at_god_time(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    if not worship or worship.god_id ~= gods.RU or
        worship.piety >= limits.RU_MAX then
        return false
    end

    local state = ctx:get(player, component.RELIGION_RU)

    if not state or #state.available > 0 or
        state.sacrifice_progress < state.sacrifice_delay then
        return false
    end

    return offers.new(ctx, player, worship.piety)
end

return offers
