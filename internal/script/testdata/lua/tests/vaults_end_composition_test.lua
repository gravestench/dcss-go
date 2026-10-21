-- The authored Vaults:$ layout must assemble source quadrants through the
-- same catalog and operation engine used by ordinary generated floors.
local branches = require("ids.branches")
local categories = require("constants.catalog")
local grid = require("policy.generation.grid")
local placement = require("policy.generation.vaults.placement")
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local items = require("ids.items")
local end_layout = require("policy.generation.layouts.vaults_vault")
local shared = require("policy.generation.vaults.vaults_end.shared")
local harness = require("tests.harness")
local layouts = require("policy.generation.layouts.catalog")
local tags = require("constants.vault_tags")
local vaults = require("policy.generation.vaults.catalog")

local test = {}

-- Give source hooks a deterministic layout stream without copying map rules.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64()
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- One successful composition needs four quadrant helpers, exactly one
-- real-rune helper, and no unresolved quadrant placeholders in its grid.
local function composed_end_floor(seed)
    local map = layouts.get("vaults_vault")
    local result = layouts.execute(context_for(seed), map,
        branches.BRANCH_VAULTS, 5, {
            up = 1,
            down = 0,
        }, {})
    local quadrants = 0
    local runes = 0

    for _, id in ipairs(result.vault_ids or {}) do
        local helper = vaults.get(id)

        if helper.tags[tags.VAULTS_END_QUADRANT] or
            helper.tags[tags.VAULTS_END_QUADRANT_PRIZE] then
            quadrants = quadrants + 1
        end

        if helper.tags[tags.VAULTS_END_RUNE] then
            runes = runes + 1
        end
    end

    harness.equal(quadrants, 4, "four source quadrant maps")
    harness.equal(runes, 1, "one real-rune helper")
    harness.equal(#result.rows, 70, "full-height level")
    harness.truthy(#result.records > 0, "typed source records")

    for _, row in ipairs(result.rows) do
        harness.falsy(row:find("[ABCD]"),
            "no unresolved quadrant placeholder")
    end

    local rune_items = 0

    for _, record in ipairs(result.records) do
        if record.kind == effects.ITEM and record.arguments and
            record.arguments.kind_id == items.RUNE_VAULTS then
            rune_items = rune_items + 1
        end
    end

    harness.equal(rune_items, 1, "one silver rune item record")
end

-- Every source quadrant must remain executable, including those with
-- dynamic inner rooms or unusual rotations. A single fixed seed per map
-- checks the entire catalog without duplicating its authored directives.
local function all_quadrants()
    local count = 0
    local player = {
        branch_id = branches.BRANCH_VAULTS,
        depth = 5,
        branch_bottom = 5,
        absolute_depth = 23,
    }

    for _, id in ipairs(register.ids(categories.VAULTS)) do
        local map = vaults.get(id)

        if map.tags[tags.VAULTS_END_QUADRANT] or
            map.tags[tags.VAULTS_END_QUADRANT_PRIZE] then
            local builder = grid.new(context_for(count + 23))
            local placed = placement.place(nil, builder, map, player)

            harness.equal(placed.id, id, "source quadrant placed")
            harness.truthy(#placed.occupied > 0,
                "quadrant painted source cells")
            count = count + 1
        end
    end

    harness.equal(count, 65, "all source quadrant maps")
end

-- The main named hook keeps the one-in-36 mall variant and one prize
-- selection in the source A position. SHUFFLE determines its physical side.
local function quadrant_modes()
    for _, mall in ipairs({ false, true }) do
        local emitted = {}
        local api = {}

        function api:one_in(bound)
            harness.equal(bound, 36, "source mall chance")

            return mall
        end

        function api:emit(kind, argument)
            harness.equal(kind, directives.SUBVAULT, "quadrant directive")
            emitted[#emitted + 1] = argument
        end

        end_layout.choose_quadrants(api)

        local prize = mall and tags.VAULTS_END_QUADRANT_PRIZE_MALL or
            tags.VAULTS_END_QUADRANT_PRIZE
        local ordinary = mall and tags.VAULTS_END_QUADRANT_MALL or
            tags.VAULTS_END_QUADRANT

        harness.equal(#emitted, 4, "four quadrant selectors")
        harness.equal(emitted[1], "A : " .. prize, "one prize selector")
        harness.equal(emitted[2], "B : " .. ordinary, "ordinary B")
        harness.equal(emitted[3], "C : " .. ordinary, "ordinary C")
        harness.equal(emitted[4], "D : " .. ordinary, "ordinary D")
    end
end

-- The shared hook gives the prize a first chance, then forces an ordinary
-- quadrant to supply the rune unless an earlier child already placed it.
local function rune_decisions()
    local cases = {
        {
            tag = tags.VAULTS_END_QUADRANT_PRIZE,
            prize_draw = true,
            placed = false,
            selected = tags.VAULTS_END_RUNE,
        },
        {
            tag = tags.VAULTS_END_QUADRANT_PRIZE,
            prize_draw = false,
            placed = false,
            selected = tags.VAULTS_END_NORUNE,
        },
        {
            tag = tags.VAULTS_END_QUADRANT,
            prize_draw = false,
            placed = false,
            selected = tags.VAULTS_END_RUNE,
        },
        {
            tag = tags.VAULTS_END_QUADRANT,
            prize_draw = false,
            placed = true,
            selected = tags.VAULTS_END_NORUNE,
        },
        {
            tag = tags.VAULTS_END_ROOM_RUNE,
            prize_draw = false,
            placed = false,
            selected = tags.VAULTS_END_RUNE,
        },
    }

    for _, case in ipairs(cases) do
        local selected
        local api = {}

        function api:has_tag(tag)
            return tag == case.tag
        end

        function api:has_placed_tag(tag)
            harness.equal(tag, tags.VAULTS_END_RUNE, "rune history tag")

            return case.placed
        end

        function api:one_in(bound)
            harness.equal(bound, 4, "source prize chance")

            return case.prize_draw
        end

        function api:emit(kind, argument)
            harness.equal(kind, directives.SUBVAULT, "rune directive")
            selected = argument
        end

        shared.rune(api)
        harness.equal(selected, "O : " .. case.selected,
            "rune slot selection")
    end
end

-- A partial or duplicated rune must fail the source end-map invariant
-- before a generated floor can be saved as a playable Vaults:5 level.
local function rejected_rune_counts()
    for _, count in ipairs({ 0, 2 }) do
        local records = {}

        for _ = 1, count do
            records[#records + 1] = {
                kind = effects.ITEM,
                arguments = {
                    kind_id = items.RUNE_VAULTS,
                },
            }
        end

        local ok, message = pcall(end_layout.require_rune, {
            records = records,
            vault_ids = {},
        })

        harness.falsy(ok, "invalid rune count must be rejected")
        harness.truthy(tostring(message):find("exactly one silver rune", 1, true),
            "rune invariant explains the rejected floor")
    end
end

function test.run()
    for seed = 1, 12 do
        composed_end_floor(seed)
    end

    all_quadrants()
    quadrant_modes()
    rune_decisions()
    rejected_rune_counts()
end

return test
