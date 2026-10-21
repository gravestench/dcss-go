-- Theory of operation: choose weighted large, encircling, and central shapes,
-- union their distance fields, and threshold them at a shared hall width.
-- Lair may add Worley roughness before source eight-neighbor zone cleanup.
local runtime = require("policy.generation.layouts.halls_runtime")
local shapes = require("policy.generation.layouts.halls_layers_shapes")

local layout = {}

-- Select cave width before constructing pure factory tables. The pinned source
-- makes these same rolls after table allocation, which itself consumes no RNG.
local function choose_width(env)
    local crawl = env.crawl
    local you = env.you
    local cave = you.in_branch("D") and crawl.coinflip()
        or you.in_branch("Lair") and crawl.x_chance_in_y(2, 3)
    local width

    if cave then
        width = crawl.random_range(4, 6)
    else
        width = crawl.random_range(2, 3)
    end

    return width, cave
end

-- Reservoir-select all three source factories before constructing any field.
-- This order matters because field constructors themselves consume random draws.
local function layer_field(env, width, cave)
    local gxm, gym = env.dgn.max_bounds()
    local procedural = env.procedural
    local util = env.util
    local first = util.random_weighted_from("weight", shapes.primary(env, width))
    local second = util.random_weighted_from("weight", shapes.outer(env, width, gym))
    local third = util.random_weighted_from("weight", shapes.inner(env, width, gym))
    local field =
        procedural.translate(procedural.min(first.func(), second.func(), third.func()), gxm / 2, gym / 2)

    field = procedural.map(field, width / 2, width, 0, 1)

    if cave then
        field = procedural.add(field, procedural.worley_diff({ scale = 0.5 }))
    end

    return field
end

-- Render source layer interference, retain its largest zone, then apply theme.
function layout.layout_hall_layers(api)
    local env = runtime.new(api)
    local width, cave = choose_width(env)
    local field = layer_field(env, width, cave)

    -- Low union distance becomes hall floor; the source border stays rock.
    env.procedural.render_map(env, field, function(value)
        return value < 1 and "." or "x"
    end)
    env.zonify.map_fill_zones(env, 1, "x")

    if cave then
        env.theme.D.caves(env)
    else
        env.theme.level_material(env)
    end

    return env.result()
end

return layout
