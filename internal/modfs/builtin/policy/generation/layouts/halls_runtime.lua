-- Theory of operation: the pinned hall scripts use a small source builder API.
-- Bind that API to one Lua grid and layout RNG, translating x to ordinary rock
-- at the boundary. Eight-neighbor source zoning, source octagon clipping, and
-- source smear limits remain here so shared four-neighbor helpers stay distinct.
local grid = require("policy.generation.grid")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local fields = require("policy.generation.layouts.halls_fields")

local runtime = {}

local directions = {
    {
        x = 0,
        y = -1,
    },
    {
        x = -1,
        y = 0,
    },
    {
        x = 0,
        y = 1,
    },
    {
        x = 1,
        y = 0,
    },
    {
        x = -1,
        y = -1,
    },
    {
        x = -1,
        y = 1,
    },
    {
        x = 1,
        y = 1,
    },
    {
        x = 1,
        y = -1,
    },
}

-- Source C++ map coordinates truncate fractional Lua numbers on access.
local function integer(value)
    return value < 0 and math.ceil(value) or math.floor(value)
end

-- Source x and the runtime's # both mean ordinary rock; other glyphs survive.
local function source_glyph(glyph)
    return glyph == "#" and "x" or glyph
end

-- Source zonify groups eight neighboring floor cells, including shallow water.
-- Preserve discovery order for ties rather than using hash table traversal.
local function regions(builder, passable)
    local visited = {}
    local found = {}

    for x = 1, builder.width - 2 do
        for y = 1, builder.height - 2 do
            local key = y * builder.width + x

            if not visited[key] and passable(source_glyph(builder:cell(x, y))) then
                local queue = { {
                    x = x,
                    y = y,
                } }
                local first = 1

                visited[key] = true

                while first <= #queue do
                    local point = queue[first]

                    first = first + 1

                    for _, direction in ipairs(directions) do
                        local next_x = point.x + direction.x
                        local next_y = point.y + direction.y
                        local next_key = next_y * builder.width + next_x

                        if
                            next_x > 0
                            and next_x < builder.width - 1
                            and next_y > 0
                            and next_y < builder.height - 1
                            and not visited[next_key]
                            and passable(source_glyph(builder:cell(next_x, next_y)))
                        then
                            visited[next_key] = true
                            queue[#queue + 1] = {
                                x = next_x,
                                y = next_y,
                            }
                        end
                    end
                end

                found[#found + 1] = queue
            end
        end
    end

    return found
end

-- Strict percentage comparison matches minimum_map_area before stairs are added.
function runtime.minimum_area(result, percent, glyphs)
    local builder = result.builder
    local count = 0

    for x = 0, builder.width - 1 do
        for y = 0, builder.height - 1 do
            if glyphs:find(builder:cell(x, y), 1, true) then
                count = count + 1
            end
        end
    end

    return count > builder.width * builder.height * percent / 100
end

-- Bind every source helper to invocation-local data. No generated state lives
-- in module globals, so rejected draws and nested calls cannot share a map.
function runtime.new(api)
    local builder = grid.new(api.ctx, api.width, api.height)
    local records = {}
    local env = {
        builder = builder,
        crawl = {},
        util = {},
        dgn = {},
        you = {},
        zonify = {},
        theme = { D = {} },
    }
    local crawl = env.crawl
    local util = env.util

    -- Source random2 takes an integer bound, including values computed by Lua.
    function crawl.random2(bound)
        return builder:roll(integer(bound))
    end

    -- Inclusive source bounds are truncated before choosing a grid coordinate.
    function crawl.random_range(first, last)
        first = integer(first)
        last = integer(last)

        return first + builder:roll(math.max(1, last - first + 1))
    end

    -- Pinned crawl.random_real takes one 64-bit layout draw and converts its
    -- lower 52 bits to the exact fraction used for source field phases.
    function crawl.random_real()
        local hi, lo = api.ctx:random_u64("layout")

        return ((hi % 1048576) * 4294967296 + lo) / 4503599627370496
    end

    -- Source random2avg rolls max once, then max + 1 for the remaining draws.
    -- The asymmetric upper bound preserves its exact source mean.
    function crawl.random2avg(bound, count)
        local total = crawl.random2(bound)

        for _ = 2, count do
            total = total + crawl.random2(bound + 1)
        end

        return math.floor(total / count)
    end

    -- Coin flips share the same bounded draw as all other construction choices.
    function crawl.coinflip()
        return builder:one_in(2)
    end

    -- Preserve one-chance checks without allocating an independent RNG owner.
    function crawl.one_chance_in(bound)
        return builder:one_in(integer(bound))
    end

    -- Source probability checks skip draws for impossible and certain outcomes.
    function crawl.x_chance_in_y(chance, total)
        return builder:chance_in(chance, total)
    end

    -- Source continuous ranges interpolate one real draw between both limits.
    function util.random_range_real(first, last)
        return first + crawl.random_real() * (last - first)
    end

    -- The pinned utility uses reservoir selection, consuming one draw per row.
    -- A single combined weighted draw would alter all later source decisions.
    function util.random_weighted_from(key, choices)
        local total = 0
        local selected

        for _, choice in ipairs(choices) do
            local weight = choice[key] or 10

            total = total + weight

            if crawl.random2(total) < weight then
                selected = choice
            end
        end

        return selected
    end

    -- Source max_bounds stays full sized even on a smaller Hell builder map.
    function env.dgn.max_bounds()
        return grid.width, grid.height
    end

    -- Source builder_bounds follows the actual floor extent, including Hell.
    function env.dgn.builder_bounds()
        return builder.width, builder.height
    end

    -- Central primary vaults can request the source cathedral polar transform.
    function env.dgn.map_parameters()
        return api.map_parameters
    end

    -- Source branch lookup accepts lowercase aliases in catacombs and cathedral.
    function env.you.in_branch(branch)
        return api.branch:lower() == branch:lower()
    end

    -- The source Zot:5 branch-bottom rule is evaluated from branch metadata.
    function env.you.at_branch_bottom()
        return api.depth == api.branch_bottom
    end

    -- The column proxy preserves source mapgrd[x][y] while grid stores rows.
    -- Both reads and writes truncate fractional diagonal corridor coordinates.
    local function column(x)
        return setmetatable({}, {
            -- Source reads outside a clipped builder are treated as solid rock.
            __index = function(_, y)
                x = integer(x)
                y = integer(y)

                if x < 0 or y < 0 or x >= builder.width or y >= builder.height then
                    return "x"
                end

                return source_glyph(builder:cell(x, y))
            end,
            -- Full-size octagon drawing can extend beyond an effective map extent.
            __newindex = function(_, y, glyph)
                x = integer(x)
                y = integer(y)

                if x >= 0 and y >= 0 and x < builder.width and y < builder.height then
                    builder:set(x, y, glyph == "x" and "#" or glyph)
                end
            end,
        })
    end

    env.mapgrd = setmetatable({}, {
        -- Columns are cached per invocation, never shared between map attempts.
        __index = function(columns, x)
            local value = column(x)

            rawset(columns, x, value)

            return value
        end,
    })

    -- Source render extends an empty map with ordinary rock before sampling.
    function env.extend_map(params)
        for x = 0, builder.width - 1 do
            for y = 0, builder.height - 1 do
                env.mapgrd[x][y] = params.fill or "x"
            end
        end
    end

    -- Concentric octagons explicitly begin with an all-rock rectangle.
    function env.fill_area(params)
        env.extend_map(params)
    end

    -- Source octa_room uses inclusive bounds and C++ integer oblique clipping.
    function env.octa_room(params)
        local x1 = integer(params.x1)
        local y1 = integer(params.y1)
        local x2 = integer(params.x2)
        local y2 = integer(params.y2)
        local oblique = integer(params.oblique)

        for x = x1, x2 do
            for y = y1, y2 do
                local glyph = env.mapgrd[x][y]

                if not params.replace or params.replace:find(glyph, 1, true) then
                    local clip = math.max(oblique + x1 - x, 0) + math.max(oblique + x - x2, 0)
                    local inside = y >= y1 + clip and y <= y2 - clip

                    env.mapgrd[x][y] = inside and params.inside or params.outside
                end
            end
        end
    end

    -- Concentric plugs use a temporary stone glyph before returning to rock.
    function env.subst(declaration)
        local from, to = declaration:match("^(%S+)%s*=%s*(%S+)$")

        for x = 0, builder.width - 1 do
            for y = 0, builder.height - 1 do
                if env.mapgrd[x][y] == from then
                    env.mapgrd[x][y] = to
                end
            end
        end
    end

    -- Source smear retries up to ten times per requested change. Its x upper
    -- bound intentionally uses y2, preserving the pinned l-dgnbld.cc quirk.
    function env.smear_map(params)
        local changes = 0
        local attempts = 0

        while changes < params.iterations and attempts <= params.iterations * 10 do
            local x = crawl.random_range(1, builder.height - 2)
            local y = crawl.random_range(1, builder.height - 2)

            attempts = attempts + 1

            if env.mapgrd[x][y] == "." then
                local adjacent = false

                for _, direction in ipairs(directions) do
                    if env.mapgrd[x + direction.x][y + direction.y] == "x" then
                        adjacent = true
                        break
                    end
                end

                if adjacent then
                    env.mapgrd[x][y] = "x"
                    changes = changes + 1
                end
            end
        end
    end

    -- Source fill_disconnected keeps only zones containing the temporary @.
    function env.fill_disconnected(params)
        local passable = ".+=w@{}()[]<>BC^TUVY$%*|Odefghijk0123456789"
        local zones = regions(builder, function(glyph)
            -- Match the C++ traversable glyph set used by the source helper.
            return passable:find(glyph, 1, true) ~= nil
        end)

        for _, zone in ipairs(zones) do
            local wanted = false

            for _, point in ipairs(zone) do
                wanted = wanted or env.mapgrd[point.x][point.y] == params.wanted
            end

            if not wanted then
                for _, point in ipairs(zone) do
                    env.mapgrd[point.x][point.y] = params.fill or "x"
                end
            end
        end
    end

    -- The source wall alphabet deliberately treats shallow water W as floor.
    function env.zonify.map_fill_zones(_, _, glyph)
        local zones = regions(builder, function(value)
            -- A source floor zone can contain water as well as ordinary floor.
            return not ("wlxcvbtg"):find(value, 1, true)
        end)
        local largest

        for _, zone in ipairs(zones) do
            if #zone > 1 and (not largest or #zone > #largest) then
                largest = zone
            end
        end

        for _, zone in ipairs(zones) do
            if zone ~= largest then
                for _, point in ipairs(zone) do
                    env.mapgrd[point.x][point.y] = glyph or "x"
                end
            end
        end
    end

    -- Source material replacement uses absolute depth and per-cell c:c:v rolls.
    function env.theme.level_material()
        if
            api.branch == "Lair"
            or api.branch == "Zot"
            or api.branch == "Dis"
            or (api.absolute_depth or api.depth) < 4
            or not crawl.one_chance_in(20)
        then
            return
        end

        for x = 0, builder.width - 1 do
            for y = 0, builder.height - 1 do
                if env.mapgrd[x][y] == "x" then
                    env.mapgrd[x][y] = crawl.random2(3) == 2 and "v" or "c"
                end
            end
        end
    end

    -- A direct or modded Dungeon hall-layer invocation uses the full source
    -- cave theme table; Lair returns before any of these selection draws.
    function env.theme.D.caves()
        if api.branch ~= "D" then
            return
        end

        local variants = {
            {
                weight = 10,
                wall = "wall_pebble_lightgray",
                floor = "floor_pebble_brown",
            },

            {
                weight = 1,
                wall = "wall_emerald",
                floor = "floor_pebble_green",
                glyph = "b",
            },

            {
                weight = 10,
                wall = "wall_pebble_darkgray",
                floor = "floor_pebble_brown",
            },

            {
                weight = 10,
                wall = "wall_pebble_lightgray",
                floor = "floor_pebble_darkgray",
            },

            {
                weight = 10,
                wall = "wall_pebble_brown",
                floor = "floor_pebble_darkgray",
            },

            {
                weight = 10,
                wall = "wall_pebble_brown",
                floor = "floor_pebble_darkbrown",
            },

            {
                weight = 10,
                wall = "wall_pebble_lightgray",
                floor = "floor_pebble_darkbrown",
            },

            {
                weight = 10,
                wall = "wall_pebble_white",
                floor = "floor_pebble_darkbrown",
            },

            {
                weight = 10,
                wall = "wall_pebble_darkbrown",
                floor = "floor_pebble_darkgray",
            },

            {
                weight = 10,
                wall = "wall_pebble_midbrown",
                floor = "floor_pebble_darkgray",
            },

            {
                weight = 10,
                wall = "wall_pebble_darkbrown",
                floor = "floor_pebble_darkbrown",
            },

            {
                weight = 10,
                wall = "wall_pebble_midbrown",
                floor = "floor_pebble_darkbrown",
            },
        }
        local chosen = util.random_weighted_from("weight", variants)

        if chosen.glyph then
            for x = 0, builder.width - 1 do
                for y = 0, builder.height - 1 do
                    if env.mapgrd[x][y] == "x" then
                        env.mapgrd[x][y] = chosen.glyph
                        records[#records + 1] = {
                            kind = effects.TILE,
                            directive = directives.TILE,
                            identity = chosen.wall,
                            source = chosen.glyph,
                            x = x,
                            y = y,
                            vault_id = api.definition and api.definition.id,
                            pending = true,
                        }
                    end
                end
            end
        else
            records[#records + 1] = {
                kind = effects.GENERATION_RULE,
                identity = "level_style",
                directive = directives.LROCKTILE,
                arguments = {
                    value = chosen.wall,
                },
                vault_id = api.definition and api.definition.id,
                pending = true,
            }
        end

        records[#records + 1] = {
            kind = effects.GENERATION_RULE,
            identity = "level_style",
            directive = directives.LFLOORTILE,
            arguments = {
                value = chosen.floor,
            },
            vault_id = api.definition and api.definition.id,
            pending = true,
        }
    end

    env.procedural, env.primitive, env.complex = fields.new(env)

    -- Validate the layout RNG before exposing terrain to the shared stair pass.
    function env.result()
        if builder.bad_random then
            error("hall layout random source failed to provide a bounded draw")
        end

        return {
            builder = builder,
            rows = builder:rows(),
            records = records,
        }
    end

    return env
end

return runtime
