-- Exercise the production summon owner for a permanent Yredelemnul
-- follower. The game save test checks that the same owner can restore it.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local gods = require("constants.gods")
local monsters = require("ids.monsters")
local summons = require("policy.magic.effects.summons.common")

local test = {}

-- A zero-degree god summon remains until dismissed or slain. Its source
-- and friendly allegiance make it eligible for later soul reclaim.
function test.run(ctx)
    local follower = summons.spawn(ctx, ctx:player(),
        gods.YREDELEMNUL, monsters.MONS_WIGHT, 0, nil, {
            attitude = attitudes.FRIENDLY,
            source_category = categories.GODS,
        })

    if not follower then
        error("Yredelemnul created no permanent follower")
    end

    return {}
end

register.policy({
    id = "test.yred_permanent_gift",
    run = test.run,
})

return test
