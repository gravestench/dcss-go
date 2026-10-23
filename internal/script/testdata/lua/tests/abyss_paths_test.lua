-- Exit and depth-stair rolls use the same production path policy as a
-- generated window. The fixture controls only named RNG outcomes.
local abyss = require("constants.abyss")
local harness = require("tests.harness")
local paths = require("policy.generation.abyss.paths")
local terrain = require("constants.terrain")
local component = require("constants.component")
local items = require("ids.items")

local test = {}

-- Mirror the production rune ledger without redeclaring its schema.
local function rune_context(owned)
    local ctx = {}
    local player = {}

    function ctx:player()
        return player
    end

    function ctx:get(entity, name)
        harness.equal(entity, player)
        harness.equal(name, component.PLAYER_RUNES)

        return {
            collected = owned and { [items.RUNE_ABYSSAL] = true } or {},
        }
    end

    return ctx
end

-- Possession applies the source's maximum escape depth immediately,
-- while an uncollected rune still uses the current branch depth.
function test.rune_improves_exit_chance()
    local state = { branch_depth = 3 }

    harness.equal(paths.exit_chance(rune_context(false), state), 6000)
    harness.equal(paths.exit_chance(rune_context(true), state), 1000)
end

-- A clear square is a deterministic placement site without an authored
-- vault. The protected center models terrain carried through a shift.
local function floor_cells()
    local cells = {}

    for y = 1, abyss.HEIGHT do
        cells[y] = {}

        for x = 1, abyss.WIDTH do
            cells[y][x] = terrain.DNGN_FLOOR
        end
    end

    return cells
end

-- Force only exit rolls, then confirm neither the protected source cell
-- nor the last-depth stair policy is overwritten by a depth feature.
function test.exits_respect_protection()
    local ctx = rune_context(false)

    function ctx:random(_, bound)
        return bound > 2000 and 0 or 1
    end

    function ctx:random_u64()
        return 0, 17
    end

    local cells = floor_cells()
    local protected = { ["40:35"] = true }
    local exits
    local stairs

    cells, _, _, _, exits, stairs = paths.place(ctx, cells, {
        branch_depth = 1,
    }, protected)

    harness.truthy(exits > 0)
    harness.equal(stairs, 0)
    harness.equal(cells[36][41], terrain.DNGN_FLOOR)
    harness.truthy(exits > 0)
end

-- A source downward stair exists through depth six and stops at the
-- branch's declared bottom; no fixed Dungeon link is required.
function test.stairs_stop_at_bottom()
    local ctx = rune_context(false)

    function ctx:random(_, bound)
        return bound == 1750 and 0 or 1
    end

    local cells = floor_cells()
    local stairs

    cells, _, _, _, _, stairs = paths.place(ctx, cells, {
        branch_depth = 6,
    }, {})

    harness.truthy(stairs > 0)
    harness.equal(cells[2][2], terrain.DNGN_ABYSSAL_STAIR)

    cells = floor_cells()
    cells, _, _, _, _, stairs = paths.place(ctx, cells, {
        branch_depth = 7,
    }, {})

    harness.equal(stairs, 0)
    harness.equal(cells[2][2], terrain.DNGN_FLOOR)
end

-- The harness invokes one entry point, while the focused cases remain
-- named so a modder can read each source rule independently.
function test.run()
    test.rune_improves_exit_chance()
    test.exits_respect_protection()
    test.stairs_stop_at_bottom()
end

return test
