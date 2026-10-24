-- The source `v` menu selects miscellany and keeps wand `V` separate.
local commands = require("policy.input.commands")
local classes = require("ids.object_classes")
local harness = require("tests.harness")
local ids = require("ids.items")
local input_items = require("policy.input.items")
local modals = require("policy.presentation.modals")
local play = require("policy.input.play")

local test = {}

-- A horn has no aim prompt; a lightning rod needs one. The inventory
-- letters remain stable across both item menus.
function test.run()
    local selected = play.route({ key = "v" })

    harness.equal(selected.action, "screen")
    harness.equal(selected.screen, "evoke_item")

    local inventory = {
        {
            id = 101,
            class = classes.OBJ_MISCELLANY,
            kind_id = ids.MISC_HORN_OF_GERYON,
        },
        {
            id = 102,
            class = classes.OBJ_MISCELLANY,
            kind_id = ids.MISC_LIGHTNING_ROD,
        },
    }
    local horn = input_items.evoke_item({
        key = "a",
        inventory = inventory,
    })

    harness.equal(horn.action, "item_step")
    harness.equal(horn.kind, commands.evoke_item)
    harness.equal(horn.item_id, 101)

    local rod = input_items.evoke_item({
        key = "b",
        inventory = inventory,
    })

    harness.equal(rod.action, "aim")
    harness.equal(rod.kind, commands.evoke_item)
    harness.equal(rod.item_id, 102)

    -- The full inventory can contain other miscellany, but `v` must not
    -- offer or accept one without a registered XP effect.
    inventory[#inventory + 1] = {
        id = 103,
        class = classes.OBJ_MISCELLANY,
        kind_id = ids.MISC_QUAD_DAMAGE,
    }

    local refused = input_items.evoke_item({
        key = "c",
        inventory = inventory,
    })

    harness.equal(refused.action, "notice")

    local rows = modals.rows({
        mode = "evoke_item",
        height = 24,
        inventory = {
            {
                id = 101,
                class = classes.OBJ_MISCELLANY,
                kind_id = ids.MISC_HORN_OF_GERYON,
                name = "horn of Geryon",
                quantity = 1,
            },
            {
                id = 103,
                class = classes.OBJ_MISCELLANY,
                kind_id = ids.MISC_QUAD_DAMAGE,
                name = "quad damage",
                quantity = 1,
            },
        },
    })

    for _, write in ipairs(rows.writes) do
        harness.equal(string.find(write.text,
            "quad damage", 1, true), nil)
    end
end

return test
