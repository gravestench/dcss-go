local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local polymorph = require("policy.combat.monster_hexes.polymorph")

local test = {}

function test.run()
    local ctx = {}
    local foe = 202

    function ctx:has()
        return false
    end

    function ctx:get(entity, id)
        if entity == foe and id == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        return nil
    end

    harness.truthy(polymorph.viable(ctx, 101, foe),
        "monster Polymorph uses the source legal-form check")
end

return test
