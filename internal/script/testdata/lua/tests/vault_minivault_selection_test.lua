-- Ordinary minivault draws use source ORIENT, DEPTH, CHANCE, and tags.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.generation.vaults.catalog")
local eligibility = require("policy.generation.vaults.eligibility")
local harness = require("tests.harness")
local ids = require("ids.vaults")
local minivault = require("policy.generation.vaults.minivault")
local used = require("policy.generation.vaults.used")

local test = {}

-- Find one candidate by ID without depending on how many more source maps
-- the catalog gains in later content imports.
local function contains(candidates, id)
    for _, candidate in ipairs(candidates) do
        if candidate.definition.id == id then
            return true
        end
    end

    return false
end

-- Depth selection takes a real minivault with a source DEPTH, while
-- controllers, oriented maps, and depthless tagged helpers stay out.
local function source_pool_boundaries()
    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "rooms",
        used = used.new({}),
        player = {},
    }
    local candidates = minivault.candidates(context)

    harness.truthy(contains(candidates, ids.eino_curves_01),
        "depth-qualified curved corridor is a minivault")
    harness.truthy(contains(candidates, ids.serial_bayou_pond_a),
        "depth-qualified bayou pond is a minivault")
    harness.truthy(contains(candidates, ids.primary_mini_dummy),
        "source chance dummy joins the minivault selector")
    harness.falsy(contains(candidates, ids.shop),
        "depthless shop helper is not a random map")
    harness.falsy(contains(candidates, ids.serial_rivers),
        "CHANCE controller is outside ordinary pool")
    harness.falsy(contains(candidates, ids.serial_bayou_shore_a),
        "oriented shore is a regular vault")

    for index = 2, #candidates do
        harness.truthy(candidates[index - 1].definition.id <
            candidates[index].definition.id,
            "weighted candidates have stable ID order")
    end

    context.used:add(catalog.get(ids.serial_bayou_lake_a))

    harness.falsy(contains(minivault.candidates(context),
        ids.serial_bayou_lake_a),
        "a placed nonduplicable minivault leaves the pool")
end

-- One weighted draw reaches the first or last candidate by cumulative
-- source weight; file discovery and path names do not enter the choice.
local function weighted_draw_uses_id_order()
    local context = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "rooms",
        excluded = {
            [ids.primary_mini_dummy] = true,
        },
        used = used.new({}),
        player = {},
    }
    local candidates = minivault.candidates(context)
    local random = {}

    -- Zero chooses the first positive-weight candidate.
    function random:roll()
        return 0
    end

    harness.equal(minivault.choose(random, candidates, context).id,
        candidates[1].definition.id, "first weighted choice")

    -- The final point in the supplied total reaches the last candidate.
    function random:roll(bound)
        return bound - 1
    end

    harness.equal(minivault.choose(random, candidates, context).id,
        candidates[#candidates].definition.id, "last weighted choice")
end

-- Layout restrictions are a shared source eligibility rule for both
-- CHANCE controllers and ordinary depth-selected maps.
local function layout_filter_is_shared()
    local curves = catalog.get(ids.serial_curves)

    harness.truthy(eligibility.layout(curves, "rooms"),
        "rooms layout admits curved controller")
    harness.falsy(eligibility.layout(curves, "halls"),
        "other layouts reject curved controller")
end

-- Restrict one policy test to named production maps while letting the
-- bundled catalog keep growing independently of this fixture.
local function only_named(ids_to_keep)
    local keep = {}
    local excluded = {}

    for _, id in ipairs(ids_to_keep) do
        keep[id] = true
    end

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        if not keep[id] then
            excluded[id] = true
        end
    end

    return {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 4,
        branch_bottom = 15,
        layout_family = "rooms",
        excluded = excluded,
        used = used.new({}),
        player = {},
    }
end

-- An extra requests another weighted draw. A non-extra map ends the
-- stage; both successful IDs join the same saved map-use history.
local function extra_then_regular_stops()
    local context = only_named({
        ids.eino_curves_01,
        ids.serial_bayou_lake_a,
    })
    local builder = {}
    local draws = 0
    local placed = {}

    -- First choose the early extra ID, then the later regular ID.
    function builder:roll(bound)
        draws = draws + 1

        return draws == 1 and 0 or bound - 1
    end

    -- Geometry is covered by family tests; this callback isolates the
    -- stage's draw and save order using real catalog definitions.
    local function place(_, _, vault)
        return {
            id = vault.id,
        }
    end

    local primary = minivault.place(nil, builder, context, placed, place)

    harness.equal(primary, ids.eino_curves_01,
        "first successful map remains the primary extra")
    harness.equal(#placed, 2, "extra redraw placed a second map")
    harness.equal(placed[2].id, ids.serial_bayou_lake_a,
        "regular map ended the stage")
    harness.equal(context.used:ids()[2], placed[2].id,
        "later minivault enters saved history")
end

-- When the entire eligible pool is extra and every fit fails, a finite
-- source-sized bound prevents an endless generation loop.
local function all_extra_pool_is_bounded()
    local context = only_named({ ids.eino_curves_01 })
    local builder = {}
    local attempts = 0

    -- The only eligible weighted map wins every draw.
    function builder:roll()
        return 0
    end

    -- Simulate geometric misses; no ID is marked used after a failed fit.
    local function reject_fit()
        attempts = attempts + 1

        return nil
    end

    minivault.place(nil, builder, context, {}, reject_fit)

    harness.equal(attempts, 10000,
        "all-extra retry count has the source finite bound")
    harness.equal(#context.used:ids(), 0,
        "failed fits do not consume map IDs")
end

-- The pool, draw, and compatibility checks cover the source selection
-- contract independently of a single generated-floor seed.
function test.run()
    source_pool_boundaries()
    weighted_draw_uses_id_order()
    layout_filter_is_shared()
    extra_then_regular_stops()
    all_extra_pool_is_bounded()
end

return test
