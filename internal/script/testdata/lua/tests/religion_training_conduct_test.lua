-- Training conduct derives from actual gained magic skill points, using
-- the same skill IDs that the character trainer and content catalog use.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local skills = require("ids.skills")
local training = require("policy.religion.conduct.training")

local test = {}

-- An exact multiple of ten requires no rounding draw. Nonmagic Fighting
-- gain must not be included in Trog's spell-practice offense.
function test.run(ctx)
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random()
        error("exact skill gain must not draw religion RNG")
    end

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.TROG,
        piety = 50,
    })

    local before = {
        [skills.SK_SPELLCASTING] = 4,
        [skills.SK_FIGHTING] = 1,
    }
    local after = {
        {
            id = skills.SK_SPELLCASTING,
            points = 24,
        },
        {
            id = skills.SK_FIGHTING,
            points = 41,
        },
    }

    harness.equal(training.report(observed, player, before, after), 2)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 49)
end

return test
