-- Degen's weaker-body choice uses the shared polymorph transition, so
-- inventory, health, and original-kind state follow the ordinary rules.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local streams = require("constants.rng_streams")

local test = {}

-- Repeated relaxation eventually admits a rat as an Ogre's weaker form.
-- The selected catalog species is a live ECS actor after transformation.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)
    local ogre = fixture.actor(ctx, monsters.MONS_OGRE,
        8, 7, 50)
    local position = ctx:get(ogre, component.POSITION)
    local pool = polymorph.shifter_pool(owner, position)
    local rat_index

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    for index, definition in ipairs(pool) do
        if definition.id == monsters.MONS_RAT then
            rat_index = index
            break
        end
    end

    harness.truthy(rat_index)

    function owner:random(stream, bound)
        if stream == streams.CARDS and bound == #pool then
            return rat_index - 1
        end

        if stream == streams.CARDS and bound == 200 then
            return 0
        end

        return ctx:random(stream, bound)
    end

    local source = catalog.get(categories.MONSTERS,
        monsters.MONS_OGRE)

    harness.truthy(polymorph.less(owner, ogre, source,
        streams.CARDS))
    harness.equal(ctx:get(ogre, component.ACTOR).kind_id,
        monsters.MONS_RAT)
    harness.equal(ctx:get(ogre,
        component.MONSTER_POLYMORPH).original_kind_id,
        monsters.MONS_OGRE)
end

return test
