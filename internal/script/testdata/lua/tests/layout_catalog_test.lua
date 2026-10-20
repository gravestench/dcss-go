-- The live selector reads effective committed DES metadata and invokes the
-- named Lua hook; these checks avoid a second hard-coded layout weight list.
local catalog = require("policy.generation.layouts.catalog")
local branches = require("ids.branches")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local depth = require("policy.generation.vaults.depth")
local des = require("policy.generation.vaults.des")
local placement = require("policy.generation.vaults.placement")
local connect = require("policy.generation.vaults.connect")
local vault_catalog = require("policy.generation.vaults.catalog")
local features = require("content.terrain_features")
local weight = require("policy.generation.vaults.weight")
local harness = require("tests.harness")

local test = {}

-- A deterministic draw exposes candidate order without copying source
-- weights or layout IDs into the test fixture.
local function picker(draw)
    local random = {}

    function random:roll(bound)
        return draw % bound
    end

    return random
end

-- Supply the production grid's uint64 draw contract to every layout hook
-- without copying its geometry or source metadata into a test fixture.
local function context_for(seed)
    local state = seed
    local context = {}

    function context:random_u64(stream)
        harness.equal(stream, "layout", "catalog layout stream")
        state = (state * 1664525 + 1013904223) % 4294967296

        return state, (state * 22695477 + 1) % 4294967296
    end

    return context
end

