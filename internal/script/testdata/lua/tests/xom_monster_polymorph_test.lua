-- Xom's two monster polymorphs use the same saved body transition as
-- ordinary Polymorph and Degen, with opposite relative power windows.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local events = require("policy.religion.xom.events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local ids = require("ids.xom_events")
local monsters = require("ids.monsters")
local polymorph = require("policy.magic.effects.statuses.polymorph")
local good = require("policy.religion.xom.selection_good")
local streams = require("constants.rng_streams")

local test = {}

-- Once animation fails its chance, a mutable nearby monster permits the
-- next source good gate. Earlier branches retain their exact draw order.
local function good_polymorph_gate(ctx, player)
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, monsters.MONS_OGRE, 9, 7, 30)
    local bounds = {
        3, 100, 100, 100, 100, 5, 5, 100, 8,
        100, 10, 8, 100, 100,
    }
    local used = 0

    -- Each chance after the first group ally test uses the same Xom
    -- stream, so a new unexpected gate fails at its actual bound.
    function owner:random(stream, bound)
        used = used + 1

        harness.equal(stream, streams.RELIGION)
        harness.equal(bound, bounds[used])

        if used == 12 or used == 14 then
            return 0
        end

        return bound - 1
    end

    harness.equal(good.choose(owner, player, 100, 2,
        streams.RELIGION), ids.GOOD_POLYMORPH)
    harness.equal(used, #bounds)
    ctx:destroy(monster)
end

-- Fix only Xom's selection and form choice. HP and status transitions
-- still go through the live monster polymorph owner.
local function transform(ctx, player, before, after, event_id,
    make_shifter)
    local owner = fixture.context(ctx, player)
    local monster = fixture.actor(ctx, before, 9, 7, 30)
    local position = ctx:get(monster, component.POSITION)
    local pool = polymorph.shifter_pool(owner, position)
    local target_index

    for index, definition in ipairs(pool) do
        if definition.id == after then
            target_index = index
            break
        end
    end

    harness.truthy(target_index)

    function owner:random(stream, bound)
        if stream == streams.RELIGION and bound == 8 then
            return make_shifter and 0 or 1
        end

        if stream == streams.RELIGION and bound == 3 then
            return 0
        end

        if stream == streams.RELIGION and bound == #pool then
            return target_index - 1
        end

        if stream == streams.RELIGION and bound == 200 then
            return 0
        end

        return ctx:random(stream, bound)
    end

    local changed = events.apply(owner, player, event_id, 20, {
        stream = streams.RELIGION,
    })

    harness.truthy(changed)
    harness.equal(ctx:get(monster, component.ACTOR).kind_id, after)
    harness.equal(ctx:get(monster,
        component.MONSTER_POLYMORPH).original_kind_id, before)

    if make_shifter then
        harness.truthy(ctx:has(monster,
            component.MONSTER_SHAPESHIFTER))
    end

    ctx:destroy(monster)
end

-- Ogre to rat and rat to ogre exercise both ends of the source window.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    good_polymorph_gate(ctx, player)

    transform(ctx, player, monsters.MONS_OGRE, monsters.MONS_RAT,
        ids.GOOD_POLYMORPH)
    transform(ctx, player, monsters.MONS_RAT, monsters.MONS_OGRE,
        ids.BAD_POLYMORPH)
    transform(ctx, player, monsters.MONS_OGRE, monsters.MONS_RAT,
        ids.GOOD_POLYMORPH, true)

    -- Keep source-backed monster definitions visible to the test reader.
    harness.truthy(catalog.get(categories.MONSTERS,
        monsters.MONS_OGRE).hd >
        catalog.get(categories.MONSTERS,
            monsters.MONS_RAT).hd)
end

return test
