-- Ru's powers share the source Exhausted duration with Berserk. This test
-- reads the production status owner and schema instead of copying either.
local component = require("constants.component")
local exhaustion = require("policy.character.exhaustion")
local harness = require("tests.harness")
local rage = require("policy.character.rage")

local test = {}

-- Elapsed aut, not the number of commands, ages Ru's saved cooldown.
function test.run(ctx)
    local player = ctx:create()

    harness.truthy(not exhaustion.active(ctx, player))
    exhaustion.apply(ctx, player, 12)
    harness.truthy(exhaustion.active(ctx, player))
    harness.equal(ctx:get(player,
        component.PLAYER_EXHAUSTION).remaining_aut, 120)
    harness.truthy(not rage.can_begin(ctx, player, true, false))

    exhaustion.tick(ctx, player, 30)
    harness.equal(ctx:get(player,
        component.PLAYER_EXHAUSTION).remaining_aut, 90)
    exhaustion.tick(ctx, player, 90)
    harness.truthy(not exhaustion.active(ctx, player))
    harness.truthy(not ctx:has(player, component.PLAYER_EXHAUSTION))

    -- Existing Berserk cooldown must also block a newly offered Ru power.
    ctx:add(player, component.RAGE, {
        remaining_aut = 0,
        cooldown_aut = 40,
        noncombat_actions = 0,
        attacked_this_turn = false,
    })

    harness.truthy(exhaustion.active(ctx, player))

    -- Active Berserk also forbids these abilities before its cooldown.
    local rage_state = ctx:get(player, component.RAGE)

    rage_state.remaining_aut = 20
    rage_state.cooldown_aut = 0
    ctx:set(player, component.RAGE, rage_state)
    harness.truthy(exhaustion.active(ctx, player))
end

return test