-- Disabled definitions remain registered but never enter a positive-weight
-- Dungeon selection at any eligible depth.
local function source_catalog()
    local ids = catalog.ids()
    local active = 0
    local disabled = 0
    local branch_only = 0

    harness.equal(#ids, 41, "effective source layout count")

    for _, id in ipairs(ids) do
        local definition = catalog.get(id)
        local dungeon_weight = weight.for_branch(definition,
            branches.BRANCH_DUNGEON)

        local dungeon = false

        for level = 1, 15 do
            dungeon = dungeon or depth.eligible(definition,
                branches.BRANCH_DUNGEON, level, 15)
        end

        if not dungeon then
            branch_only = branch_only + 1
        elseif dungeon_weight > 0 then
            active = active + 1
        else
            disabled = disabled + 1
        end
    end

    harness.equal(active, 17, "active source layouts")
    harness.equal(disabled, 4, "registered disabled layouts")
    harness.equal(branch_only, 20, "registered branch-only layouts")
end

-- Boundary depths change the candidate set while the selected result
-- always comes from a positive source weight and an eligible DEPTH rule.
local function eligible_choices()
    for _, level in ipairs({ 1, 4, 9, 15 }) do
        for draw = 0, 120 do
            local selected = catalog.choose(picker(draw),
                branches.BRANCH_DUNGEON, level, 15)

            harness.truthy(weight.for_branch(selected,
                branches.BRANCH_DUNGEON) > 0,
                "Dungeon layout positive weight")
            harness.truthy(depth.eligible(selected,
                branches.BRANCH_DUNGEON, level, 15),
                "Dungeon layout depth")
        end
    end
end

-- A primary arrival can request or veto a layout family. No restriction
-- permits all families, exactly as the source primary-vault rule does.
local function primary_tags()
    local city = {
        tags = {
            layout_type_city = true,
        },
    }

    harness.truthy(catalog.compatible(city, {}),
        "unrestricted primary accepts city")
    harness.truthy(catalog.compatible(city, {
        layout_city = true,
    }), "positive city tag")
    harness.falsy(catalog.compatible(city, {
        layout_rooms = true,
    }), "positive noncity tag")
    harness.falsy(catalog.compatible(city, {
        nolayout_city = true,
    }), "negative city tag")
end

-- The basic hook must execute through the same catalog contract as all
-- other source layouts and return three connected ordinary stair pairs.
local function basic_hook()
    local result = catalog.execute(context_for(17),
        catalog.get("layout_basic"), branches.BRANCH_DUNGEON, 2)

    harness.equal(#result.stairs, 3, "basic hook stair pairs")
    harness.equal(result.id, "layout_basic", "executed layout identity")
end

-- Every active source layout must run through the live DES hook contract.
-- Select its first and last eligible Dungeon depths from metadata, then
-- require a shared-stair result rather than testing only its private hook.
local function execute_active_layouts()
    for _, id in ipairs(catalog.ids()) do
        local definition = catalog.get(id)

        local first_depth
        local last_depth

        for level = 1, 15 do
            if depth.eligible(definition,
                branches.BRANCH_DUNGEON, level, 15) then
                first_depth = first_depth or level
                last_depth = level
            end
        end

        if first_depth and
            weight.for_branch(definition, branches.BRANCH_DUNGEON) > 0 then
            for _, level in ipairs({ first_depth, last_depth }) do
                local result = catalog.execute(context_for(47), definition,
                    branches.BRANCH_DUNGEON, level)

                harness.equal(result.id, id, "executed source layout")
                harness.equal(#result.rows, 70, "layout height")
                harness.equal(#result.rows[1], 80, "layout width")
                harness.truthy(#result.stairs >= 3,
                    "source layout has connected ordinary stairs")
            end
        end
    end
end

-- Arrival placement must preserve every ordinary stair glyph emitted by
-- the shared postpass, including the alternate pairs that basic did not use.
local function protect_completed_stairs()
    local source = table.concat({
        "NAME: stair_guard_probe",
        "ORIENT: encompass",
        "MAP",
        "#",
        "ENDMAP",
    }, "\n")
    local vault = des.parse("vaults/arrival/stair_guard_probe.des", source)

    for _, glyph in ipairs({ "{", "(", "[", "}", ")", "]" }) do
        local builder = grid.new({})

        builder:set(39, 34, glyph)

        local ok, err = pcall(placement.place, nil, builder, vault, {})

        harness.falsy(ok, "arrival cannot replace completed stair " .. glyph)
        harness.truthy(tostring(err):find("existing stair", 1, true),
            "stair conflict reports its cause")
    end
end

-- KMONS replaces a glyph's default terrain in DCSS. A keyed fungus on b
-- needs floor rather than the crystal wall that bare b would normally mean.
local function keyed_monster_uses_floor()
    local context = context_for(9)
    local builder = grid.new(context)
    local vault = vault_catalog.get("scummos_arrival_checkerplants")
    local placed = placement.place(context, builder, vault, {})
    local cells = features.decode_source_rows(builder:rows())

    features.apply_vault_terrain(cells, placed.records, context, 1)

    local found = 0

    for _, record in ipairs(placed.records) do
        if record.kind == effects.MONSTER and record.source == "b" then
            found = found + 1
            harness.equal(cells[record.y + 1][record.x + 1],
                "DNGN_FLOOR", "keyed fungus has floor terrain")
        end
    end

    harness.truthy(found > 0, "checkerplants keyed fungi were placed")
end

-- A vault corridor can cross a stair placed by the layout postpass. The
-- connector may carve nearby rock but must retain the stair at that cell.
local function connector_preserves_completed_stair()
    local builder = grid.new({})

    builder:set(17, 21, ".")
    builder:set(19, 21, "{")

    local entry = {
        x = 21,
        y = 21,
        source = "@",
    }
    local placed = {
        id = "stair_connector_probe",
        path = "vaults/arrival/stair_connector_probe.des",
        entry = entry,
        exits = { entry },
        records = {},
        bounds = {
            x = 20,
            y = 20,
            width = 3,
            height = 3,
        },
    }

    connect.finish(nil, builder, placed, { { x = 19, y = 21 } })

    harness.equal(builder:cell(19, 21), "{",
        "vault connector preserves completed stair")
end

-- Run catalog selection, tag filtering, and one real hook end to end.
function test.run()
    source_catalog()
    eligible_choices()
    primary_tags()
    basic_hook()
    execute_active_layouts()
    protect_completed_stairs()
    keyed_monster_uses_floor()
    connector_preserves_completed_stair()
end

return test
