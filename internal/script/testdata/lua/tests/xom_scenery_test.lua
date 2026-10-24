-- Xom scenery changes live terrain through the normal grid. This test
-- supplies a small visible area while keeping ECS entities in production.
local component = require("constants.component")
local events = require("ids.xom_events")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local scenery = require("policy.religion.xom.effects.scenery")
local terrain = require("constants.terrain")

local test = {}

-- A visible fountain is a source scenery candidate. Its change is kept
-- in the grid, so rendering and saving read the same blood fountain.
function test.run(ctx)
    local player = ctx:create()
    local owner = fixture.context(ctx, player)

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 7,
        y = 7,
    })

    owner.cells["8:7"] = terrain.DNGN_FOUNTAIN_BLUE

    function owner:visible_cells()
        return {
            { x = 7, y = 7 },
            { x = 8, y = 7 },
        }
    end

    harness.equal(#scenery.candidates(owner, player), 1)

    local changed = scenery.apply(owner, player,
        events.GOOD_SCENERY, 8)

    harness.equal(changed, 1)
    harness.equal(owner:cell(1, 8, 7),
        terrain.DNGN_FOUNTAIN_BLOOD)

    owner.cells["8:7"] = terrain.DNGN_FLOOR

    local near_axis = 0

    function owner:random(_, bound)
        if bound == 13 then
            near_axis = near_axis + 1
            return near_axis % 2 == 1 and 8 or 6
        end

        return 0
    end

    local altars = scenery.apply(owner, player,
        events.GOOD_SCENERY, 8)

    harness.truthy(terrain.DNGN_ALTAR_XOM)
    harness.equal(altars, 1)
    harness.equal(owner:cell(1, 9, 7),
        terrain.DNGN_ALTAR_XOM)

    -- A second door in the same gate is changed even when the first is
    -- the only one visible in the small source vision window.
    owner.cells["8:7"] = terrain.DNGN_OPEN_DOOR
    owner.cells["8:8"] = terrain.DNGN_OPEN_DOOR

    function owner:cell(_, x, y)
        if x < 4 or x > 11 or y < 4 or y > 11 then
            return nil
        end

        return self.cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    harness.equal(#scenery.candidates(owner, player), 2)

    local doors = scenery.apply(owner, player,
        events.GOOD_SCENERY, 8)

    harness.equal(doors, 2)
    harness.equal(owner:cell(1, 8, 7), terrain.DNGN_CLOSED_DOOR)
    harness.equal(owner:cell(1, 8, 8), terrain.DNGN_CLOSED_DOOR)

    -- The alternate empty-scenery result creates ordinary saved summons.
    owner.cells["8:7"] = terrain.DNGN_FLOOR
    owner.cells["8:8"] = terrain.DNGN_FLOOR

    function owner:random(_, bound)
        return bound == 2 and 1 or 0
    end

    local butterflies = scenery.apply(owner, player,
        events.GOOD_SCENERY, 8)

    harness.truthy(butterflies > 0)
    harness.equal(#ctx:query({ component.SUMMON }), butterflies)
end

return test
