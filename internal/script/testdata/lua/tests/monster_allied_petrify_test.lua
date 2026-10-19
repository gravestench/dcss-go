-- A monster-targeted petrifying gaze must use the monster stasis owner.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local petrify = require("policy.combat.monster_spells.petrify")

local test = {}

-- Force the will contest to fail while keeping production ECS schemas and
-- the real petrification effect; the target must enter monster stasis.
function test.run(ctx)
    local player = ctx:create()
    local caster = fixture.actor(ctx, monsters.MONS_BASILISK, 1, 1, 40)
    local foe = fixture.actor(ctx, monsters.MONS_ADDER, 3, 1, 40)
    local game = fixture.context(ctx, player)
    local messages = {}

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    -- Leave the gaze ray unobstructed so will and actor status decide it.
    function game:projectile_clear()
        return true
    end

    -- Make the will contest fail deterministically in the real resolver.
    function game:random(_, bound)
        return bound - 1
    end

    -- The player is not observing this gaze, so status still applies while
    -- no name or outcome leaks into the public message log.
    function game:visible()
        return false
    end

    -- Capture any accidental report of the unseen monster's result.
    function game:emit(_, message)
        messages[#messages + 1] = message
    end

    local plan = petrify.plan(game, caster, foe)

    harness.truthy(plan, "gaze can plan a visible monster foe")
    petrify.resolve(game, caster, foe, nil, plan)

    local stasis = ctx:get(foe, component.MONSTER_STASIS)

    harness.truthy(stasis and stasis.petrifying_aut > 0,
        "monster foe enters its own petrifying phase")
    harness.falsy(ctx:has(foe, component.PLAYER_PETRIFICATION),
        "monster foe never receives a player status")
    harness.equal(#messages, 0,
        "unseen petrifying gaze emits no target outcome")
end

return test
