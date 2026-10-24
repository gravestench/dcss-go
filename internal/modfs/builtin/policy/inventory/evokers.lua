-- Theory of operation: XP evokers have no item-local charge field. Each
-- subtype draws from one player debt entry, so swapping or duplicating an
-- item cannot reset its charges. A credited monster kill reduces debt only
-- for subtypes currently in inventory. Effects and command timing live in
-- separate modules; this owner knows only charge rules.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local formulas = require("policy.character.formulas")
local power = require("policy.magic.power")
local skills = require("ids.skills")
local streams = require("constants.rng_streams")
local intent = require("constants.intent")
local effects = require("policy.inventory.evokers.effects")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local confusion = require("policy.magic.player_confusion")

local evokers = {}

local rules = {}

for _, definition in ipairs(catalog.all(categories.ITEMS)) do
    if definition.evoker then
        local rule = definition.evoker

        if type(rule.charge_debt) ~= "number" or
            rule.charge_debt < 1 or rule.charge_debt % 1 ~= 0 or
            type(rule.max_charges) ~= "number" or
            rule.max_charges < 1 or rule.max_charges % 1 ~= 0 then
            error("invalid XP evoker rules for " .. definition.id)
        end

        rules[definition.id] = rule
    end
end

-- Return a subtype's source charge cost and capacity. Unknown miscellany
-- is not an XP evoker, even if a mod gives it a similar name.
function evokers.definition(kind_id)
    return rules[kind_id]
end

-- An item definition is incomplete without its matching Lua behavior.
-- Fail during mod loading rather than after a player finds that item.
function evokers.validate_effects()
    for kind_id in pairs(rules) do
        if not effects.get(kind_id) then
            error("XP evoker has no registered effect " .. kind_id)
        end
    end
end

-- The remaining evokers select a target automatically or act around the
-- player. Only these three need an explicit aiming screen.
function evokers.aimed(kind_id)
    local rule = rules[kind_id]

    return rule ~= nil and rule.aimed == true
end

-- Keep boundary arithmetic identical for the inventory label and the XP
-- crossing check, even though component reads return fresh Lua tables.
local function charges_for_debt(rule, debt)
    return math.max(0, rule.max_charges -
        math.ceil(debt / rule.charge_debt))
end

-- Compute visible charges from debt. Partial debt consumes a whole slot,
-- matching the source ceiling division in item-prop.cc:evoker_charges.
function evokers.charges(ctx, player, kind_id)
    local rule = assert(rules[kind_id], "unknown XP evoker")
    local state = ctx:get(player, component.XP_EVOKERS)
    local debt = state and (state.debt or {})[kind_id] or 0

    return charges_for_debt(rule, debt)
end

-- Spend one charge on the player after an effect has committed. In
-- particular, a second copy of this subtype sees the same debt.
function evokers.expend(ctx, player, kind_id)
    local rule = assert(rules[kind_id], "unknown XP evoker")

    if evokers.charges(ctx, player, kind_id) <= 0 then
        error("XP evoker has no charge to expend")
    end

    local state = ctx:get(player, component.XP_EVOKERS) or { debt = {} }

    state.debt[kind_id] = (state.debt[kind_id] or 0) + rule.charge_debt

    if ctx:has(player, component.XP_EVOKERS) then
        ctx:set(player, component.XP_EVOKERS, state)
    else
        ctx:add(player, component.XP_EVOKERS, state)
    end
end

-- Source div_rand_round consumes an RNG draw only for a remainder. Keeping
-- the draw in the evoker stream makes replay independent of other domains.
local function random_round(ctx, numerator, denominator)
    local whole = math.floor(numerator / denominator)
    local remainder = numerator % denominator

    if remainder > 0 and
        ctx:random(streams.EVOKER, denominator) < remainder then
        whole = whole + 1
    end

    return whole
end

-- The source's skill_rdiv(SK_EVOCATIONS, 2, 13) starts with skill scaled
-- by 2*256, then randomly divides by 13*256. This denominator makes
-- Evocations training shorten the same XP recharge clock.
local function xp_factor(ctx, player)
    local progress = ctx:get(player, component.PROGRESSION)
    local level = progress.level
    local next_xp = formulas.experience_needed(level + 1, 0)
    local base = math.max(math.min(
        math.floor(next_xp * 2 / 7), level * 425),
        level * 4 + 30)
    local skill = power.training(ctx, player, skills.SK_EVOCATIONS, 512)
    local bonus = random_round(ctx, skill, 13 * 256)

    return math.max(1, math.floor(base / (3 + bonus)))
end

-- Only carried types charge. The source's inventory list holds one item
-- per subtype; this set provides the same behavior with duplicate copies.
local function carried_types(ctx, player)
    local result = {}

    for _, entity in ipairs(ctx:query({ component.ITEM, component.CARRIED_BY })) do
        local item = ctx:get(entity, component.ITEM)
        local carrier = ctx:get(entity, component.CARRIED_BY)

        if item and carrier and carrier.holder == player and
            rules[item.kind_id] then
            result[item.kind_id] = true
        end
    end

    return result
