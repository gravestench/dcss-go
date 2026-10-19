local component = require("constants.component")
local harness = require("tests.harness")
local spells = require("policy.combat.monster_spells")
local terrain = require("constants.terrain")

local test = {}
local caster = 11
local player = 12

local function context(branch)
    local ctx = {
        branch = branch or "BRANCH_DUNGEON",
        cells = {},
        components = {},
        events = {},
        rolls = {},
        roll_map = {},
        markers = {},
        next_entity = 100,
        now = 100,
    }

    function ctx:player()
        return player
    end

    function ctx:aut()
        return self.now
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:level_branch()
        return self.branch
    end

    function ctx:get(entity, id)
        local supplied = self.components[entity .. ":" .. id]

        if supplied then
            return supplied
        end

        if id == component.POSITION then
            if entity == caster then
                return { level_id = 1, x = 4, y = 4 }
            end

            if entity == player then
                return { level_id = 1, x = 6, y = 4 }
            end
        end

        if id == component.ACTOR and entity == caster then
            return { kind_id = "MONS_EARTH_ELEMENTAL", speed = 10 }
        end

        if id == component.HEALTH then
            return { current = 30, max = 30 }
        end

        if id == component.PROGRESSION and entity == player then
            return { level = 1 }
        end

        return self.components[entity .. ":" .. id]
    end

    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    function ctx:add(entity, id, value)
        self.components[entity .. ":" .. id] = value
    end

    function ctx:set(entity, id, value)
        self.components[entity .. ":" .. id] = value
    end

    function ctx:create()
        self.next_entity = self.next_entity + 1
        return self.next_entity
    end

    function ctx:remove(entity, id)
        self.components[entity .. ":" .. id] = nil
    end

    function ctx:destroy(entity)
        for key in pairs(self.components) do
            if key:match("^(%d+):") == tostring(entity) then
                self.components[key] = nil
            end
        end
    end

    function ctx:query(ids)
        local found = {}

        if ids[1] == component.ACTOR then
            found[1] = caster
        end

        for key in pairs(self.components) do
            local entity, id = key:match("^(%d+):(.+)$")

            if id == ids[1] then
                found[#found + 1] = tonumber(entity)
            end
        end

        table.sort(found)

        return found
    end

    function ctx:cell(_, x, y)
        if x < 1 or y < 1 or x > 9 or y > 9 then
            return nil
        end

        return self.cells[x .. ":" .. y] or terrain.DNGN_FLOOR
    end

    function ctx:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    function ctx:marker_property(_, x, y, name)
        local marker = self.markers[x .. ":" .. y]

        return marker and marker[name] or nil
    end

    function ctx:visible()
        return true
    end

    function ctx:visible_no_trans()
        return true
    end

    function ctx:visible_no_trans_with_blocked(_, from_x, from_y, _, to_x, to_y, blocked)
        for _, cell in ipairs(blocked) do
            if cell.x == 5 and (cell.y == 4 or cell.y == 5) and
                (from_x - 5) * (to_x - 5) < 0 and
                from_y == to_y and to_y == cell.y then
                return false
            end
        end

        return true
    end

    function ctx:visible_cells()
        local cells = {}

        for y = 1, 9 do
            for x = 1, 9 do
                cells[#cells + 1] = { x = x, y = y }
            end
        end

        return cells
    end

    function ctx:actor_at(_, x, y)
        if x == 4 and y == 4 then
            return caster
        end

        if x == 6 and y == 4 then
            return player
        end

        return nil
    end

    function ctx:walkable(level_id, x, y)
        local feature = self:cell(level_id, x, y)

        return feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_SHALLOW_WATER
    end

    function ctx:place_actor(entity, level_id, x, y)
        self.components[entity .. ":" .. component.POSITION] = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    function ctx:move_actor(entity, level_id, x, y)
        self:place_actor(entity, level_id, x, y)
    end

    function ctx:random(_, bound)
        self.rolls[#self.rolls + 1] = bound
        return self.roll_map[bound] or 0
    end

    function ctx:emit(_, message)
        self.events[#self.events + 1] = message
    end

    return ctx
end

function test.run()
    local awaken = spells.effect("SPELL_AWAKEN_EARTH")
    local awaken_ctx = context()

    awaken_ctx.cells["7:4"] = terrain.DNGN_ROCK_WALL
    awaken_ctx.cells["6:5"] = terrain.DNGN_CLEAR_ROCK_WALL

    local aim = awaken.plan(awaken_ctx, caster, player)

    harness.truthy(aim, "wall-adjacent foe is a valid earth target")
    harness.equal(aim.x, 6, "awaken earth aims at the foe's cell")

    awaken.resolve(awaken_ctx, caster, player, nil, aim)

    harness.equal(awaken_ctx:cell(1, 6, 5), terrain.DNGN_FLOOR,
        "fair adjacency begins at the source-chosen clear rock wall")
    harness.equal(awaken_ctx:cell(1, 7, 4), terrain.DNGN_ROCK_WALL,
        "summon limit stops before the later wall")
    harness.equal(#awaken_ctx:query({ component.SUMMON }), 1,
        "destroyed rock produces a timed elemental")

    local center_ctx = context()

    center_ctx.cells["5:4"] = terrain.DNGN_ROCK_WALL
    awaken.resolve(center_ctx, caster, player, nil, {
        kind = "cell",
        level_id = 1,
        x = 5,
        y = 4,
    })

    harness.equal(center_ctx:cell(1, 5, 4), terrain.DNGN_FLOOR,
        "fair adjacency can awaken its center wall")

    for _, bound in ipairs(center_ctx.rolls) do
        harness.falsy(bound == 8,
            "a successful center wall needs no neighbour-angle draw")
    end

    local veto_ctx = context()

    veto_ctx.cells["5:4"] = terrain.DNGN_ROCK_WALL
    veto_ctx.markers["5:4"] = { veto_destroy = "veto" }
    awaken.resolve(veto_ctx, caster, player, nil, {
        kind = "cell", level_id = 1, x = 5, y = 4,
    })

    harness.equal(veto_ctx:cell(1, 5, 4), terrain.DNGN_ROCK_WALL,
        "a vault veto_destroy marker protects rock from Awaken Earth")
    harness.equal(#veto_ctx:query({ component.SUMMON }), 0,
        "protected rock produces no elemental")

    local tide = spells.effect("SPELL_CALL_TIDE")
    local tide_ctx = context("BRANCH_SHOALS")

    harness.truthy(tide.plan(tide_ctx, caster, player),
        "Shoals caster may call a tide")
    harness.falsy(tide.plan(context("BRANCH_DUNGEON"), caster, player),
        "call tide is impossible outside Shoals")

    tide.resolve(tide_ctx, caster, player, nil,
        tide.plan(tide_ctx, caster, player))

    local tide_state = tide_ctx:get(caster, "world.called_tide")

    harness.truthy(tide_state and tide_state.expires_aut > tide_ctx:aut(),
        "call tide stores a timed caster state")
    harness.falsy(tide.plan(tide_ctx, caster, player),
        "an active tide cannot be called twice")

    -- The level-owned heightmap, tide clock, and connected-coast traversal
    -- are exercised in shoals_tide_test.lua with a dedicated Shoals fixture.

    local corruption = spells.effect("SPELL_CORRUPT_LOCALE")
    local corrupt_ctx = context()

    corrupt_ctx.roll_map[4001] = 3000
    corrupt_ctx.roll_map[2] = 1
    corrupt_ctx.visible_cells = function()
        return { { x = 5, y = 4 } }
    end

    harness.falsy(corruption.plan(context("BRANCH_ABYSS"), caster, player),
        "corrupt locale is impossible in Abyss")
    harness.truthy(corruption.plan(corrupt_ctx, caster, player),
        "other branches permit monster corruption")

    corruption.resolve(corrupt_ctx, caster, player, nil,
        corruption.plan(corrupt_ctx, caster, player))

    harness.truthy(#corrupt_ctx.rolls > 0,
        "corruption rolls across nearby dungeon terrain")
    harness.equal(corrupt_ctx:cell(1, 5, 4), terrain.DNGN_ROCK_WALL,
        "monster corruption changes a bare floor temporarily")
    harness.equal(#corrupt_ctx:query({ component.SUMMON }), 1,
        "monster corruption calls an Abyss servant")

    local servant = corrupt_ctx:query({ component.SUMMON })[1]

    harness.equal(corrupt_ctx:get(servant, component.ACTOR).kind_id,
        "MONS_ABOMINATION_SMALL",
        "Abyss:1 population supplies the first eligible servant")

    local corruption_marker = corrupt_ctx:query({
        component.TEMPORARY_TERRAIN,
    })[1]
    local corruption_state = corrupt_ctx:get(corruption_marker,
        component.TEMPORARY_TERRAIN)

    harness.equal(corruption_state.expires_aut, 160,
        "Abyss terrain change lasts the source 60 aut minimum")

    local crowded_ctx = context()

    crowded_ctx.roll_map[4001] = 3000
    crowded_ctx.roll_map[2] = 1
    crowded_ctx.visible_cells = function()
        return { { x = 5, y = 4 } }
    end

    for _, point in ipairs({
        { 4, 3 }, { 5, 3 }, { 6, 3 },
        { 5, 5 }, { 6, 5 },
    }) do
        crowded_ctx.cells[point[1] .. ":" .. point[2]] =
            terrain.DNGN_ROCK_WALL
    end

    corruption.resolve(crowded_ctx, caster, player, nil,
        corruption.plan(crowded_ctx, caster, player))

    harness.equal(crowded_ctx:cell(1, 5, 4), terrain.DNGN_FLOOR,
        "corruption does not wall off a crowded square")

    local seal = spells.effect("SPELL_SEAL_DOORS")
    local seal_ctx = context()

    seal_ctx.cells["5:4"] = terrain.DNGN_CLOSED_DOOR

    local seal_plan = seal.plan(seal_ctx, caster, player)

    harness.truthy(seal_plan, "a visible closed door justifies sealing")
    harness.equal(seal_ctx.rolls[1], 80,
        "warden AI check consumes its source duration draw")
    seal.resolve(seal_ctx, caster, player, nil, seal_plan)

    harness.equal(seal_ctx.rolls[2], 80,
        "the actual seal cast draws a fresh duration")

    harness.equal(seal_ctx:cell(1, 5, 4), "DNGN_SEALED_DOOR",
        "closed door receives a timed seal")

    seal_ctx.now = 180
    require("systems.world_temporary_terrain").update(seal_ctx, player)

    harness.equal(seal_ctx:cell(1, 5, 4), terrain.DNGN_CLOSED_DOOR,
        "the door seal expires back to the original door")

    local friendly_ctx = context()

    friendly_ctx.cells["5:4"] = terrain.DNGN_CLOSED_DOOR
    friendly_ctx:add(caster, component.SUMMON, {
        attitude = "friendly",
    })

    harness.falsy(seal.plan(friendly_ctx, caster, player),
        "a friendly warden never seals the player's escape")

    local double_ctx = context()

    double_ctx.cells["5:4"] = terrain.DNGN_OPEN_DOOR
    double_ctx.cells["5:5"] = terrain.DNGN_OPEN_DOOR

    for _, threat in ipairs({ 81, 82 }) do
        double_ctx:add(threat, component.ACTOR, {
            kind_id = "MONS_EARTH_ELEMENTAL", speed = 10,
        })
        double_ctx:add(threat, component.POSITION, {
            level_id = 1, x = 7, y = threat - 77,
        })
    end

    local double_plan = seal.plan(double_ctx, caster, player)

    harness.truthy(double_plan, "connected open door has a sealing plan")
    seal.resolve(double_ctx, caster, player, nil, double_plan)

    harness.equal(double_ctx:cell(1, 5, 4), terrain.DNGN_SEALED_DOOR,
        "first panel of a connected doorway is sealed")
    harness.equal(double_ctx:cell(1, 5, 5), terrain.DNGN_SEALED_DOOR,
        "second panel of a connected doorway is sealed")

    local hostile_door_ctx = context()

    hostile_door_ctx.cells["5:4"] = terrain.DNGN_OPEN_DOOR
    hostile_door_ctx.actor_at = function(_, _, x, y)
        if x == 5 and y == 4 then
            return 77
        end

        return nil
    end

    harness.falsy(seal.plan(hostile_door_ctx, caster, player),
        "a hostile creature blocking an open door prevents force closing")

    local jammed_ctx = context()

    jammed_ctx.cells["5:4"] = terrain.DNGN_OPEN_DOOR
    jammed_ctx.cells["5:5"] = terrain.DNGN_OPEN_DOOR

    for _, threat in ipairs({ 81, 82 }) do
        jammed_ctx:add(threat, component.ACTOR, {
            kind_id = "MONS_EARTH_ELEMENTAL", speed = 10,
        })
        jammed_ctx:add(threat, component.POSITION, {
            level_id = 1, x = 7, y = threat - 77,
        })
    end

    local jammed_plan = seal.plan(jammed_ctx, caster, player)
    local moved = 0

    jammed_ctx:add(77, component.SUMMON, { attitude = "friendly" })
    jammed_ctx:add(78, component.SUMMON, { attitude = "friendly" })
    jammed_ctx.actor_at = function(_, _, x, y)
        if x == 5 and y == 4 then
            return 77
        end

        if x == 5 and y == 5 then
            return 78
        end

        return nil
    end
    jammed_ctx.walkable = function(_, _, x, y)
        return x == 5 and y == 3
    end
    jammed_ctx.move_actor = function()
        moved = moved + 1
    end

    seal.resolve(jammed_ctx, caster, player, nil, jammed_plan)

    harness.equal(moved, 0,
        "a later jammed panel cannot cause a partial actor push")
    harness.equal(jammed_ctx:cell(1, 5, 4), terrain.DNGN_OPEN_DOOR,
        "a jammed group leaves all panels open")

    local shelter_ctx = context()

    shelter_ctx.cells["5:4"] = terrain.DNGN_OPEN_DOOR
    harness.falsy(seal.plan(shelter_ctx, caster, player),
        "warden leaves a door open when closure would hide the only threat")
    seal.resolve(shelter_ctx, caster, player, nil,
        require("policy.combat.monster_support.self_target").plan(caster))
    harness.equal(shelter_ctx:cell(1, 5, 4), terrain.DNGN_OPEN_DOOR,
        "resolution rechecks tension before forcing the door shut")

    local pushed_ctx = context()

    pushed_ctx.cells["5:4"] = terrain.DNGN_OPEN_DOOR
    pushed_ctx:add(player, component.POSITION, {
        level_id = 1, x = 5, y = 4,
    })
    pushed_ctx.walkable = function(_, _, x, y)
        return x == 6 and y == 3 or x == 4 and y == 5
    end
    pushed_ctx.actor_at = function(_, _, x, y)
        if x == 5 and y == 4 then
            return player
        end

        if x == 4 and y == 4 then
            return caster
        end
    end
    pushed_ctx.visible_no_trans_with_blocked = function(_, _, from_x)
        return from_x < 5
    end

    local pushed_plan = seal.plan(pushed_ctx, caster, player)

    harness.truthy(pushed_plan,
        "player in a door can be pushed toward the threatening side")
    seal.resolve(pushed_ctx, caster, player, nil, pushed_plan)

    local pushed_position = pushed_ctx:get(player, component.POSITION)

    harness.equal(pushed_position.x, 4,
        "forced closure selects the maximum-tension push side")
    harness.equal(pushed_position.y, 5,
        "forced closure skips an earlier sheltering push square")

    local stair_ctx = context()

    stair_ctx.cells["5:4"] = terrain.DNGN_STONE_STAIRS_UP_I

    seal.resolve(stair_ctx, caster, player, nil,
        seal.plan(stair_ctx, caster, player))

    harness.equal(stair_ctx:cell(1, 5, 4), terrain.DNGN_SEALED_STAIRS_UP,
        "a visible stair is sealed without deleting its original feature")

    local clear_ctx = context()

    clear_ctx.cells["5:4"] = "DNGN_CLOSED_CLEAR_DOOR"

    local clear_plan = seal.plan(clear_ctx, caster, player)

    harness.truthy(clear_plan, "translucent doors can be sealed")
    seal.resolve(clear_ctx, caster, player, nil, clear_plan)

    harness.equal(clear_ctx:cell(1, 5, 4),
        terrain.DNGN_SEALED_CLEAR_DOOR,
        "a translucent door keeps its clear sealed feature")
end

return test
