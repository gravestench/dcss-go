-- Serial controllers place related DES maps through one bounded Lua API.
local catalog = require("policy.generation.vaults.catalog")
local selection = require("policy.generation.vaults.selection")

local controller = {}
local MAX_CHILD_MAPS = 1000

-- Controller random choices use the same layout stream as their maps, so
-- a saved RNG state reproduces the entire serial family on first entry.
function controller.roll(api, bound)
    return api.builder:roll(bound)
end

-- Certain and impossible chances skip a draw, matching source controller
-- functions that call x_chance_in_y with boundary values.
function controller.chance(api, numerator, denominator)
    return numerator >= denominator or
        (numerator > 0 and api:roll(denominator) < numerator)
end

-- Use the builder's one-in primitive for source one_chance_in decisions.
function controller.one_in(api, bound)
    return api.builder:one_in(bound)
end

-- Turn one bounded draw into the source controller's inclusive interval.
function controller.random_range(api, first, last)
    return first + api:roll(last - first + 1)
end

-- A controller can span branches; absolute depth is an optional supplied
-- fact, with its current local depth as the Dungeon fallback.
function controller.absolute_depth(api)
    return api.context.absolute_depth or api.context.depth
end

-- Keep the tag request separate from its parent so a child hook sees its
-- own map_tag without changing the next sibling's player context.
local function child_context(parent, tag)
    local child = {}

    for name, value in pairs(parent) do
        child[name] = value
    end

    child.player = {}

    for name, value in pairs(parent.player or {}) do
        child.player[name] = value
    end

    child.player.map_tag = tag
    child.ignore_chance = true

    return child
end

-- Place related maps in request order. A missing tag ends that request;
-- a malformed map still errors so the level never saves an incomplete set.
function controller.place_maps(api, tag, count)
    if type(count) ~= "number" or count < 0 or
        count > MAX_CHILD_MAPS or count ~= math.floor(count) then
        error("serial controller requested an invalid map count")
    end

    local placed_count = 0

    for _ = 1, count do
        local child = child_context(api.context, tag)
        local selected = selection.choose_tag(api.builder, tag, child)

        if not selected then
            return placed_count
        end

        local vault = catalog.get(selected.id)
        local map, reason = api.place(nil, api.builder, vault, child)

        if not map then
            error("cannot place vault " .. vault.id ..
                ": " .. tostring(reason))
        end

        api.placed[#api.placed + 1] = map
        api.context.used:add(vault)
        placed_count = placed_count + 1
    end

    return placed_count
end

-- Bind one ephemeral controller object to its builder, level facts, and
-- already placed maps. Source-specific policy remains in its own Lua file.
function controller.new(builder, context, placed, place)
    local api = {
        builder = builder,
        context = context,
        placed = placed,
        place = place,
    }

    api.roll = controller.roll
    api.chance = controller.chance
    api.one_in = controller.one_in
    api.random_range = controller.random_range
    api.absolute_depth = controller.absolute_depth
    api.place_maps = controller.place_maps

    return api
end

return controller
