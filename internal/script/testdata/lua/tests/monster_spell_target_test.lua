
local harness = require("tests.harness")
local kind = require("constants.target_kind")
local target = require("policy.combat.monster_spell_target")

local test = {}

-- Zero direction component survives the intent boundary.
function test.run()
    local plan = {
        kind = kind.ENTITY,
        entity = 7,
    }

    harness.equal(target.require_entity(plan, 7), 7,
        "an entity effect accepts its planned foe")

    local wrong = pcall(target.require_entity, plan, 8)

    harness.falsy(wrong, "an entity effect rejects a different foe")

    local cell = pcall(target.require_entity, {
        kind = kind.CELL,
        level_id = 1,
        x = 4,
        y = 5,
    }, 7)

    harness.falsy(cell, "an entity effect rejects an empty-cell plan")

    local intent = target.write({}, {
        kind = kind.ENTITY,
        entity = 7,
        dx = 3,
        dy = 0,
    })
    local restored = target.read(intent)

    harness.equal(restored.dx, 3,
        "selected beam direction survives the intent boundary")
    harness.equal(restored.dy, 0,
        "zero direction component survives the intent boundary")
end

return test
