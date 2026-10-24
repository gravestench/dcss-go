-- Theory of operation: each registered sacrifice definition becomes one
-- ordinary ability with the same stable ID. Availability reads the saved
-- offer set, while preparation asks for a free confirmation. Only a forced,
-- still-current ability intent spends a turn and closes the whole set.
-- Adding a mod sacrifice file needs no new command handler.
local abilities = require("ids.abilities")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local registry = require("policy.abilities.registry")
local resolution = require("policy.religion.ru.resolution")
local pricing = require("policy.religion.ru.pricing")
local piety = require("policy.religion.piety")
local limits = require("constants.piety")
local gods = require("constants.gods")

local sacrifices = {}

-- Present the catalog's human description instead of an internal mutation
-- ID. The saved offer still stores IDs, so localized text can change safely.
local function variant_label(id)
    local definition = catalog.get(categories.MUTATIONS, id)

    return type(definition.short_description) == "string" and
        definition.short_description ~= "" and
        definition.short_description or id
end

-- Use the same gate for a menu row and a prepared command. In particular,
-- leaving Ru after seeing an offer removes its ability immediately.
function sacrifices.available(ctx, player, id)
    return resolution.acceptable(ctx, player, id)
end

-- Source asks before permanently changing the character. A saved choice
-- can have a variable mutation, so show that choice in the question.
function sacrifices.confirmation(ctx, player, definition)
    local state = ctx:get(player, component.RELIGION_RU)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)
    local selected = definition.variant_pool and
        state[definition.variant_pool] or {}
    local detail = ""

    if #selected > 0 then
        local labels = {}

        for _, id in ipairs(selected) do
            labels[#labels + 1] = variant_label(id)
        end

        detail = " (" .. table.concat(labels, ", ") .. ")"
    end

    local gain = state.quoted_piety[definition.id] +
        pricing.skill_value(ctx, player, definition)
    local after = math.min(limits.RU_MAX,
        worship.piety + gain)
    local stars = piety.rank(gods.RU, after)
    local rating = string.rep("*", stars) ..
        string.rep(".", #limits.BREAKPOINTS - stars)

    return "Ru asks you to " .. definition.sacrifice_text ..
        detail .. ". This is " .. pricing.describe(gain) ..
        " sacrifice. Piety after sacrifice: " .. rating ..
        ". Do you really want to make this sacrifice?"
end

-- The terminal has a dedicated confirmation view. Other clients receive
-- the same free confirmation through the normal ability prepare result.
function sacrifices.prepare(ctx, player, input, definition)
    if not sacrifices.available(ctx, player, definition.id) then
        return "Ru is no longer offering that sacrifice."
    end

    if not input.forced then
        return {
            confirmation = sacrifices.confirmation(ctx, player,
                definition),
            confirmation_id = definition.id,
        }
    end
end

-- Build one small handler object per registered definition. Functions are
-- named as methods so the action flow remains readable to a mod author.
local function offered_ability(definition)
    local ability = {
        name = "Sacrifice " .. definition.name,
    }

    -- Show only a choice from the player's saved current offer set.
    function ability.available(ctx, player)
        return sacrifices.available(ctx, player, definition.id)
    end

    -- Every permanent bargain must be confirmed by the player.
    function ability.confirmation_needed()
        return true
    end

    -- Read the saved mutation variant for the confirmation view.
    function ability.confirmation_message(ctx, player)
        return sacrifices.confirmation(ctx, player, definition)
    end

    -- A declined prompt returns before an action intent is scheduled.
    function ability.prepare(ctx, player, input)
        return sacrifices.prepare(ctx, player, input, definition)
    end

    -- The resolver checks this ID again after action timing.
    function ability.resolve(ctx, player)
        resolution.accept(ctx, player, definition.id)
    end

    return ability
end

-- Register the resolved catalog after all content layers have loaded.
-- A later overlay may replace a definition without changing this loop.
for _, definition in ipairs(catalog.all(categories.RU_SACRIFICES)) do
    registry.add(definition.id, offered_ability(definition))
end

local rejection = {
    name = "Reject Sacrifices",
}

-- Rejection shares the offer gate but does not name a specific choice.
function rejection.available(ctx, player)
    local state = ctx:get(player, component.RELIGION_RU)

    return state and #state.available > 0 and
        resolution.offered(ctx, player, state.available[1]) or false
end

-- Rejecting the whole set also needs explicit confirmation.
function rejection.confirmation_needed()
    return true
end

-- Use the same wording in the terminal view and the command bridge.
function rejection.confirmation_message()
    return "Do you really want to reject the sacrifices Ru is offering?"
end

-- A canceled rejection leaves all choices and the timer untouched.
function rejection.prepare(ctx, player, input)
    if not input.forced then
        return {
            confirmation = rejection.confirmation_message(),
            confirmation_id = abilities.RU_REJECT_SACRIFICES,
        }
    end
end

-- A paid rejection closes the set and extends the saved wait.
function rejection.resolve(ctx, player)
    resolution.reject(ctx, player)
    ctx:emit("religion",
        "Ru will take longer to evaluate your readiness.")
end

registry.add(abilities.RU_REJECT_SACRIFICES, rejection)

return sacrifices
