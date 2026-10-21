-- The shared cloud ring uses a generated lord's saved trait and the same
-- ECS cloud placement owner as source-flag monsters and spells. Terrain
-- and allegiance decide which neighboring cells receive a cloud.
local adjacent = require("constants.adjacent_cells")
local cloud_ids = require("ids.clouds")
local clouds = require("policy.clouds.placement")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local rings = require("policy.combat.monster_cloud_ring")
local ring_ids = require("constants.monster_cloud_rings")
local system = require("systems.combat_monster_cloud_ring")

local test = {}

-- Use production IDs on both sides so changing a cloud catalog entry does
-- not leave a hidden string literal in this test.
local function check_ring_kinds()
    local cases = {
        { ring_ids.THUNDER, cloud_ids.CLOUD_STORM },
        { ring_ids.FLAMES, cloud_ids.CLOUD_FIRE },
        { ring_ids.ICE, cloud_ids.CLOUD_COLD },
        { ring_ids.DRAINING, cloud_ids.CLOUD_NEGATIVE_ENERGY },
        { ring_ids.CHAOS, cloud_ids.CLOUD_CHAOS },
        { ring_ids.ACID, cloud_ids.CLOUD_ACID },
        { ring_ids.MIASMA, cloud_ids.CLOUD_MIASMA },
        { ring_ids.MUTATION, cloud_ids.CLOUD_MUTAGENIC },
        { ring_ids.FOG, cloud_ids.CLOUD_GREY_SMOKE },
    }

    for _, case in ipairs(cases) do
        harness.equal(ring_ids.CLOUD_FOR_RING[case[1]], case[2],
            "source ring cloud " .. case[1])
    end
end

-- A lord's own cloud on its current square disappears, while aligned
-- creatures and other cloud types block creation around it. Same-type
-- adjacent clouds remain, matching Crawl's no-replacement rule.
local function check_surround(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 8, 8, 100)
    local game = fixture.context(ctx, player)
    local lord = fixture.actor(ctx,
        monsters.MONS_PANDEMONIUM_LORD, 20, 20, 100)

    ctx:add(lord, component.PANDEMONIUM_LORD, {
        ring_id = ring_ids.FLAMES,
    })

    local ally = fixture.actor(ctx, monsters.MONS_RAT, 21, 20, 10)

    game.walls["19:20"] = true

    local draws = 0

    function game:random(_, bound)
        harness.equal(bound, 6, "source ring lifetime draw")
        draws = draws + 1

        return 0
    end

    clouds.place(game, cloud_ids.CLOUD_FIRE, lord, 1, 20, 20, 10)
    clouds.place(game, cloud_ids.CLOUD_COLD, lord, 1, 20, 19, 10)
    clouds.place(game, cloud_ids.CLOUD_FIRE, lord, 1, 21, 19, 10)
    rings.surround(game, lord)

    harness.falsy(clouds.at(game, 1, 20, 20),
        "matching cloud under lord is removed")
    harness.falsy(clouds.at(game, 1, 19, 20),
        "wall blocks the ring")
    harness.falsy(clouds.at(game, 1, 21, 20),
        "aligned monster blocks the ring")
    harness.equal(select(2, clouds.at(game, 1, 20, 19)).kind_id,
        cloud_ids.CLOUD_COLD, "competing cloud remains")
    harness.equal(select(2, clouds.at(game, 1, 21, 19)).decay_aut,
        10, "same-type cloud is not refreshed")

    for _, offset in ipairs(adjacent) do
        local x = 20 + offset[1]
        local y = 20 + offset[2]
        local blocked = (x == 19 and y == 20) or
            (x == 21 and y == 20) or (x == 20 and y == 19)

        if not blocked then
            local _, state = clouds.at(game, 1, x, y)

            harness.truthy(state, "open ring cell has cloud")
            harness.equal(state.kind_id, cloud_ids.CLOUD_FIRE,
                "open ring cell uses source cloud")
        end
    end

    harness.equal(draws, 5, "eligible cells consume lifetime draws")
    harness.truthy(ally, "aligned actor is retained")

    -- Refresh follows the lord's new position after movement. A dead lord
    -- cannot paint another ring, even if its saved component still exists.
    game:move_actor(lord, 1, 30, 20)
    system.update(game, lord)

    harness.equal(select(2, clouds.at(game, 1, 30, 19)).kind_id,
        cloud_ids.CLOUD_FIRE, "monster action refreshes new position")

    local health = ctx:get(lord, component.HEALTH)

    health.current = 0
    ctx:set(lord, component.HEALTH, health)
    game:move_actor(lord, 1, 40, 20)
    system.update(game, lord)
    harness.falsy(clouds.at(game, 1, 40, 19),
        "dead lord does not paint a cloud ring")
end

-- The fixture uses real component schemas and cloud placement, so this
-- verifies the saved ring and source cloud behavior together.
function test.run(ctx)
    check_ring_kinds()
    check_surround(ctx)
end

return test
