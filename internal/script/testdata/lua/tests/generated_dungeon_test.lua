-- Pairing tests use the production grid and feature decoder. They supply a
-- small, already-built parent level because Go owns live occupancy and sight.
local features = require("content.terrain_features")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local stairs = require("policy.generation.generated_stairs")
local terrain = require("constants.terrain")

local test = {}

-- Three ordinary trails give each floor the same baseline stair count as
-- basic Dungeon generation, without spending random layout draws here.
local function floor(depth)
    local builder = grid.new({})

    for y = 1, 68 do
        for x = 1, 78 do
            builder:set(x, y, ".")
        end
    end

    local pairs = {
        {
            up = { x = 10, y = 10 },
            down = { x = 10, y = 20 },
        },

        {
            up = { x = 30, y = 10 },
            down = { x = 30, y = 20 },
        },

        {
            up = { x = 50, y = 10 },
            down = { x = 50, y = 20 },
        },
    }

    for _, pair in ipairs(pairs) do
        builder:set(pair.up.x, pair.up.y, "<")
        builder:set(pair.down.x, pair.down.y, ">")
    end

    return {
        depth = depth,
        layout = {
            builder = builder,
            stairs = pairs,
        },
        source_up = {},
        source_down = {},
        protected = {},
        links = {},
    }
end

-- Read source glyphs through the same decoder that the real scenario policy
-- uses, then expose only the live grid operations pairing needs.
local function parent_context(parent)
    local context = {
        cells = features.decode_source_rows(parent.layout.builder:rows()),
        occupied = {},
    }

    function context:cell(_, x, y)
        local row = self.cells[y + 1]

        return row and row[x + 1]
    end

    function context:actor_at(_, x, y)
        return self.occupied[x .. ":" .. y]
    end

    function context:walkable(_, x, y)
        local feature = self:cell(1, x, y)

        return feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_STONE_STAIRS_UP_I or
            feature == terrain.DNGN_STONE_STAIRS_DOWN_I
    end

    return context
end

-- First-floor up stairs are unavailable; every down stair has a named next
-- floor but no coordinate until that floor is generated.
local function first_floor_has_pending_downstairs()
    local first = floor(1)

    stairs.first(first, 15)

    harness.equal(#first.links, 6, "first floor baseline links")

    local pending = 0
    local unavailable = 0

    for _, link in ipairs(first.links) do
        if link.pending then
            pending = pending + 1
            harness.equal(link.to_level_id, 2, "pending destination depth")
        else
            unavailable = unavailable + 1
            harness.truthy(link.unavailable ~= "", "up stair boundary message")
        end
    end

    harness.equal(pending, 3, "three pending down stairs")
    harness.equal(unavailable, 3, "three unavailable up stairs")
end

-- An authored extra down stair on the parent receives a connected up
-- landing on the child, and the selected stair maps to its exact arrival.
local function extra_parent_down_gets_child_landing()
    local parent = floor(1)
    local child = floor(2)
    local extra = { x = 60, y = 30 }

    parent.source_down[1] = extra
    parent.layout.builder:set(extra.x, extra.y, ">")
    stairs.first(parent, 15)

    local context = parent_context(parent)
    local links, entry = stairs.pair(context, {
        id = 1,
        width = 80,
        height = 70,
        seen = {},
        stairs = parent.links,
    }, child, extra)

    harness.equal(#links, 4, "all parent down stairs paired")
    harness.truthy(entry, "selected source stair has an entry")
    harness.equal(child.layout.builder:cell(entry.x, entry.y), "<",
        "extra parent exit lands on an up stair")
end

-- A child vault may author another up exit. Add its parent departure only
-- on connected, unoccupied floor; the wall and active actor remain intact.
local function extra_child_up_gets_safe_parent_departure()
    local parent = floor(1)
    local child = floor(2)
    local extra = { x = 60, y = 30 }

    child.source_up[1] = extra
    child.layout.builder:set(extra.x, extra.y, "<")
    stairs.first(parent, 15)

    local context = parent_context(parent)
    context.occupied["12:20"] = 9
    context.cells[21][12] = terrain.DNGN_ROCK_WALL

    local links = stairs.pair(context, {
        id = 1,
        width = 80,
        height = 70,
        seen = {},
        stairs = parent.links,
    }, child, parent.layout.stairs[1].down)

    harness.equal(#links, 4, "child extra up stair gained a parent link")

    local added

    for _, link in ipairs(links) do
        if link.new then
            added = link
        end
    end

    harness.truthy(added, "new parent departure exists")
    harness.equal(context:cell(1, added.x, added.y), terrain.DNGN_FLOOR,
        "new parent departure uses floor")
    harness.falsy(context:actor_at(1, added.x, added.y),
        "new departure cannot replace an actor")
    harness.equal(context:cell(1, 11, 20), terrain.DNGN_ROCK_WALL,
        "wall remains unchanged")
end

-- Run each pairing shape against one owner, so additions cannot regress
-- ordinary or source-vault stairs independently.
function test.run()
    first_floor_has_pending_downstairs()
    extra_parent_down_gets_child_landing()
    extra_child_up_gets_safe_parent_departure()
end

return test
