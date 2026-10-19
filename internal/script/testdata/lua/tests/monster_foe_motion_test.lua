-- Defensive briar placement reads a saved observation of foe movement.
-- The test moves one real ECS actor, not a second copy of its position.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local motion = require("policy.ai.foe_motion")
local monsters = require("ids.monsters")

local test = {}

-- Closing distance selects cover; moving away selects an escape-blocking
-- arc. The caster's own movement never changes the stored foe cell.
function test.run(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 5, 1, 30)
    local caster = fixture.actor(ctx,
        monsters.MONS_THORN_HUNTER, 1, 1, 30)
    local game = fixture.context(ctx, player)

    ctx:add(player, component.PLAYER, {})
    ctx:add(caster, component.AI, { behavior = "seek" })

    motion.observe(game, caster)

    harness.falsy(motion.approaching(game, caster, player),
        "the first sighting has no invented movement history")

    game:move_actor(player, 1, 4, 1)
    motion.observe(game, caster)

    harness.truthy(motion.approaching(game, caster, player),
        "a foe moving closer selects the defensive wall")

    game:move_actor(player, 1, 6, 1)
    motion.observe(game, caster)

    harness.falsy(motion.approaching(game, caster, player),
        "a retreating foe selects the distant wall")
end

return test
