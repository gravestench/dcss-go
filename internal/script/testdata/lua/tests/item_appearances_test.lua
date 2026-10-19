-- Staff descriptors preserve source spacing.

local appearances = require("data.item_appearances")
local names = require("policy.items.appearances")
local pools = require("constants.appearance_pools")
local harness = require("tests.harness")

local test = {}

-- Pin appearance pool sizes and pairings because unidentified items rely on
-- these committed names remaining stable across fresh games and saves.
function test.run()
    harness.equal(#appearances.wand.primary, 12,
        "wand primary names match the pinned source")
    harness.equal(#appearances.wand.secondary, 16,
        "wand secondary names match the pinned source")
    harness.equal(appearances.wand.primary[1], "iron",
        "wand table starts with the source's iron descriptor")

    harness.equal(#appearances.ring.primary, 29,
        "ring primary names match the pinned source")
    harness.equal(#appearances.amulet.primary, 29,
        "amulet primary names match the pinned source")
    harness.equal(#appearances.staff.secondary, 10,
        "staff secondary names match the pinned source")
    harness.equal(appearances.potion.colours[1], "blue",
        "removed clear potion colour is excluded")
    harness.equal(appearances.potion.qualifiers[1], "",
        "plain potions retain the empty source qualifier")
    harness.equal(names.name(pools.STAFF, 0), "crooked glowing staff",
        "staff descriptors preserve source spacing")
    harness.equal(names.weight(pools.POTION, 0), 16,
        "plain potion descriptions keep the source bias")
    harness.equal(names.weight(pools.POTION, 22), 1,
        "qualified potions keep the ordinary draw weight")
end

return test
