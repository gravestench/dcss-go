-- Hall layouts retain the pinned source metadata, primitive geometry, and
-- validation thresholds through the real DES discovery and hook path.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local depth = require("policy.generation.vaults.depth")
local harness = require("tests.harness")
local runtime = require("policy.generation.layouts.halls_runtime")
local shapes = require("policy.generation.layouts.halls_layers_shapes")
local halls_noise = require("policy.generation.layouts.halls_noise")
local weights = require("policy.generation.vaults.weight")

local test = {}

-- A saved-stream-shaped deterministic context exercises real generation hooks.
local function context(seed)
    local state = seed
    local ctx = {}

    -- Keep each draw on the layout stream and avoid platform integer overflow.
    function ctx:random_u64(stream)
        harness.equal(stream, "layout", "hall random stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return ctx
end

-- Direct helper calls use the same effective dimensions as ordinary levels.
local function api_for(seed)
    return {
        ctx = context(seed),
        branch = "Zot",
        branch_bottom = 5,
        depth = 2,
        absolute_depth = 24,
        width = 80,
        height = 70,
    }
end

-- These numerical fixtures were compiled from pinned perlin.cc and worley.cc
-- with their original headers and only AppHdr.h removed. They test exact source
-- hashes, Poisson counts, LCG overflow, density normalization, and 3D sampling.
local function exact_source_noise()
    local samples = {
        {
            x = 0.1,
            y = 0.2,
            z = 0.3,
            simplex = 0.63589036799999976,
            worley = 0.33844622753460674,
        },
        {
            x = 101.25,
            y = 103.5,
            z = 104.75,
            simplex = 0.049070974794237471,
            worley = 0.14790445868143909,
        },
        {
            x = 35.75,
            y = 0.25,
            z = 810.5,
            simplex = 0.55676559927966318,
            worley = 0.34766844704190869,
        },
        {
            x = 1000000,
            y = 499999.75,
            z = 9.25,
            simplex = 0.35257812517076498,
            worley = 0.061903997018430301,
        },
    }

    for _, sample in ipairs(samples) do
        local field = {
            scale = 1,
            x = 0,
            y = 0,
            z = sample.z,
            cache = {},
        }
        local simplex = halls_noise.simplex_at(field, sample.x, sample.y)

        field.z = 0

        local worley = halls_noise.worley_at(field, sample.x, sample.y, sample.z)

        harness.truthy(
            math.abs(simplex - sample.simplex) < 0.000000001,
            "pinned C++ simplex sample: " .. tostring(simplex)
        )
        harness.truthy(
            math.abs(worley - sample.worley) < 0.000000001,
            "pinned C++ Worley sample: " .. tostring(worley)
        )
    end
end

-- Pin field formulas independently of broad terrain plausibility checks.
local function primitive_geometry()
    local env = runtime.new(api_for(741))
    local primitive = env.primitive
    local procedural = env.procedural

    harness.equal(primitive.distance(3, 4), 5, "source Euclidean primitive")
    harness.equal(primitive.box(-3, 2), 3, "source box primitive")
    harness.equal(primitive.diamond()(3, -2), 5, "source diamond primitive")
    harness.equal(primitive.octagon(2)(3, 3), 4, "source octagon clipping")
    harness.equal(primitive.hexagon(2)(3, 3), 6, "source hexagon warp")
    harness.equal(primitive.cross()(3, -2), 2, "source cross primitive")
    harness.equal(primitive.ex()(3, -2), 1, "source diagonal cross")
    harness.equal(procedural.phase(primitive.radial, 4, 0.25)(0, 1), 0.25, "source angular phase")
    harness.equal(procedural.scale(primitive.box, 2, 4)(6, 8), 3, "source anisotropic domain scaling")

    env.extend_map({ fill = "x" })
    env.octa_room({
        x1 = 10,
        y1 = 10,
        x2 = 20,
        y2 = 20,
        oblique = 3.5,
        replace = "x",
        inside = ".",
        outside = "x",
    })

    harness.equal(env.mapgrd[10][12], "x", "octagon clips corner")
    harness.equal(env.mapgrd[10][13], ".", "C++ truncates oblique")
    harness.equal(env.mapgrd[13][10], ".", "octagon reaches straight side")
    harness.equal(env.mapgrd[20][17], ".", "inclusive octagon opposite side")

    local field = halls_noise.worley(env.builder, 0.2)
    local flat = halls_noise.worley_at(field, 3, 7, 0)
    local wrapped = halls_noise.worley_at(field, 3, 7, 20)

    harness.equal(flat, halls_noise.worley_at(field, 3, 7, 0), "Worley sampling remains pure")
    harness.truthy(flat ~= wrapped, "cathedral retains cylinder z coordinate")
end

-- Source random_real uses one unbounded 64-bit draw and its lower 52 bits.
-- A million-step bounded draw shifts both field phases and later RNG draws.
local function source_real_draw()
    local calls = 0
    local ctx = {}

    function ctx:random_u64(stream)
        harness.equal(stream, "layout", "real draw stream")
        calls = calls + 1

        return 12345, 6789
    end

    local api = api_for(1)

    api.ctx = ctx

    local env = runtime.new(api)
    local actual = env.crawl.random_real()
    local expected = (12345 * 4294967296 + 6789) / 4503599627370496

    harness.truthy(math.abs(actual - expected) < 0.000000000000001,
        "pinned 52-bit random fraction")
    harness.equal(calls, 1, "one unbounded draw")
end

-- Exercise every weighted motif constructor, including the rare gears and spiral.
-- A missing helper must fail here even when a seeded catalog draw avoids that motif.
local function complete_layer_motifs()
    local env = runtime.new(api_for(171))
    local groups = {
        shapes.primary(env, 3),
        shapes.outer(env, 3, 70),
        shapes.inner(env, 3, 70),
    }

    harness.equal(#groups[1], 4, "source primary motif count")
    harness.equal(#groups[2], 7, "source outer motif count")
    harness.equal(#groups[3], 12, "source central motif count")

    for _, group in ipairs(groups) do
        for _, choice in ipairs(group) do
            local field = choice.func()
            local value = field(7, 11)

            harness.truthy(
                type(value) == "number" and value == value,
                "every source hall motif constructs a finite field"
            )
            harness.equal(field(7, 11), value, "source motif sampling is pure")
        end
    end

    local bounds = {}

    -- Expose source random2avg bounds without depending on a particular RNG value.
    function env.crawl.random2(bound)
        bounds[#bounds + 1] = bound

        return bound - 1
    end

    harness.equal(env.crawl.random2avg(4, 2), 3, "source asymmetric average result")
    harness.equal(bounds[1], 4, "source first average bound")
    harness.equal(bounds[2], 5, "source later average bound")
end

-- Diagonal source zones must survive together; the unrelated island is sealed.
local function source_zones_and_validation()
    local env = runtime.new(api_for(77))

    env.mapgrd[10][10] = "."
    env.mapgrd[11][11] = "W"
    env.mapgrd[30][30] = "."
    env.zonify.map_fill_zones(env, 1, "x")

    harness.equal(env.mapgrd[10][10], ".", "source keeps diagonal floor")
    harness.equal(env.mapgrd[11][11], "W", "source groups shallow water as floor")
    harness.equal(env.mapgrd[30][30], "x", "source seals smaller zone")

    local result = env.result()

    for x = 1, 56 do
        for y = 1, 10 do
            env.mapgrd[x][y] = "."
        end
    end

    env.mapgrd[11][11] = "x"
    env.mapgrd[10][10] = "."
    harness.equal(runtime.minimum_area(result, 10, "."), false, "source rejects exactly ten percent")
    env.mapgrd[57][1] = "."
    harness.truthy(runtime.minimum_area(result, 10, "."), "source accepts strictly more than ten percent")
end

-- Every source declaration remains effective and every hook produces full terrain.
local function source_catalog()
    local cases = {
        {
            id = "layout_hall_layers",
            branch = branches.BRANCH_LAIR,
            depth = 2,
            bottom = 5,
            weight = 7,
        },
        {
            id = "layout_onion",
            branch = branches.BRANCH_SNAKE,
            depth = 2,
            bottom = 4,
            weight = 10,
        },
        {
            id = "layout_catacombs",
            branch = branches.BRANCH_CRYPT,
            depth = 2,
            bottom = 3,
            weight = 10,
        },
        {
            id = "layout_onion_interference",
            branch = branches.BRANCH_ZOT,
            depth = 2,
            bottom = 5,
            weight = 10,
        },
        {
            id = "layout_cathedral_of_symmetry",
            branch = branches.BRANCH_ZOT,
            depth = 5,
            bottom = 5,
            weight = 10,
        },
        {
            id = "layout_concentric_octagons",
            branch = branches.BRANCH_ZOT,
            depth = 2,
            bottom = 5,
            weight = 10,
        },
        {
            id = "layout_concentric_octagons",
            branch = branches.BRANCH_SNAKE,
            depth = 2,
            bottom = 4,
            weight = 5,
        },
        {
            id = "layout_catacombs",
            branch = branches.BRANCH_TARTARUS,
            depth = 2,
            bottom = 7,
            weight = 10,
        },
        {
            id = "layout_cathedral_of_symmetry",
            branch = branches.BRANCH_TARTARUS,
            depth = 2,
            bottom = 7,
            weight = 10,
        },
    }

    for _, case in ipairs(cases) do
        local definition = catalog.get(case.id)

        harness.equal(
            weights.for_branch(definition, case.branch),
            case.weight,
            case.id .. " source branch weight"
        )
        harness.truthy(
            depth.eligible(definition, case.branch, case.depth, case.bottom),
            case.id .. " source branch eligibility"
        )

        local result = catalog.execute(context(7291), definition, case.branch, case.depth)
        local floor = 0

        harness.truthy(#result.stairs >= 3, case.id .. " shared stairs")
        harness.equal(#result.rows, result.builder.height, case.id .. " effective height")

        for _, row in ipairs(result.rows) do
            harness.equal(#row, result.builder.width, case.id .. " effective width")
            harness.equal(row:find("[x@]"), nil, case.id .. " no temporary source markers")

            for glyph in row:gmatch(".") do
                if glyph == "." then
                    floor = floor + 1
                end
            end
        end

        harness.truthy(floor > 80, case.id .. " substantive source geometry")
    end

    local catacombs = catalog.get("layout_catacombs")
    local interference = catalog.get("layout_onion_interference")
    local octagons = catalog.get("layout_concentric_octagons")

    harness.equal(
        depth.eligible(catacombs, branches.BRANCH_CRYPT, 3, 3),
        false,
        "catacombs excludes Crypt bottom"
    )
    harness.equal(
        depth.eligible(interference, branches.BRANCH_ZOT, 5, 5),
        false,
        "interference excludes Zot bottom"
    )
    harness.truthy(octagons.tags.no_rotate, "octagon source no_rotate")
    harness.truthy(octagons.tags.no_hmirror, "octagon source no_hmirror")
    harness.truthy(octagons.tags.no_vmirror, "octagon source no_vmirror")
end

-- Run mathematical contracts before exercising real branch-specific layouts.
function test.run()
    source_real_draw()
    exact_source_noise()
    primitive_geometry()
    complete_layer_motifs()
    source_zones_and_validation()
    source_catalog()
end

return test
