-- Worship is live ECS state, with source IDs and bounded values checked at
-- the same boundary that will validate restored saves.
local component = require("constants.component")
local gods = require("constants.gods")
local harness = require("tests.harness")
local schema = require("schemas.religion_worship")
local validation = require("policy.religion.validation")

local test = {}

-- Check one malformed saved-state shape at a time without restating the
-- production schema in this fixture.
local function rejects(ctx, owner, changes, reason)
    local state = ctx:get(owner, schema.id)

    for field, value in pairs(changes) do
        state[field] = value
    end

    ctx:set(owner, schema.id, state)

    local ok = pcall(validation.check, ctx, owner)

    harness.falsy(ok, reason)
end

-- A newly created owner has no god history; invalid IDs and amounts cannot
-- become authoritative merely because the ECS field types accept them.
function test.run(ctx)
    local owner = ctx:create()

    ctx:add(owner, schema.id, {})

    local state = ctx:get(owner, component.RELIGION_WORSHIP)

    harness.equal(state.god_id, gods.NO_GOD)
    harness.equal(state.piety, 0)
    harness.equal(state.gift_timeout, 0)
    harness.equal(next(state.penance), nil)
    validation.check(ctx, owner)

    rejects(ctx, owner, {
        god_id = "GOD_UNKNOWN",
    }, "unknown god rejected")

    ctx:set(owner, schema.id, {})
    rejects(ctx, owner, {
        piety = -1,
    }, "negative piety rejected")

    ctx:set(owner, schema.id, {})
    rejects(ctx, owner, {
        piety_max = {
            [gods.TROG] = -1,
        },
    }, "negative god history rejected")
end

return test
