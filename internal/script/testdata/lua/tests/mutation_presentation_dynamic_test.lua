local component = require("constants.component")
local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local screen = require("policy.presentation.mutations")
local harness = require("tests.harness")

local test = {}

local function text_of(result)
    local lines = {}

    for _, write in ipairs(result.writes) do
        lines[#lines + 1] = write.text
    end

    return table.concat(lines, "\n")
end

function test.run(ctx)
    local player = ctx:create()

    records.grant_acquired(ctx, player, mutations.MUT_ICEMAIL, 2)
    records.grant_acquired(ctx, player,
        mutations.MUT_CONDENSATION_SHIELD, 1)
    records.grant_acquired(ctx, player,
        mutations.MUT_SANGUINE_ARMOUR, 1)
    ctx:add(player, component.ICY_DEFENSE, { remaining_aut = 0 })
    ctx:add(player, component.SANGUINE_ARMOUR, { remaining_aut = 0 })

    local idle = text_of(screen.rows(ctx, {
        owner = player,
        height = 24,
    }))

    harness.truthy(idle:find("icy envelope protects you from harm. (AC +8)",
        1, true), "Icemail displays its current AC")
    harness.truthy(idle:find("shield of frost defends you. (SH +4)",
        1, true), "Condensation Shield displays source SH")
    harness.truthy(idle:find("blood forms armour. (AC +0)", 1, true),
        "dormant sanguine armour displays zero AC")

    ctx:set(player, component.SANGUINE_ARMOUR, { remaining_aut = 50 })

    local active = text_of(screen.rows(ctx, {
        owner = player,
        height = 24,
    }))

    harness.truthy(active:find("blood forms armour. (AC +6)", 1, true),
        "active sanguine armour displays six AC")
end

return test
