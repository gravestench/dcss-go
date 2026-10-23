-- First sight uses the production visibility system and saved monster
-- marker. Re-entering sight must not grant The Shining One another roll.
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local sight = require("systems.character_scream")

local test = {}

-- A real actor and worship component exercise the same state transitions
-- as ordinary play while a thin wrapper controls sight and religion RNG.
function test.run(ctx)
    local player = ctx:create()
    local monster = ctx:create()
    local visible = true
    local rolls = 0
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:visible()
        return visible
    end

    function observed:random(stream)
        harness.equal(stream, "religion")
        rolls = rolls + 1

        return 0
    end

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })
    ctx:add(player, component.PROGRESSION, { level = 1 })
    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = gods.SHINING_ONE,
        piety = 30,
    })

    local rat = catalog.get(categories.MONSTERS, monsters.MONS_RAT)

    ctx:add(monster, component.ACTOR, { kind_id = rat.id })
    ctx:add(monster, component.HEALTH, {
        current = 5,
        max = 5,
    })
    ctx:add(monster, component.POSITION, {
        level_id = 1,
        x = 2,
        y = 1,
    })

    sight.update(observed, player)

    harness.truthy(ctx:has(monster, component.RELIGION_TSO_SEEN))
    harness.equal(rolls, 1)

    visible = false
    sight.update(observed, player)
    visible = true
    sight.update(observed, player)

    harness.equal(rolls, 1)
end

return test
