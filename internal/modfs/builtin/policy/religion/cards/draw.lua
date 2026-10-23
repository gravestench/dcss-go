-- Theory of operation: a deck stores only its count. Drawing samples one
-- concrete card from the effective Lua catalog at the source weight, then
-- the operation owner spends that count and saves the sampled ID.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local decks = require("ids.decks")
local streams = require("constants.rng_streams")

local draw = {}

local random_decks = {
    [decks.ESCAPE] = true,
    [decks.DESTRUCTION] = true,
    [decks.SUMMONING] = true,
    [decks.PUNISHMENT] = true,
}

-- Example: a zero roll in Escape chooses the first stable card ID with
-- positive Escape weight. A mod's filename cannot alter that traversal.
function draw.sample(ctx, deck_id)
    if not random_decks[deck_id] then
        error("cannot sample card deck " .. tostring(deck_id))
    end

    local definitions = catalog.all(categories.CARDS)
    local total = 0

    for _, definition in ipairs(definitions) do
        total = total + (definition.deck_weights[deck_id] or 0)
    end

    if total <= 0 then
        error("card deck has no candidates " .. deck_id)
    end

    local choice = ctx:random(streams.CARDS, total)

    for _, definition in ipairs(definitions) do
        choice = choice - (definition.deck_weights[deck_id] or 0)

        if choice < 0 then
            return definition.id
        end
    end

    error("card selection exceeded deck " .. deck_id)
end

return draw
