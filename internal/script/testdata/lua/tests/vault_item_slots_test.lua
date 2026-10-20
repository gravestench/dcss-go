-- Comma-separated DES item slots create stacked items on one map cell.
local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local items = require("ids.items")
local placement = require("policy.generation.vaults.placement")

local test = {}

-- The source item_list places every comma slot; a slash would choose one
-- alternative inside a slot. One D glyph therefore yields two records.
local function one_cell_gets_both_items()
    local source = {
        id = "item_slots_fixture",
        path = "vaults/serial/item_slots_fixture.des",
        rows = { "@D" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KITEM,
                argument = "D = stone q:2, potion of curing",
                line = 4,
            },
        },
    }
    local builder = grid.new({})

    function builder:roll()
        return 0
    end

    local placed = placement.place(nil, builder, source)
    local found = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.ITEM then
            found[#found + 1] = record
        end
    end

    harness.equal(#found, 2, "both source item slots place")
    harness.equal(found[1].arguments.kind_id, items.MI_STONE,
        "first item slot")
    harness.equal(found[1].arguments.quantity, 2,
        "first item quantity")
    harness.equal(found[2].arguments.kind_id, items.POT_CURING,
        "second item slot")
    harness.equal(found[1].x, found[2].x,
        "source items share one cell x")
    harness.equal(found[1].y, found[2].y,
        "source items share one cell y")
end

-- A colon assignment shares its choice across matching cells but still
-- creates a separate pair of item records and mutable arguments at each.
local function shared_choice_keeps_separate_records()
    local source = {
        id = "shared_item_slots_fixture",
        path = "vaults/serial/shared_item_slots_fixture.des",
        rows = { "@DD" },
        orientation = "centre",
        operations = {
            {
                kind = directives.KITEM,
                argument = "D : stone, potion of curing",
                line = 4,
            },
        },
    }
    local builder = grid.new({})

    function builder:roll()
        return 0
    end

    local placed = placement.place(nil, builder, source)
    local found = {}

    for _, record in ipairs(placed.records) do
        if record.kind == effects.ITEM then
            found[#found + 1] = record
        end
    end

    harness.equal(#found, 4, "two source slots on each of two cells")
    harness.equal(found[1].arguments.kind_id, found[3].arguments.kind_id,
        "first slot choice is shared")
    harness.equal(found[2].arguments.kind_id, found[4].arguments.kind_id,
        "second slot choice is shared")
    harness.falsy(found[1].arguments == found[3].arguments,
        "different cells do not share argument tables")
end

-- Verify the multi-item slot rule before research spellbooks depend on it.
function test.run()
    one_cell_gets_both_items()
    shared_choice_keeps_separate_records()
end

return test
