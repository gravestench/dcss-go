-- Xom's enchantments affect existing monster status owners, so the next
-- monster action and a save read the same timer as an ordinary spell.
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")

local test = {}

-- The first source draws select Petrify and Haste. They must write the
-- production stasis and boon components on the same living target.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_ORC, 9, 7, 20)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    function owner:random(stream, bound)
        if stream == streams.RELIGION then
            return 0
        end

        return ctx:random(stream, bound)
    end

    events.apply(owner, player, ids.GOOD_ENCHANT_MONSTER, 20, {
        stream = streams.RELIGION,
    })
    events.apply(owner, player, ids.BAD_ENCHANT_MONSTER, 20, {
        stream = streams.RELIGION,
    })

    harness.truthy(ctx:get(monster,
        component.MONSTER_STASIS).petrifying_aut > 0)
    harness.truthy(ctx:get(monster,
        component.MONSTER_BOONS).haste_aut > 0)
end

return test
