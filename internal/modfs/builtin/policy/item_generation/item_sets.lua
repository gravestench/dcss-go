local streams = require("constants.rng_streams")
local component = require("constants.component")
local ids = require("ids.items")
local sets = require("constants.item_sets")

local item_sets = {}

-- Source: crawl-ref/source/item-prop.cc:728-734.
local definitions = {
    {
        id = sets.HEX_WANDS,
        kinds = {
            ids.WAND_CHARMING,
            ids.WAND_PARALYSIS,
        },
    },
    {
        id = sets.BEAM_WANDS,
        kinds = {
            ids.WAND_ACID,
            ids.WAND_LIGHT,
            ids.WAND_QUICKSILVER,
        },
    },
    {
        id = sets.BLAST_WANDS,
        kinds = {
            ids.WAND_ICEBLAST,
            ids.WAND_ROOTS,
        },
    },
    {
        id = sets.CONCEALMENT_SCROLLS,
        kinds = {
            ids.SCR_FOG,
            ids.SCR_BUTTERFLIES,
        },
    },
}

function item_sets.initialise(ctx, player)
    if ctx:has(player, component.PLAYER_ITEM_SETS) then
        return
    end

    local choices = {}

    for _, definition in ipairs(definitions) do
        local index = ctx:random(streams.ITEM_GENERATION, #definition.kinds) + 1

        choices[definition.id] = definition.kinds[index]
    end

    ctx:add(player, component.PLAYER_ITEM_SETS, {
        choices = choices,
    })
end

function item_sets.choice(ctx, player, set_id)
    local state = ctx:get(player, component.PLAYER_ITEM_SETS)

    if not state or not state.choices[set_id] then
        error("player item set " .. set_id .. " was not initialised")
    end

    return state.choices[set_id]
end

function item_sets.allowed(ctx, player, kind_id)
    local state = ctx:get(player, component.PLAYER_ITEM_SETS)

    if not state then
        error("player item sets were not initialised")
    end

    for _, definition in ipairs(definitions) do
        for _, candidate in ipairs(definition.kinds) do
            if candidate == kind_id then
                return state.choices[definition.id] == kind_id
            end
        end
    end

    return true
end

function item_sets.validate(state)
    if not state then
        error("player item sets are missing")
    end

    local expected = {}

    for _, definition in ipairs(definitions) do
        expected[definition.id] = true
        local choice = state.choices[definition.id]
        local found = false

        for _, candidate in ipairs(definition.kinds) do
            if candidate == choice then
                found = true
                break
            end
        end

        if not found then
            error("invalid player item set " .. definition.id)
        end
    end

    for id in pairs(state.choices) do
        if not expected[id] then
            error("unknown player item set " .. id)
        end
    end
end

return item_sets
