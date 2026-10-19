-- Known cancellation is refused without any magical effect.

local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local potions = require("policy.potions")
local zap_ids = require("policy.magic.effects.zaps.ids")

local test = {}

-- Cancel active statuses and inspect both cleared and retained effects,
-- preserving the rule that cancellation does not erase every player state.
function test.run(ctx)
    local player = ctx:create()
    local effect = potions.get(items.POT_CANCELLATION)

    harness.truthy(effect, "cancellation potion is registered")
    harness.truthy(effect.can_quaff(ctx, player),
        "known cancellation is refused without any magical effect")

    ctx:add(player, component.DURATIONS, {
        haste_aut = 200,
        might_aut = 100,
    })
    ctx:add(player, zap_ids.component.CONTAMINATION, {
        amount = 5000,
    })

    harness.falsy(effect.can_quaff(ctx, player),
        "active magical effects permit cancellation")
    effect.apply(ctx, player)

    local durations = ctx:get(player, component.DURATIONS)

    harness.equal(durations.haste_aut, 1,
        "cancellation winds haste down to one aut")
    harness.equal(durations.might_aut, 1,
        "cancellation winds might down to one aut")
    harness.equal(ctx:get(player,
        zap_ids.component.CONTAMINATION).amount, 4000,
        "cancellation reduces contamination by at least 1000")

    -- Confusion alone is a cancellable effect even without haste or might.
    local confused = ctx:create()

    ctx:add(confused, zap_ids.component.PLAYER_CONFUSION, {
        remaining_aut = 100,
    })

    harness.falsy(effect.can_quaff(ctx, confused),
        "confusion alone permits cancellation")
    effect.apply(ctx, confused)
    harness.equal(ctx:get(confused,
        zap_ids.component.PLAYER_CONFUSION).remaining_aut, 1,
        "cancellation shortens confusion")

    local slowing = ctx:create()

    ctx:add(slowing, component.PLAYER_SLOW, {
        remaining_aut = 100,
    })
    effect.apply(ctx, slowing)
    harness.equal(ctx:get(slowing,
        component.PLAYER_SLOW).remaining_aut, 1,
        "cancellation shortens slow")

    -- Petrification wind-down uses its own saved component.
    local turning = ctx:create()

    ctx:add(turning, component.PLAYER_PETRIFICATION, {
        petrifying_aut = 20,
        petrified_aut = 0,
    })
    effect.apply(ctx, turning)
    harness.equal(ctx:get(turning,
        component.PLAYER_PETRIFICATION).petrifying_aut, 0,
        "cancellation stops a player turning to stone")

    -- Haste alone still consumes the cancellation contamination roll, even
    -- when the target has no contamination to reduce.
    local dry = ctx:create()
    local draws = 0
    local tracked = setmetatable({}, { __index = ctx })

    -- Pin cancellation's dispel draw and count calls, so the test notices a
    -- changed chance or extra RNG use even if the final status still clears.
    function tracked.random(_, stream, bound)
        harness.equal(stream, "potion", "cancellation RNG stream")
        harness.equal(bound, 4000, "cancellation RNG bound")
        draws = draws + 1

        return 0
    end

    ctx:add(dry, component.DURATIONS, {
        haste_aut = 100,
    })
    effect.apply(tracked, dry)
    harness.equal(draws, 1,
        "cancellation consumes its roll without contamination")
end

return test
