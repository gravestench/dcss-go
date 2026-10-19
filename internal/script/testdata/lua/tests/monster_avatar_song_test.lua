-- Avatar Song's pull and drowned-soul call use production policies against
-- a small grid fixture. Only actor creation and unrelated resistance owners
-- are fixed so target terrain and placement choices remain under test.
local component = require("constants.component")
local flight = require("policy.combat.flight")
local harness = require("tests.harness")
local habitat = require("policy.combat.monster_habitat")
local monsters = require("ids.monsters")
local pull = require("policy.combat.monster_avatar_song.pull")
local resistance = require("policy.combat.player_resistance")
local senses = require("policy.character.senses")
local souls = require("policy.combat.monster_avatar_song.souls")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")
local water = require("policy.character.water")

local test = {}
local caster = 101
local player = 202
local ally = 303

-- Place one avatar and player on floor, leaving two deep-water cells for
-- deterministic placement without recreating monster definitions.
local function game_context()
    local data = {
        [caster] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_MERFOLK_AVATAR,
                speed = 10,
            },
            [component.POSITION] = {
                level_id = 1,
                x = 2,
                y = 2,
            },
            [component.HEALTH] = {
                current = 20,
                max = 20,
            },
        },
        [player] = {
            [component.PLAYER] = {},
            [component.POSITION] = {
                level_id = 1,
                x = 4,
                y = 2,
            },
        },
        [ally] = {
            [component.ACTOR] = {
                kind_id = monsters.MONS_RAT,
                speed = 10,
            },
        },
    }
    local grid = {
        ["1,2"] = terrain.DNGN_DEEP_WATER,
        ["1,3"] = terrain.DNGN_DEEP_WATER,
    }
    local ctx = {}

    -- Both pull and soul selection read the live position index, not a
    -- copied map of actors from the time the song was cast.
    function ctx:get(entity, id)
        return data[entity] and data[entity][id] or nil
    end

    -- Match component presence without inventing production schema fields.
    function ctx:has(entity, id)
        return data[entity] ~= nil and data[entity][id] ~= nil
    end

    -- The avatar policy must target this player, even on a monster action.
    function ctx:player()
        return player
    end

    -- Filter the fixture by the real component query used for ally strength.
    function ctx:query(required)
        local result = {}

        for _, entity in ipairs({ caster, player, ally }) do
            local matches = true

            for _, id in ipairs(required) do
                matches = matches and data[entity][id] ~= nil
            end

            if matches then
                result[#result + 1] = entity
            end
        end

        return result
    end

    -- Bound water candidates to this small deterministic level.
    function ctx:level_size()
        return 5, 5
    end

    -- Supply the two authored water cells while leaving other cells floor.
    function ctx:cell(_, x, y)
        return grid[x .. "," .. y] or terrain.DNGN_FLOOR
    end

    -- Isolate drowning safety from the grid's ordinary walkability rule.
    function ctx:walkable()
        return true
    end

    -- Read current positions so a completed pull changes later occupancy.
    function ctx:actor_at(level_id, x, y)
        for _, entity in ipairs({ caster, player, ally }) do
            local position = data[entity][component.POSITION]

            if position and position.level_id == level_id and
                position.x == x and position.y == y then
                return entity
            end
        end

        return nil
    end

    -- No wall separates the avatar from the candidate pull cell.
    function ctx:visible_no_trans()
        return true
    end

    -- Choose the adjacent step toward the singer for the pull test.
    function ctx:route_step()
        return -1, 0, true
    end

    -- Apply one grid move to the fixture's spatial record.
    function ctx:move_actor(entity, level_id, x, y)
        data[entity][component.POSITION] = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    -- Preserve the batch contract when the production pull swaps actors.
    function ctx:move_actors(moves)
        for _, move in ipairs(moves) do
            self:move_actor(move.actor, move.level_id,
                move.x, move.y)
        end
    end

    -- Pick a repeatable branch and the first remaining water cell.
    function ctx:random(_, bound)
        harness.truthy(bound > 0,
            "the choice has a positive bound")
        return 0
    end

    -- Messages do not affect pull or placement assertions here.
    function ctx:emit()
    end

    return ctx, data, grid
end

-- Hold unrelated character resistance and summon construction fixed; the
-- production pull and water choice policies still make every decision.
local function fixed_services()
    local old = {
        clarity = resistance.clarity,
        flying = flight.active,
        swimming = water.can_swim,
        visible = senses.player_sees_cell,
        summon = summons.spawn,
        allied = targets.allied,
        habitat = habitat.at,
    }
    local created = {}

    -- Keep unrelated clarity mechanics out of the physical pull test.
    resistance.clarity = function()
        return false
    end

    -- A grounded player makes deep water a meaningful refusal case.
    flight.active = function()
        return false
    end

    -- Refuse swimming so the terrain safety rule must decide the pull.
    water.can_swim = function()
        return false
    end

    -- Observe the first drowned-soul message without sight simulation.
    senses.player_sees_cell = function()
        return true
    end

    -- Record the production policy's chosen cells and inherited HD.
    summons.spawn = function(_, _, _, kind, _, _, options)
        created[#created + 1] = {
            kind = kind,
            x = options.exact.x,
            y = options.exact.y,
            hd = options.hd,
        }
    end

    -- Let a hypothetical occupant be swappable in this isolated grid.
    targets.allied = function()
        return true
    end

    -- The occupant can stand on the player's old floor cell.
    habitat.at = function()
        return true
    end

    return old, created
end

-- Release mutations to cached production modules after the test so later
-- tests retain the real behavior.
local function restore(old)
    resistance.clarity = old.clarity
    flight.active = old.flying
    water.can_swim = old.swimming
    senses.player_sees_cell = old.visible
    summons.spawn = old.summon
    targets.allied = old.allied
    habitat.at = old.habitat
end

-- Test one legal pull, a dangerous-water refusal, and two unique water
-- placements whose HD comes from the avatar's production monster profile.
function test.run()
    local old, created = fixed_services()
    local ctx, data, grid = game_context()

    harness.truthy(pull.apply(ctx, caster, player),
        "the song pulls one open floor step")
    harness.equal(data[player][component.POSITION].x, 3,
        "the grid owner moved the player toward the avatar")

    data[player][component.POSITION].x = 4
    grid["3,2"] = terrain.DNGN_DEEP_WATER

    harness.falsy(pull.apply(ctx, caster, player),
        "a land-bound player refuses a deep-water pull")
    harness.equal(data[player][component.POSITION].x, 4,
        "dangerous terrain leaves the player in place")

    local state = { called = false }

    souls.apply(ctx, caster, state)
    harness.truthy(state.called,
        "deep water begins the avatar's saved call")
    harness.equal(#created, 2,
        "the first successful pulse calls two souls on this draw")
    harness.equal(created[1].kind, monsters.MONS_DROWNED_SOUL,
        "the summoned kind comes from the shared monster ID")
    harness.truthy(created[1].x ~= created[2].x or
        created[1].y ~= created[2].y,
        "souls take distinct deep-water cells")
    harness.equal(created[1].hd, 13,
        "soul HD scales to the source avatar")

    restore(old)
end

return test
