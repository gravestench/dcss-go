-- Glaciate tests the production cone and spell entry point with only the
-- external grid, damage, and cloud services replaced by a small fixture.
local component = require("constants.component")
local cone = require("policy.combat.monster_area.cone")
local effect = require("policy.combat.monster_spells.glaciate")
local harness = require("tests.harness")
local impact = require("policy.combat.monster_area.impact")
local monsters = require("ids.monsters")
local placement = require("policy.clouds.placement")
local senses = require("policy.character.senses")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local foe = 22
local player = 33

-- Start with the player in the eastward cone. Moving them away lets the
-- same aimed cast proceed without changing the selected foe.
local function context()
    local positions = {
        [caster] = {
            level_id = 1,
            x = 4,
            y = 4,
        },
        [foe] = {
            level_id = 1,
            x = 6,
            y = 4,
        },
        [player] = {
            level_id = 1,
            x = 5,
            y = 5,
        },
    }
    local ctx = {}

    -- This player handle is checked for the source allied safety rule.
    function ctx:player()
        return player
    end

    -- The source decision uses actor HD and the player's current level.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return positions[entity]
        end

        if id == component.ACTOR then
            return {
                kind_id = monsters.MONS_RAT,
            }
        end

        if id == component.PROGRESSION then
            return {
                level = 1,
            }
        end

        if id == component.HEALTH then
            return {
                current = 50,
            }
        end

        return nil
    end

    -- Only the player gets the player marker for HD weighting.
    function ctx:has(entity, id)
        return entity == player and id == component.PLAYER
    end

    -- Every in-bounds cell is floor so cone geometry owns selection.
    function ctx:cell(_, x, y)
        if x < 0 or x > 12 or y < 0 or y > 12 then
            return nil
        end

        return terrain.DNGN_FLOOR
    end

    -- No wall masks the cone edge being tested.
    function ctx:visible_no_trans()
        return true
    end

    -- Read current positions after the test moves the player to safety.
    function ctx:actor_at(_, x, y)
        for entity, position in pairs(positions) do
            if position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- Minimum source rolls make contacts and cloud durations replayable.
    function ctx:random(_, bound)
        harness.truthy(bound > 0,
            "Glaciate uses positive source die bounds")

        return 0
    end

    return ctx, positions
end

-- Check cone boundaries, allied-player refusal, and the ring pass that
-- contacts actors and leaves cold clouds in empty affected cells.
function test.run()
    local old = {
        enemy = targets.enemy,
        aligned = targets.aligned,
        hit = impact.hit,
        place = placement.place,
        seen = senses.player_sees_actor,
    }
    local ctx, positions = context()
    local hits = {}
    local clouds = {}

    -- Only the foe counts as enemy power in the source cone tracer.
    targets.enemy = function(_, _, entity)
        return entity == foe
    end

    -- The player is an ally for the special nondemonic refusal.
    targets.aligned = function(_, _, entity)
        return entity == player
    end

    -- Observe which body the real cone reaches without copying AC rules.
    impact.hit = function(_, _, entity, raw, profile)
        hits[#hits + 1] = {
            entity = entity,
            raw = raw,
            flavour = profile.flavour,
        }
    end

    -- Empty cells still call the production cloud placement boundary.
    placement.place = function(_, kind, _, _, x, y, duration)
        clouds[#clouds + 1] = {
            kind = kind,
            x = x,
            y = y,
            duration = duration,
        }
    end

    -- Suppress display-only sight so the test needs no perception fixture.
    senses.player_sees_actor = function()
        return false
    end

    local cells = cone.cells(ctx, 1, 4, 4, 6, 4, 6)
    local reached = {}

    for _, cell in ipairs(cells) do
        reached[cell.x .. ":" .. cell.y] = true
    end

    harness.truthy(reached["6:4"], "the aimed cell lies in the cone")
    harness.truthy(reached["5:5"], "the diagonal edge lies in the cone")
    harness.falsy(reached["4:5"],
        "the cone excludes a cell directly south of the caster")
    harness.falsy(effect.plan(ctx, caster, foe),
        "a nondemonic ally refuses to Glaciate the player")

    positions[player].x = 1
    positions[player].y = 1

    local plan = effect.plan(ctx, caster, foe)

    harness.truthy(plan, "a foe-only cone can be cast")
    effect.resolve(ctx, caster, foe, nil, plan)
    harness.equal(#hits, 1, "only the foe receives cold contact")
    harness.equal(hits[1].entity, foe,
        "the planned foe remains inside the resolved cone")
    harness.truthy(#clouds > 1,
        "Glaciate fills the cone with cold clouds")

    targets.enemy = old.enemy
    targets.aligned = old.aligned
    impact.hit = old.hit
    placement.place = old.place
    senses.player_sees_actor = old.seen
end

return test
