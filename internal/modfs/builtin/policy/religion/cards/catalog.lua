-- Theory of operation: the effective mod catalog is the sole source of
-- card names and deck weights. Boot validates its shape before any gift or
-- draw reaches an invalid random pool. Sorted IDs provide seeded order.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local decks = require("ids.decks")

local cards = {}

local player_decks = {
    decks.ESCAPE,
    decks.DESTRUCTION,
    decks.SUMMONING,
}

local known_decks = {
    [decks.ESCAPE] = true,
    [decks.DESTRUCTION] = true,
    [decks.SUMMONING] = true,
    [decks.PUNISHMENT] = true,
}

-- Include the effective definition's path in a modding error. A replacement
-- file can change weights without changing this validation owner.
local function invalid(definition, detail)
    local origin = register.origin(categories.CARDS, definition.id)

    error(origin .. ": card " .. definition.id .. " " .. detail)
end

-- Check the stable identity, visible name, effect hook path, and every
-- positive deck weight. The effect module is loaded by the effect owner.
function cards.validate_definition(definition)
    if type(definition.id) ~= "string" or
        not definition.id:match("^CARD_[A-Z0-9_]+$") then
        invalid(definition, "has an invalid ID")
    end

    if type(definition.name) ~= "string" or
        definition.name == "" then
        invalid(definition, "needs a display name")
    end

    if type(definition.effect_module) ~= "string" or
        not definition.effect_module:match("^policy%.[a-z0-9_.]+$") then
        invalid(definition, "needs an effect module")
    end

    if type(definition.deck_weights) ~= "table" or
        next(definition.deck_weights) == nil then
        invalid(definition, "needs deck weights")
    end

    for deck_id, weight in pairs(definition.deck_weights) do
        if not known_decks[deck_id] then
            invalid(definition, "names unknown deck " .. tostring(deck_id))
        end

        if type(weight) ~= "number" or weight % 1 ~= 0 or weight <= 0 then
            invalid(definition, "has invalid weight in " .. deck_id)
        end
    end
end

-- Check the winning definitions, not per-file declarations from overlaid
-- layers. A deck with no cards would make source weighted draws impossible.
function cards.validate()
    local totals = {}

    for _, definition in ipairs(catalog.all(categories.CARDS)) do
        cards.validate_definition(definition)

        for deck_id, weight in pairs(definition.deck_weights) do
            totals[deck_id] = (totals[deck_id] or 0) + weight
        end
    end

    for _, deck_id in ipairs(player_decks) do
        if not totals[deck_id] then
            error("card catalog has no cards in " .. deck_id)
        end
    end

    if not totals[decks.PUNISHMENT] then
        error("card catalog has no punishment cards")
    end
end

return cards
