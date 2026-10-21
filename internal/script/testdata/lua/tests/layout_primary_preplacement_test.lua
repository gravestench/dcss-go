-- A layout that wraps an authored primary needs the real selected map on
-- the builder before it paints surrounding geometry. The source GeoElf
-- castle uses those bounds to decide its walls, gates, moat, and rooms.
local branches = require("ids.branches")
local catalog = require("policy.generation.layouts.catalog")
local des = require("policy.generation.vaults.des")
local generated = require("policy.generation.generated")
local grid = require("policy.generation.grid")
local stairs = require("policy.generation.layouts.stairs")
local harness = require("tests.harness")
local primary = require("policy.generation.vaults.primary")
local used = require("policy.generation.vaults.used")

local test = {}

-- Use the production builder's named random stream with deterministic bits.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "preplacement random stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- The production floor owner must preplace the selected Elf finale before
-- running GeoElf Castle, then return that same map for ordinary vault history.
local function castle_wraps_selected_primary()
    harness.equal(type(generated.prepare_layout), "function",
        "generation prepares primary-aware layouts")

    local ctx = context_for(91)
    local branch = register.get("branches", branches.BRANCH_ELF)
    local specification = primary.specification(branch, 3)
    local player = {
        branch_id = branches.BRANCH_ELF,
        depth = 3,
        branch_bottom = branch.depth,
        absolute_depth = branch.absolute_depth + 2,
        name = "Player",
    }
    local input = {
        branch_id = player.branch_id,
        depth = player.depth,
        profile = {
            up = 3,
            down = 0,
        },
        prior_vault_ids = {},
        primary_spec = specification,
        primary_choice = {
            id = "elf_hall",
        },
        player = player,
        map_parameters = { "layout" },
    }
    local definition = catalog.get("layout_geoelf_castle")
    local layout, placed = generated.prepare_layout(ctx, definition, input)

    harness.equal(layout.id, definition.id, "source castle layout")
    harness.equal(placed.id, input.primary_choice.id,
        "castle wraps selected source finale")
    harness.truthy(#layout.stairs >= 3,
        "castle retains connected Elf exits")
end

-- The completed stairs may connect through authored primary floor, but
-- their new glyphs must be placed on the surrounding layout instead.
local function stair_pass_preserves_primary_floor()
    local ctx = {}

    function ctx:random_u64()
        return 0, 0
    end

    local builder = grid.new(ctx)
    local excluded = {}

    for x = 10, 30 do
        builder:set(x, 10, ".")

        if x <= 28 then
            excluded[x .. ":10"] = true
        end
    end

    local paired = stairs.complete(builder, {
        up = 1,
        down = 1,
    }, excluded)

    harness.equal(#paired, 1, "one connected stair pair")
    harness.truthy(paired[1].up.x >= 29,
        "up stair avoids authored primary floor")
    harness.truthy(paired[1].down.x >= 29,
        "down stair avoids authored primary floor")
end

-- A centred source primary first draws from layouts tagged central. Snake
-- has both central and ordinary candidates, so this checks the preference
-- on the real effective DES catalog rather than a copied weight table.
local function centred_primary_layout_choice()
    for draw = 0, 300 do
        local random = {}

        function random:roll(bound)
            return draw % bound
        end

        local selected = catalog.choose(random, branches.BRANCH_SNAKE,
            4, 4, {}, true)

        harness.truthy(selected.tags.central,
            "centred primary selects a central layout")
    end
end

-- The layout catalog must forward a preplaced builder and its world-space
-- bounds to a named Lua hook. The probe module lives in the test mod, while
-- DES parsing and hook dispatch remain the production implementations.
local function wrapping_layout_context()
    local path = "vaults/layout/primary_layout_probe.des"
    local source = mod.read("tests/fixtures/primary_layout_probe.des")
    local definition = des.parse(path, source)
    local ctx = context_for(41)
    local builder = grid.new(ctx)
    local primary_vault = {
        x1 = 25,
        y1 = 22,
        x2 = 35,
        y2 = 32,
    }

    for y = 2, builder.height - 3 do
        for x = 2, builder.width - 3 do
            builder:set(x, y, ".")
        end
    end

    local result = catalog.execute(ctx, definition,
        branches.BRANCH_ELF, 3, nil, nil, {
            builder = builder,
            primary_vault = primary_vault,
            map_parameters = { "central" },
        })

    harness.equal(result.builder, builder,
        "layout hook preserves preplaced builder")

    local rejected, message = pcall(catalog.execute, ctx, definition,
        branches.BRANCH_ELF, 3)

    harness.falsy(rejected, "wrapping layout without primary is vetoed")
    harness.truthy(tostring(message):find("veto", 1, true),
        "source veto rejects before the layout hook")
end

-- Preplacement must use the real selected Elf:3 vault and retain both its
-- placed cells and source records. The castle cannot infer its footprint
-- from a filename or re-roll a second, unrelated primary later.
local function elf_primary_before_layout()
    harness.equal(type(primary.select), "function",
        "primary can be selected before layout")
    harness.equal(type(primary.preplace), "function",
        "primary preplacement API exists")

    local ctx = context_for(73)
    local builder = grid.new(ctx)
    local choice = {
        id = "elf_hall",
    }
    local player = {
        branch_id = branches.BRANCH_ELF,
        depth = 3,
        branch_bottom = 3,
        absolute_depth = 17,
        name = "Player",
    }
    local context = {
        branch_id = player.branch_id,
        depth = player.depth,
        branch_bottom = player.branch_bottom,
        absolute_depth = player.absolute_depth,
        primary_vault_family = "elf_end",
        primary_choice = choice,
        player = player,
        used = used.new({}),
    }

    local selected_vault = primary.select(builder, context)

    harness.equal(selected_vault.id, choice.id,
        "source primary selected before layout")

    local placed = primary.preplace(ctx, builder, context)

    harness.equal(placed.id, choice.id, "selected source primary")
    harness.truthy(#placed.occupied > 0, "primary occupied real cells")
    harness.truthy(placed.bounds.width > 0, "primary has placed bounds")
    harness.truthy(#placed.records > 0, "primary retains source records")

    local changed = false

    for _, point in ipairs(placed.occupied) do
        changed = changed or builder:cell(point.x, point.y) ~= "#"
    end

    harness.truthy(changed,
        "primary cells exist before castle layout")

    -- Once the castle has drawn around this map, the ordinary extra pass
    -- must publish the same placement without choosing or drawing it again.
    context.preplaced_primary = placed

    local published = {}

    local function reject_duplicate_fit()
        error("primary was placed a second time")
    end

    local selected = primary.place(ctx, builder, context, published,
        reject_duplicate_fit)

    harness.equal(selected, placed.id, "preplaced primary identity")
    harness.equal(#published, 1, "preplaced primary published once")
    harness.equal(published[1], placed, "same source placement published")
    harness.equal(context.used:ids()[1], placed.id,
        "preplaced primary enters saved history")
end

-- Keep the preplacement contract alongside the source family tests.
function test.run()
    elf_primary_before_layout()
    wrapping_layout_context()
    castle_wraps_selected_primary()
    stair_pass_preserves_primary_floor()
    centred_primary_layout_choice()
end

return test
