-- Theory of operation: this source Ossuary draws one floor seed uniformly,
-- then floods outwards through eight-neighbor cells. Each visited source
-- glyph has its own weighted replacement list; doors and closed barriers
-- stop propagation. The map-local API preserves the same layout RNG stream.
local directives = require("constants.vault_directives")

local flooded = {}

local replacements = {
    ["."] = {
        { ".", 1 },
        { "W", 2 },
    },
    x = {
        { "x", 5 },
        { "w", 5 },
    },
    c = {
        { "c", 5 },
        { "w", 3 },
        { "W", 2 },
        { "x", 1 },
    },
    ["+"] = {
        { "+", 10 },
        { "W", 5 },
    },
    ["1"] = {
        { "2", 1 },
    },
}

-- The source utility draws once from a total weight, then walks entries
-- in declaration order. A map table would make that order unstable.
local function weighted_choice(api, choices)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice[2]
    end

    local draw = api:roll(total)

    for _, choice in ipairs(choices) do
        if draw < choice[2] then
            return choice[1]
        end

        draw = draw - choice[2]
    end

    error("Ossuary flood choice exceeded its weights")
end

-- Reservoir sampling consumes one source chance per floor candidate and
-- gives each candidate equal odds without building a second cell list.
local function floor_seed(api)
    local width, height = api:map_size()
    local count = 0
    local seed_x
    local seed_y

    for x = 0, width - 1 do
        for y = 0, height - 1 do
            if api:cell(x, y) == "." then
                count = count + 1

                if api:one_in(count) then
                    seed_x = x
                    seed_y = y
                end
            end
        end
    end

    if not seed_x then
        error("Ossuary flood has no floor seed")
    end

    return seed_x, seed_y
end

-- Queue order mirrors source dgn.flood: x-neighbors outside y-neighbors,
-- with the current cell skipped and a cell marked when it is enqueued.
-- The seed starts unmarked, exactly as the source helper does.
local function spread(api, seed_x, seed_y, distance)
    local width, height = api:map_size()
    local queue = {
        {
            x = seed_x,
            y = seed_y,
            distance = distance,
        },
    }
    local queued = {}
    local first = 1

    while first <= #queue do
        local point = queue[first]

        first = first + 1

        local source = api:cell(point.x, point.y)
        local choices = replacements[source]

        if choices then
            api:set_cell(point.x, point.y,
                weighted_choice(api, choices))
        end

        local remaining = point.distance - 1

        if source == "+" or source == "v" then
            remaining = 0
        end

        if remaining > 0 then
            for dx = -1, 1 do
                for dy = -1, 1 do
                    local x = point.x + dx
                    local y = point.y + dy
                    local key = x .. ":" .. y

                    if (dx ~= 0 or dy ~= 0) and
                        x >= 0 and y >= 0 and
                        x < width and y < height and
                        not queued[key] then
                        queue[#queue + 1] = {
                            x = x,
                            y = y,
                            distance = remaining,
                        }
                        queued[key] = true
                    end
                end
            end
        end
    end
end

-- Source script runs before SHUFFLE and SUBST, so the water works on the
-- authored glyphs and later substitutions still decide vault content.
local function flood(api)
    local x, y = floor_seed(api)

    spread(api, x, y, api:random_range(6, 16))
end

-- The old lrockcol choice is a typed presentation directive, not a Go
-- rendering special case for this one destination.
local function rock_colour(api)
    api:emit(directives.LROCKCOL, "brown")
end

flooded.flood = flood
flooded.rock_colour = rock_colour

return flooded
