-- The source movement warning is conditional on active ice defenses and
-- nearby danger. This fixture reads the production ECS status components.
local component = require("constants.component")
local bend = require("policy.abilities.lugonu.bend_space")
local depart = require("policy.abilities.lugonu.depart")
local enter = require("policy.abilities.lugonu.enter")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local movement = require("policy.character.unsafe_move")

local test = {}

-- A visible hostile creates the warning; the forced transition then
-- removes both ice defenses through their live status components.
function test.run(ctx)
    local player = ctx:create()
    local hostile = ctx:create()
    local game = setmetatable({}, { __index = ctx })

    function game:player()
        return player
    end

    function game:visible()
        return true
    end

    ctx:add(player, component.PLAYER, {})
    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 4,
        y = 4,
    })
    ctx:add(player, component.HEALTH, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.MAGIC, {
        current = 20,
        max = 20,
    })
    ctx:add(player, component.PLAYER_STATUS, {
        ice_armour_aut = 100,
        ice_armour_power = 30,
    })
    ctx:add(player, component.FROZEN_RAMPARTS, {
        level_id = 1,
        origin_x = 4,
        origin_y = 4,
        power = 10,
        remaining_aut = 100,
    })
    ctx:add(hostile, component.ACTOR, {
        kind_id = monsters.MONS_GOBLIN,
        speed = 10,
    })
    ctx:add(hostile, component.POSITION, {
        level_id = 1,
        x = 5,
        y = 4,
    })
    ctx:add(hostile, component.HEALTH, {
        current = 5,
        max = 5,
    })

    local warning = movement.warning(game, player)

    harness.truthy(warning and
        warning:find("icy armour and frozen ramparts", 1, true))

    for _, ability in ipairs({ depart, bend, enter }) do
        local response = ability.prepare(game, player, {})

        harness.equal(response.confirmation, warning)
        harness.equal(ability.prepare(game, player, {
            forced = true,
        }), nil)
    end

    movement.break_ice(game, player)
    harness.equal(game:get(player,
        component.PLAYER_STATUS).ice_armour_aut, 0)
    harness.falsy(game:has(player, component.FROZEN_RAMPARTS))
    harness.equal(movement.warning(game, player), nil)
end

return test
