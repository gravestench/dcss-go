-- Theory of operation: picking up a rune consumes its floor item and adds
-- its stable item ID to the player's saved rune set. Pan placement reads
-- this player-owned progress rather than searching current inventory or
-- interpreting a transient floor item.
local catalog = require("policy.catalog")
local classes = require("ids.object_classes")
local component = require("constants.component")
local pan = require("constants.runes")

local runes = {}

-- A new character starts with an empty set; restore uses the saved set.
function runes.initialise(ctx, player)
    ctx:add(player, component.PLAYER_RUNES, {
        collected = {},
    })
end

-- Only a defined rune item can be committed to permanent progress.
function runes.collect(ctx, player, kind_id)
    local definition = catalog.get("items", kind_id)

    if definition.class ~= classes.OBJ_RUNES then
        error("cannot collect a non-rune item " .. kind_id)
    end

    local state = ctx:get(player, component.PLAYER_RUNES)

    if not state then
        error("player rune progress is missing")
    end

    if state.collected[kind_id] then
        error("rune was already collected " .. kind_id)
    end

    state.collected[kind_id] = true
    ctx:set(player, component.PLAYER_RUNES, state)
end

-- A rune remains found after its floor entity has been destroyed.
function runes.has(ctx, player, kind_id)
    local state = ctx:get(player, component.PLAYER_RUNES)

    return state and state.collected[kind_id] or false
end

-- Zot checks the total set of distinct collected runes. Count saved player
-- progress rather than looking for inventory stacks the source never stores.
function runes.count(ctx, player)
    local state = ctx:get(player, component.PLAYER_RUNES)

    if not state then
        error("player rune progress is missing")
    end

    local count = 0

    for _, collected in pairs(state.collected) do
        if collected then
            count = count + 1
        end
    end

    return count
end

-- Ignacio's source chance uses only the four Pan runes, not the total
-- number collected across Dungeon Crawl's other branches.
function runes.pan_count(ctx, player)
    local count = 0

    for _, kind_id in pairs(pan) do
        if runes.has(ctx, player, kind_id) then
            count = count + 1
        end
    end

    return count
end

-- Reject malformed save entries before they influence branch generation.
function runes.validate(state)
    if not state or not state.collected then
        error("player rune progress is missing")
    end

    for kind_id, collected in pairs(state.collected) do
        local okay, definition = pcall(catalog.get, "items", kind_id)

        if not collected or not okay or
            definition.class ~= classes.OBJ_RUNES then
            error("invalid collected rune " .. kind_id)
        end
    end
end

return runes
