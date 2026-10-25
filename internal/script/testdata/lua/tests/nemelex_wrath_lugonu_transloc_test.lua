-- Lugonu's displacement uses the ordinary teleport and Abyss owners. The
-- source first chooses a destination, then checks for nearby hostile threat.
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local gods = require("constants.gods")
local harness = require("tests.harness")
local lugonu = require("policy.religion.wrath.lugonu")
local monsters = require("ids.monsters")
local species = require("ids.species")
local streams = require("constants.rng_streams")
local teleport = require("policy.magic.player_teleport")

local test = {}

-- The fixed source draws round level 27's upper depth from five to six,
-- then choose six from the inclusive five-to-six interval.
local function level_scaled_banishment()
    local bounds = {}
    local ctx = {}

    function ctx:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        bounds[#bounds + 1] = bound

        return #bounds == 1 and 0 or 1
    end

    harness.equal(abyss.depth_for_power(ctx, 27,
        streams.CARDS), 6)
    harness.equal(bounds[1], 6)
    harness.equal(bounds[2], 2)
end

-- The selected depth must reach the real Abyss entry API along with the
-- saved outside return site; it cannot be discarded after the draw.
local function banishment_route()
    local player = {}
    local ctx = {}
    local original = abyss.enter
    local entered
    local draws = 0

    function ctx:get(entity, name)
        harness.equal(entity, player)
        harness.equal(name, component.POSITION)

        return {
            level_id = 1,
            x = 8,
            y = 9,
        }
    end

    -- This route starts on an ordinary floor. The source's Arena guard
    -- must see no saved visit before the banishment reaches Abyss entry.
    function ctx:has(entity, name)
        harness.equal(entity, player)
        harness.equal(name, component.PLAYER_ARENA_VISIT)

        return false
    end

    function ctx:random(stream, bound)
        harness.equal(stream, streams.CARDS)
        draws = draws + 1

        return draws == 1 and 0 or bound - 1
    end

    -- The entry message is outside this route assertion; the real owner
    -- still emits it after the captured transition call.
    function ctx:emit()
    end

    abyss.enter = function(_, entity, site, options)
        harness.equal(entity, player)
        entered = {
            site = site,
            depth = options.branch_depth,
        }
    end

    local okay, failure = pcall(abyss.banish, ctx, player, {
        power = 27,
        force = true,
        stream = streams.CARDS,
    })

    abyss.enter = original

    if not okay then
        error(failure)
    end

    harness.equal(entered.depth, 6)
    harness.equal(entered.site.level_id, 1)
    harness.equal(entered.site.x, 8)
    harness.equal(entered.site.y, 9)
end

-- The same landing is rejected until a visible hostile monster threatens
-- it. The first failed attempt leaves position and cloud state untouched.
local function near_monster_teleport(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 0, 0)

    ctx:add(player, component.PLAYER, {
        species_id = species.SP_HUMAN,
    })
    ctx:add(player, component.PROGRESSION, {
        level = 1,
    })

    local owner = fixture.context(ctx, player)

    function owner:level_size()
        return 5, 5
    end

    function owner:records_at()
        return {}
    end

    function owner:random(stream, bound)
        if stream == "teleport" then
            return math.min(2, bound - 1)
        end

        return ctx:random(stream, bound)
    end

    harness.falsy(teleport.now(owner, player, {
        near_monsters = true,
    }))
    harness.equal(ctx:get(player, component.POSITION).x, 0)

    fixture.actor(ctx, monsters.MONS_ORC, 3, 2)

    harness.truthy(teleport.now(owner, player, {
        near_monsters = true,
        reason = "Space warps around you!",
    }))
    harness.equal(ctx:get(player, component.POSITION).x, 2)
    harness.equal(ctx:get(player, component.POSITION).y, 2)

    -- Lugonu's selected branch uses the same threat-sensitive landing,
    -- then continues to its ordinary hostile-minion phase.
    local before = #ctx:query({ component.SUMMON })
    local first_card = true

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            if first_card then
                first_card = false

                return 1
            end

            return 0
        end

        if stream == "teleport" then
            return math.min(4, bound - 1)
        end

        return ctx:random(stream, bound)
    end

    harness.truthy(lugonu.apply(owner, player))
    harness.equal(ctx:get(player, component.POSITION).x, 4)
    harness.equal(ctx:get(player, component.POSITION).y, 4)

    local summoned = ctx:query({ component.SUMMON })

    harness.equal(#summoned - before, 1)
    harness.equal(ctx:get(summoned[#summoned],
        component.SUMMON).source_id, gods.LUGONU)
end

-- The second coinflip passes current XL into forced banishment before the
-- handler continues its minion phase. A separate game test exercises the
-- called owner through a real level transaction and save/restore.
local function wrath_banishment_choice(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 30, 10)
    local owner = fixture.context(ctx, player)
    local original = abyss.banish
    local offered
    local cards = 0
    local before = #ctx:query({ component.SUMMON })

    ctx:add(player, component.PROGRESSION, {
        level = 27,
    })

    function owner:random(stream, bound)
        if stream == streams.CARDS then
            cards = cards + 1

            if cards == 2 then
                harness.equal(bound, 2)

                return 1
            end

            return 0
        end

        return ctx:random(stream, bound)
    end

    abyss.banish = function(_, actor, options)
        harness.equal(actor, player)
        offered = options
    end

    local okay, failure = pcall(lugonu.apply, owner, player)

    abyss.banish = original

    if not okay then
        error(failure)
    end

    harness.truthy(offered)
    harness.equal(offered.power, 27)
    harness.truthy(offered.force)
    harness.equal(offered.stream, streams.CARDS)
    harness.truthy(#ctx:query({ component.SUMMON }) > before)
end

function test.run(ctx)
    level_scaled_banishment()
    banishment_route()
    near_monster_teleport(ctx)
    wrath_banishment_choice(ctx)
end

return test
