-- A timed Gauntlet entrance must be owned by its Lua portal handler and
-- keep the one source duration draw in a typed, inspectable marker.
local branches = require("ids.branches")
local features = require("content.terrain_features")
local effects = require("constants.vault_effects")
local depth = require("policy.generation.vaults.depth")
local eligibility = require("policy.generation.vaults.eligibility")
local gauntlet = require("constants.gauntlet")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local handlers = require("policy.world.portals.catalog")
local placement = require("policy.generation.vaults.placement")
local portal = require("policy.world.gauntlet.portal")
local terrain = require("constants.terrain")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- The real builder owns the draw; this fixture supplies only repeatable
-- random bits, not a second implementation of the portal duration rule.
local function seeded_context(seed)
    local value = seed
    local context = {}

    function context:random_u64()
        value = (value * 48271) % 2147483647

        return 0, value
    end

    function context:random(_stream, bound)
        self:random_u64()

        return value % bound
    end

    return context
end

-- The source O glyph must emit one gate marker at the same placement
-- coordinate. The handler should reject malformed or out-of-range clocks.
function test.run()
    harness.equal(handlers.owner(terrain.DNGN_ENTER_GAUNTLET),
        "gauntlet", "Gauntlet entry feature owner")
    harness.equal(handlers.owner(terrain.DNGN_EXIT_GAUNTLET),
        "gauntlet", "Gauntlet exit feature owner")

    local gate = vaults.get("gauntlet_entry_generic")
    local early = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 10,
        branch_bottom = 15,
        absolute_depth = 10,
    }
    local eligible = {
        branch_id = branches.BRANCH_DUNGEON,
        depth = 11,
        branch_bottom = 15,
        absolute_depth = 11,
    }

    harness.truthy(not eligibility.depth(gate, early),
        "Gauntlet gate appeared before D:11")
    harness.truthy(eligibility.depth(gate, eligible),
        "Gauntlet gate is absent at D:11")
    harness.equal(depth.chance(gate, branches.BRANCH_DUNGEON,
        11, 15, 11), 500, "source five-percent gate chance")

    local context = seeded_context(59)
    local player = eligible
    local builder = grid.new(context)
    local placed = placement.place(context, builder,
        vaults.get("gauntlet_entry_generic"), player, {})
    local cells = features.decode_source_rows(builder:rows())
    local records = features.apply_vault_terrain(cells,
        placed.records, context, 1)
    local timers = 0

    for _, record in ipairs(records) do
        if record.kind == effects.MARKER and
            portal.is_marker(record) then
            local duration = portal.parse(record.identity)

            harness.truthy(duration >= gauntlet.MIN_DURATION_TURNS and
                duration <= gauntlet.MAX_DURATION_TURNS,
                "source gate duration is outside its range")
            timers = timers + 1
        end
    end

    harness.equal(timers, 1, "source gate marker count")

    local okay = pcall(portal.parse,
        'lua:timed_marker { low = 399, high = 399, ' ..
        'single_timed = true, floor = "stone_arch" }')

    harness.truthy(not okay,
        "out-of-range gate duration was accepted")
end

return test
