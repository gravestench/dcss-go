-- Invisibility expires after elapsed action time.

local component = require("constants.component")
local harness = require("tests.harness")
local items = require("ids.items")
local potions = require("policy.potions")
local invisibility = require("policy.potions.invisibility")

local test = {}

-- Apply invisibility and inspect the ECS status seen by targeting rules,
-- rather than asserting only the potion's presentation message.
function test.run(ctx)
    local player = ctx:create()
    local effect = potions.get(items.POT_INVISIBILITY)

    harness.truthy(effect, "invisibility potion is registered")
    harness.falsy(invisibility.active(ctx, player),
        "player starts visible")
    effect.apply(ctx, player)

    harness.equal(ctx:get(player, component.POTION_INVISIBILITY).remaining_aut,
        150, "invisibility starts at source minimum 15 turns")
    harness.truthy(invisibility.active(ctx, player),
        "invisibility changes live visibility")

    ctx:add(player, component.STICKY_FLAME, {
        remaining_aut = 20,
    })
    harness.falsy(invisibility.active(ctx, player),
        "liquid flames reveal an invisible player")
    ctx:remove(player, component.STICKY_FLAME)

    effect.apply(ctx, player)

    harness.equal(ctx:get(player, component.POTION_INVISIBILITY).remaining_aut,
        150, "reusing potion adds a zero-to-39-turn roll")

    invisibility.tick(ctx, player, 150)
    harness.falsy(invisibility.active(ctx, player),
        "invisibility expires after elapsed action time")
end

return test
