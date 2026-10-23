-- Whole-floor Treasure Trove selection reads the effective DES catalog.
-- Each source room remains a separately replaceable mod asset.
local harness = require("tests.harness")
local species = require("ids.species")
local level = require("policy.generation.trove.level")
local item_specs = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")
local classes = require("ids.object_classes")
local quality = require("constants.vault_item_quality")

local test = {}

-- Positive source weights produce all 21 destination choices for Human.
-- Sorting by stable NAME prevents directory order from changing a seed.
function test.run()
    local maps = level.candidates({
        species_id = species.SP_HUMAN,
    })

    harness.equal(#maps, 21, "all source reward rooms are selectable")

    for index, map in ipairs(maps) do
        harness.truthy(map.weight > 0, map.id .. " positive weight")

        if index > 1 then
            harness.truthy(maps[index - 1].id < map.id,
                "Trove draw order is stable by NAME")
        end
    end

    -- `useful` is a live-character filter, not a quality word embedded in
    -- the item name. Keep it beside the ordinary good-item modifier.
    local site = {
        path = "vaults/trove/trove_armour_1.des",
        line = 1,
        vault_id = "trove_armour_1",
    }
    local selected = item_specs.parse(
        "any useful armour good_item", site)[1][1]
    local resolved = resolve.item({}, selected, 18, site)

    harness.equal(selected.name, "any armour",
        "useful source modifier leaves a normal class request")
    harness.truthy(selected.useful,
        "source useful modifier survives parsing")
    harness.equal(resolved.class_id, classes.OBJ_ARMOUR,
        "useful armour keeps its class")
    harness.equal(resolved.quality, quality.GOOD,
        "useful does not force superb quality")
end

return test
