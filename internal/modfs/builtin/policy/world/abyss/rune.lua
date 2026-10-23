-- Theory of operation: the Abyssal rune is a normal ECS floor item.
-- Source generation first asks for a depth-eligible rune vault, then
-- falls back to a uniform random floor cell. The player's saved rune
-- ledger suppresses every later copy after pickup; a rune preserved by
-- a moving-window shift also suppresses a duplicate in the new edge.
local abyss = require("constants.abyss")
local component = require("constants.component")
local effects = require("constants.vault_effects")
local items = require("ids.items")
local runes = require("policy.character.runes")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.abyss.vaults")

local rune = {}

-- The source considers an uncollected rune already present only when it
-- survives this particular region move. An item on an erased edge is
-- removed and may be rolled again on a later generated area.
local function survives(ctx, mask)
    if not mask then
        return false
    end

    for _, entity in ipairs(ctx:query({
        component.ITEM,
        component.POSITION,
    })) do
        local item = ctx:get(entity, component.ITEM)
        local position = ctx:get(entity, component.POSITION)

        if item.kind_id == items.RUNE_ABYSSAL and
            position.level_id == abyss.LEVEL_ID and
            mask[position.x .. ":" .. position.y] then
            return true
        end
    end

    return false
end

-- Reservoir sampling gives each eligible floor cell one equal chance
-- without constructing a second large list of the 80x70 window.
local function fallback(ctx, level, protected)
    local chosen
    local found = 0

    for y = 1, abyss.HEIGHT - 2 do
        for x = 1, abyss.WIDTH - 2 do
            if level.cells[y + 1][x + 1] == terrain.DNGN_FLOOR and
                not protected[x .. ":" .. y] and
                (x ~= level.entry_x or y ~= level.entry_y) then
                found = found + 1

                if ctx:random("abyss-rune", found) == 0 then
                    chosen = { x = x, y = y }
                end
            end
        end
    end

    return chosen
end

-- KITEM in a tagged DES map records a concrete rune request. Retain
-- its source record for save inspection, but publish one ECS item from
-- that coordinate at the action barrier rather than inventing a second
-- item through the fallback pass.
local function tagged_rune(records)
    for _, record in ipairs(records) do
        if record.kind == effects.ITEM and
            record.arguments and
            record.arguments.kind_id == items.RUNE_ABYSSAL then
            record.pending = false

            return { x = record.x, y = record.y }
        end
    end

    return nil
end

-- Plan source chance and placement before any live grid mutation. The
-- caller then stages the returned level and calls rune.spawn only after
-- replace_region has installed its pending terrain view.
function rune.plan(ctx, level, state, protected, surviving_mask)
    local player = ctx:player()

    if state.branch_depth < abyss.RUNE_MIN_DEPTH or
        runes.has(ctx, player, items.RUNE_ABYSSAL) or
        survives(ctx, surviving_mask) then
        return nil
    end

    local roll = math.floor(abyss.RUNE_CHANCE_BASE ^
        (state.branch_depth / abyss.RUNE_CHANCE_DIVISOR))

    if ctx:random("abyss-rune", abyss.RUNE_MAX_ROLL) >= roll then
        return nil
    end

    local placed = vaults.place_tagged(ctx, level.cells,
        state, protected, "abyss_rune")

    if placed then
        level.cells = placed.cells
        level.vault_ids[#level.vault_ids + 1] = placed.id

        for _, point in ipairs(placed.occupied) do
            protected[point.x .. ":" .. point.y] = true
        end

        for _, record in ipairs(placed.records) do
            level.vault_records[#level.vault_records + 1] = record
        end

        for _, id in ipairs(placed.vault_ids or {}) do
            if id ~= placed.id then
                level.vault_ids[#level.vault_ids + 1] = id
            end
        end

        -- The generator and state may share this list while planning.
        -- Assign one completed list instead of appending each ID twice.
        state.selected_map_ids = level.vault_ids

        local location = tagged_rune(placed.records)

        if location then
            return location
        end
    end

    return fallback(ctx, level, protected)
end

-- Position and item identity use the same ECS schemas as ordinary
-- generated floor loot, so pickup and permanent rune progress need no
-- Abyss-specific item implementation.
function rune.spawn(ctx, location)
    if not location then
        return
    end

    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = items.RUNE_ABYSSAL,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(item, component.POSITION, {
        level_id = abyss.LEVEL_ID,
        x = location.x,
        y = location.y,
    })
end

return rune
