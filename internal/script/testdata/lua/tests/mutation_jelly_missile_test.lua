
local component = require("constants.component")
local items = require("ids.items")
local mutations = require("ids.mutations")
local jelly = require("policy.mutations.effects.projectiles.jelly_missile")
local records = require("policy.mutations.records")
local harness = require("tests.harness")

local test = {}

-- Healing uses random2 of half the final projectile damage.
function test.run(ctx)
    local player = ctx:create()

    ctx:add(player, component.HEALTH, {
        current = 30,
        max = 30,
    })
    records.grant_acquired(ctx, player, mutations.MUT_JELLY_MISSILE, 1)

    harness.falsy(jelly.absorb(ctx, player, items.MI_STONE, 10),
        "full HP blocks jelly missile healing")

    local health = ctx:get(player, component.HEALTH)
    health.current = 20
    ctx:set(player, component.HEALTH, health)

    ctx:add(player, component.PLAYER_STATUS, {
        death_door_aut = 50,
    })

    harness.falsy(jelly.absorb(ctx, player, items.MI_STONE, 10),
        "Death's Door blocks jelly missile healing")

    ctx:remove(player, component.PLAYER_STATUS)

    health.current = 0
    ctx:set(player, component.HEALTH, health)

    harness.falsy(jelly.absorb(ctx, player, items.MI_STONE, 10),
        "a lethal shot cannot be undone by Jelly Missile")

    health.current = 20
    ctx:set(player, component.HEALTH, health)

    local absorbed = false

    for _ = 1, 20 do
        if jelly.absorb(ctx, player, items.MI_STONE, 10) then
            absorbed = true
            break
        end
    end

    harness.truthy(absorbed,
        "an eligible missile can be eaten on the source coin flip")

    health = ctx:get(player, component.HEALTH)

    harness.truthy(health.current >= 20 and health.current <= 24,
        "healing uses random2 of half the final projectile damage")
    harness.falsy(jelly.absorb(ctx, player, items.WPN_DAGGER, 10),
        "weapons are not missile projectiles")
end

return test
