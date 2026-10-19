
local records = require("policy.mutations.records")
local levels = require("policy.mutations.levels")
local transition = require("policy.mutations.transition")
local mutations = require("ids.mutations")
local classes = require("constants.mutation_classes")
local component = require("constants.component")
local harness = require("tests.harness")

local test = {}

-- Restore rejects a missing scheduled species mutation.
function test.run(ctx)
    local player = ctx:create()
    local id = mutations.MUT_ROBUST

    records.grant_innate(ctx, player, id, 1)
    records.grant_acquired(ctx, player, id, 1)
    records.grant_temporary(ctx, player, id, 1, 50)

    local entry = records.find(ctx, player, id)

    harness.truthy(entry, "mutation record exists")
    harness.equal(entry.state.innate, 1, "innate level")
    harness.equal(entry.state.acquired, 1, "acquired level")
    harness.equal(entry.state.temporary, 1, "temporary level")
    -- Multiple temporary mutation levels use one player XP expiry clock.
    harness.equal(records.timer(ctx, player).remaining_xp, 50,
        "shared temporary expiry progress")
    harness.equal(levels.base(ctx, player, id), 3, "base level")
    harness.equal(levels.effective(ctx, player, id), 3,
        "effective level without a form")

    records.delete(ctx, player, id, classes.TEMPORARY, 1)
    harness.equal(levels.base(ctx, player, id), 2,
        "removing a temporary level")

    local remaining = records.find(ctx, player, id)
    harness.equal(records.timer(ctx, player).remaining_xp, 0,
        "temporary expiry resets when the last level ends")

    records.delete(ctx, player, id, classes.ACQUIRED, 1)
    records.delete(ctx, player, id, classes.INNATE, 1)
    -- Removing the last class level destroys the empty mutation entity.
    harness.equal(records.find(ctx, player, id), nil,
        "zero-level record is removed")

    local scheduled = {
        mutations = {
            {
                id = mutations.MUT_HOP,
                level = 13,
                amount = 1,
            },
        },
    }

    ctx:add(player, "core.player", {
        species_id = "SP_HUMAN",
        job_id = "JOB_FIGHTER",
        name = "Mutation test",
    })

    transition.grant_scheduled(ctx, player, scheduled, 12)
    harness.equal(levels.base(ctx, player, mutations.MUT_HOP), 0,
        "future innate level is absent")

    transition.grant_scheduled(ctx, player, scheduled, 13)
    -- Future innate mutations become active only at their recorded level milestone.
    harness.equal(levels.base(ctx, player, mutations.MUT_HOP), 1,
        "scheduled innate level is granted")

    ctx:add(player, component.PLAYER_FORM, {
        form_id = "appendage",
        remaining_aut = 30,
        power = 40,
        appendage_mask = 4,
    })

    harness.equal(levels.base(ctx, player, mutations.MUT_TALONS), 0,
        "form appendage does not alter saved mutation levels")
    harness.equal(levels.effective(ctx, player, mutations.MUT_TALONS), 2,
        "form appendage grants a live effective level")

    records.grant_acquired(ctx, player, mutations.MUT_HORNS, 1)
    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 1)
    ctx:set(player, component.PLAYER_FORM, {
        form_id = "spider",
        remaining_aut = 30,
        power = 40,
    })

    harness.equal(levels.base(ctx, player, mutations.MUT_HORNS), 1,
        "suppressed horns remain saved")
    harness.equal(levels.effective(ctx, player, mutations.MUT_HORNS), 0,
        "Spider Form suppresses body mutations")
    harness.equal(levels.effective(ctx, player, mutations.MUT_ROBUST), 1,
        "Spider Form preserves non-body HP mutations")

    records.grant_innate(ctx, player, mutations.MUT_CLEVER, 1)
    records.validate(ctx, player, scheduled, 13)

    records.delete(ctx, player, mutations.MUT_HOP, classes.INNATE, 1)

    local missing_grant = pcall(records.validate, ctx, player, scheduled, 13)

    harness.equal(missing_grant, false,
        "restore rejects a missing scheduled species mutation")
end

return test
