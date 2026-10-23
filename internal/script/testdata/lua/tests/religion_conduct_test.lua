-- Conduct tests use the production worship component and catalog. The
-- temporary context wrapper selects a test player without copying a schema.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local piety = require("policy.religion.piety")
local branches = require("ids.branches")
local kinds = require("constants.religion_conduct")

local test = {}

-- A real component keeps the test coupled to the saved worship shape.
local function owner(ctx, god_id, points)
    local player = ctx:create()

    ctx:add(player, component.RELIGION_WORSHIP, {
        god_id = god_id,
        piety = points,
    })

    return player
end

-- The conduct owner must leave an unworshipping player and RNG untouched.
local function godless(ctx)
    local conduct = require("policy.religion.conduct")
    local kinds = require("constants.religion_conduct")
    local player = owner(ctx, gods.NO_GOD, 0)
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random()
        error("godless conduct must not draw RNG")
    end

    local applied = conduct.record(observed, {
        id = kinds.KILL_LIVING,
        level = 3,
        known = true,
    })

    harness.falsy(applied)
    harness.equal(ctx:get(player, component.RELIGION_WORSHIP).piety, 0)
end

-- Source offense loses piety first. Once devotion reaches zero, the
-- excommunication path records old-god wrath instead of a live penance.
local function excommunication(ctx)
    local player = owner(ctx, gods.TROG, 15)
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random()
        error("unscaled offense must not draw RNG")
    end

    piety.offend(observed, player, 20, 5)

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.god_id, gods.NO_GOD)
    harness.equal(state.piety, 0)
    harness.truthy((state.penance[gods.TROG] or 0) > 0)
end

-- Trog punishes even an attempted cast. The source's level multiplies
-- both consequences, while the first piety point fills hysteresis.
local function trog_cast(ctx)
    local conduct = require("policy.religion.conduct")
    local kinds = require("constants.religion_conduct")
    local player = owner(ctx, gods.TROG, 50)
    local observed = setmetatable({}, { __index = ctx })

    function observed:player()
        return player
    end

    function observed:random()
        error("Trog's fixed cast punishment must not draw RNG")
    end

    harness.truthy(conduct.record(observed, {
        id = kinds.SPELL_CASTING,
        level = 3,
        known = true,
    }))

    local state = ctx:get(player, component.RELIGION_WORSHIP)

    harness.equal(state.piety, 48)
    harness.equal(state.penance[gods.TROG], 15)
end

-- Lugonu gets no conduct from an action performed in the Abyss. The same
-- kill outside it remains eligible for the ordinary response curve.
local function lugonu_abyss(ctx)
    local handler = require("policy.religion.conduct.lugonu")
    local player = ctx:create()
    local observed = setmetatable({}, { __index = ctx })

    function observed:level_branch()
        return branches.BRANCH_ABYSS
    end

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    harness.falsy(handler.before(observed, player, {
        id = kinds.KILL_LIVING,
        level = 5,
        known = true,
    }))
end

-- Keep source behavior cases separate so later failures identify their
-- event category instead of one large assertion chain.
function test.run(ctx)
    godless(ctx)
    excommunication(ctx)
    trog_cast(ctx)
    lugonu_abyss(ctx)
end

return test
