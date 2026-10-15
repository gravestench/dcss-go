local catalog = require("policy.catalog")
local branches = require("ids.branches")
local items = require("ids.items")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local harness = require("tests.harness")

local test = {}

function test.run()
    local dungeon = catalog.get("branches", branches.BRANCH_DUNGEON)
    local club = catalog.get("items", items.WPN_CLUB)
    local abomination = catalog.get("monsters", monsters.MONS_ABOMINATION_LARGE)
    local fireball = catalog.get("spells", spells.SPELL_FIREBALL)

    harness.equal(dungeon.id, branches.BRANCH_DUNGEON, "Dungeon branch")
    harness.equal(club.name, "club", "club item")
    harness.equal(abomination.name, "large abomination", "monster definition")
    harness.equal(fireball.name, "Fireball", "spell definition")

    local origin = register.origin("monsters", monsters.MONS_ABOMINATION_LARGE)
    harness.truthy(origin:match("^content/monsters/"), "monster origin")
end

return test