end

-- Apply credited monster XP to each indebted subtype present in the pack.
-- A recovered charge is announced when its debt crosses a charge boundary.
function evokers.award_xp(ctx, player, xp)
    local state = ctx:get(player, component.XP_EVOKERS)

    if not state or xp <= 0 then
        return
    end

    local carried = carried_types(ctx, player)
    local factor = nil

    local kinds = {}

    for kind_id in pairs(state.debt) do
        kinds[#kinds + 1] = kind_id
    end

    -- Sort before drawing recharge RNG so map insertion and file load order
    -- cannot change which subtype receives a fractional XP point.
    table.sort(kinds)

    for _, kind_id in ipairs(kinds) do
        local debt = state.debt[kind_id]
        if debt > 0 and carried[kind_id] then
            factor = factor or xp_factor(ctx, player)

            local rule = rules[kind_id]
            local old_charges = charges_for_debt(rule, debt)
            state.debt[kind_id] = math.max(0, debt -
                random_round(ctx, xp, factor))
            local gained = charges_for_debt(rule,
                state.debt[kind_id]) - old_charges

            if gained > 0 then
                local name = catalog.get("items", kind_id).name

                if rules[kind_id].max_charges == 1 then
                    ctx:emit("evoke", "Your " .. name .. " has recharged.")
                else
                    local noun = gained == 1 and " charge." or " charges."

                    ctx:emit("evoke", "Your " .. name ..
                        " has regained " .. gained .. noun)
                end
            end
        end
    end

    ctx:set(player, component.XP_EVOKERS, state)
end

-- Reject saved debt for unknown subtypes or non-player entities. A forged
-- negative or fractional value could otherwise create extra charges.
function evokers.validate(ctx, player)
    for _, entity in ipairs(ctx:query({ component.XP_EVOKERS })) do
        if entity ~= player then
            error("orphan XP evoker debt")
        end

        local state = ctx:get(entity, component.XP_EVOKERS)

        for kind_id, debt in pairs(state.debt or {}) do
            if not rules[kind_id] or type(debt) ~= "number" or
                debt < 0 or debt % 1 ~= 0 then
                error("invalid XP evoker debt")
            end
        end
    end
end

-- Reject a missing, foreign, empty, or invalid item without opening a
-- timed action. Target-specific rules may reject the requested cell too.
function evokers.prepare(ctx, player, item_id, dx, dy, forced)
    local entity = item_id ~= 0 and ctx:entity(item_id) or nil
    local item = entity and ctx:get(entity, component.ITEM)
    local carrier = entity and ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player then
        return { message = "You are not carrying that evoker." }
    end

    local rule = evokers.definition(item.kind_id)

    if not rule then
        return { message = "You cannot evoke that item." }
    end

    if mutation_levels.effective(ctx, player,
        mutations.MUT_NO_ARTIFICE) > 0 then
        return { message = "You cannot evoke magical items." }
    end

    if confusion.active(ctx, player) then
        return { message = "You are too confused!" }
    end

    if evokers.charges(ctx, player, item.kind_id) <= 0 then
        return { message = "That evoker is inert." }
    end

    if rule.aimed and dx == 0 and dy == 0 then
        return { message = "Okay, then." }
    end

    local effect = effects.get(item.kind_id)

    if not effect then
        error("XP evoker has no registered effect " .. item.kind_id)
    end

    if effect.prepare then
        local rejection = effect.prepare(ctx, player, dx, dy, forced)

        if rejection then
            if type(rejection) == "table" then
                return rejection
            end

            return { message = rejection }
        end
    end

    return {
        intent = {
            kind = intent.EVOKE_ITEM,
            item_id = entity,
            dx = dx,
            dy = dy,
        },
        cost = 10,
    }
end

-- The committed action rechecks its carried item before delegating to
-- that subtype's Lua resolver. Only an effect marked chargeable adds debt.
function evokers.resolve(ctx, player, chosen, aut)
    local entity = chosen.item_id
    local item = entity and ctx:get(entity, component.ITEM)
    local carrier = entity and ctx:get(entity, component.CARRIED_BY)

    if not item or not carrier or carrier.holder ~= player or
        not rules[item.kind_id] or
        evokers.charges(ctx, player, item.kind_id) <= 0 then
        error("prepared XP evoker is no longer carried or charged")
    end

    local effect = effects.get(item.kind_id)

    if not effect then
        error("XP evoker has no registered effect " .. item.kind_id)
    end

    local outcome = effect.resolve(ctx, player, chosen, aut)

    if outcome and outcome.charge then
        evokers.expend(ctx, player, item.kind_id)
    end

    for _ = 1, outcome and outcome.practice or 0 do
        ctx:signal("practice", skills.SK_EVOCATIONS)
    end

    return outcome
end

return evokers
