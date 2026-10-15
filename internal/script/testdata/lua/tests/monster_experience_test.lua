local catalog = require("policy.catalog")
local death = require("policy.death")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}

function test.run()
    local basilisk = catalog.get("monsters", monsters.MONS_BASILISK)
    local sphinx = catalog.get("monsters", monsters.MONS_SPHINX)

    harness.equal(death.experience(basilisk, 36), 193,
        "Petrify raises Basilisk XP by the source spell difficulty")
    harness.equal(death.experience(sphinx, 88), 1503,
        "Sphinx counts both dangerous spells without an equipment bonus")
    harness.equal(death.experience(sphinx, 88, true), 2256,
        "legacy XP scaling supplies the source threat grade")
end

return test
