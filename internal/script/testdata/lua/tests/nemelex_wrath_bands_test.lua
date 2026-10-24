-- Beogh and Okawaru's wrath leaders use the ordinary monster band catalog.
-- Their followers must retain the god source through the same ECS summon
-- schema as the leader, so saving cannot turn them into ambient monsters.
local attitudes = require("constants.attitude")
local band_members = require("policy.population.band_members")
local branches = require("ids.branches")
local categories = require("constants.catalog")
local catalog = require("policy.catalog")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local streams = require("constants.rng_streams")
local summons = require("policy.religion.wrath.summons")

local test = {}

-- Count only members of this leader, since the world can already contain
-- unrelated bands from earlier cases in the same Lua test runtime.
local function assert_followers(ctx, leader, god_id, minimum,
    expected_kind)
    local count = 0

    for _, actor in ipairs(ctx:query({ component.FOLLOWER })) do
        local link = ctx:get(actor, component.FOLLOWER)

        if link.leader == leader then
            local saved = ctx:get(actor, component.SUMMON)

            harness.truthy(saved)
            harness.equal(saved.source_id, god_id)
            harness.equal(saved.attitude, attitudes.HOSTILE)
            harness.equal(saved.expires_aut, 0)

            if expected_kind then
                harness.equal(ctx:get(actor, component.ACTOR).kind_id,
                    expected_kind)
            end

            count = count + 1
        end
    end

    harness.truthy(count >= minimum)
end

-- A Dungeon warlord brings the source mixed-orc army. An Okawaru knight
-- brings its own band through the same generic placement and save owners.
function test.run(ctx)
    local player = ctx:create()
    local game = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 20,
        y = 20,
    })

    local warlord = summons.hostile(game, player, gods.BEOGH,
        monsters.MONS_ORC_WARLORD, 0, nil, {
            permit_band = true,
        })

    harness.truthy(warlord)
    assert_followers(ctx, warlord, gods.BEOGH, 8)

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 40,
        y = 40,
    })

    local knight = summons.hostile(game, player, gods.OKAWARU,
        monsters.MONS_ORC_KNIGHT, 0, nil, {
            permit_band = true,
        })

    harness.truthy(knight)
    assert_followers(ctx, knight, gods.OKAWARU, 3)

    -- The basic-draconian roster is depth gated. A deep connected Dungeon
    -- floor permits its mixed-species escort without a special wrath path.
    function game:level_depth()
        return 25
    end

    function game:random(stream, bound)
        if stream == streams.BANDS then
            return 0
        end

        return ctx:random(stream, bound)
    end

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 60,
        y = 60,
    })

    local draconian = summons.hostile(game, player, gods.OKAWARU,
        monsters.MONS_BLACK_DRACONIAN, 0, nil, {
            permit_band = true,
        })

    harness.truthy(draconian)
    assert_followers(ctx, draconian, gods.OKAWARU, 2)

    -- Vaults replaces a warlord's mixed band with two to four knights.
    -- The saved follower validator accepts this alternate source roster.
    function game:level_branch()
        return branches.BRANCH_VAULTS
    end

    ctx:set(player, component.POSITION, {
        level_id = 1,
        x = 80,
        y = 80,
    })

    local vault_warlord = summons.hostile(game, player, gods.BEOGH,
        monsters.MONS_ORC_WARLORD, 0, nil, {
            permit_band = true,
        })

    harness.truthy(vault_warlord)
    assert_followers(ctx, vault_warlord, gods.BEOGH, 2,
        monsters.MONS_ORC_KNIGHT)

    local profile = catalog.get(categories.MONSTERS,
        monsters.MONS_ORC_WARLORD).band

    harness.truthy(band_members.allowed(profile,
        monsters.MONS_ORC_KNIGHT))
end

return test
