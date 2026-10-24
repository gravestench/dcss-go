-- Test policies dispatch through the same effective Xom event catalog as
-- ordinary worship, leaving live movement to the game's Abyss owner.
local events = require("policy.religion.xom.events")
local ids = require("ids.xom_events")
local streams = require("constants.rng_streams")

local probe = {}

-- Real banishment must leave the player in a saved Abyss window.
function probe.real(ctx)
    events.apply(ctx, ctx:player(), ids.BAD_BANISHMENT, 20, {
        stream = streams.RELIGION,
    })

    return {}
end

-- Pseudo banishment must enter and exit in one transaction, restoring
-- the outside position instead of maintaining an invalid return pointer.
function probe.pseudo(ctx)
    events.apply(ctx, ctx:player(), ids.BAD_PSEUDO_BANISHMENT, 20, {
        stream = streams.RELIGION,
    })

    return {}
end

-- Exercise stair repulsion through the same catalog dispatch and grid
-- transaction used by a live Xom action.
function probe.stairs(ctx)
    return {
        moved = events.apply(ctx, ctx:player(),
            ids.BAD_MOVING_STAIRS, 20, {
                stream = streams.RELIGION,
            }),
    }
end

register.policy({
    id = "test.xom_banishment",
    run = probe.real,
})

register.policy({
    id = "test.xom_pseudo_banishment",
    run = probe.pseudo,
})

register.policy({
    id = "test.xom_stairs",
    run = probe.stairs,
})

return probe
