-- Travel tests use an actual committed arrival map for the link and the
-- shared ECS world fixture for actors, clouds, and saved player knowledge.
local catalog = require("policy.generation.vaults.catalog")
local attitudes = require("constants.attitude")
local behaviors = require("constants.ai_behaviors")
local component = require("constants.component")
local features = require("content.terrain_features")
local fixture = require("tests.monster_ally_support_fixture")
local grid = require("policy.generation.grid")
local harness = require("tests.harness")
local intents = require("constants.intent")
local monsters = require("ids.monsters")
local placement = require("policy.generation.vaults.placement")
local terrain = require("constants.terrain")
local transport_ids = require("constants.transporter")
local transporters = require("policy.generation.transporters")
local travel = require("policy.world.transporters")
local navigation = require("policy.commands.navigation")
local stairs = require("systems.world_stairs")
local vaults = require("ids.vaults")

local test = {}

-- Build the source link from the same DES placement and terrain decode that
-- ordinary D:1 generation uses, instead of restating marker definitions.
local function source_link(ctx)
    local builder = grid.new(ctx)
    local map = catalog.get(vaults.spicycebolla_arrival_risky_transporter)
    local placed = placement.place(ctx, builder, map)
    local cells = features.decode_source_rows(builder:rows())
    local level = {
        cells = cells,
        vault_records = features.apply_vault_terrain(cells,
            placed.records, ctx, 1),
    }

    transporters.resolve(level)

    local source
    local destination

    for _, record in ipairs(level.vault_records) do
        if record.identity == transport_ids.SOURCE_CALL ..
            '("tut_risky")' then
            source = record
        elseif record.identity == transport_ids.DESTINATION_CALL ..
            '("tut_risky")' then
            destination = record
        end
    end

    harness.truthy(source, "authored transporter source missing")
    harness.truthy(destination, "authored transporter landing missing")

    return level, source, destination
end

-- Forward ECS methods through the shared fixture while reading the actual
-- resolved link arguments at its authored cell.
local function game_context(ctx, player, level)
    local game = fixture.context(ctx, player)

    game.events = {}

    -- Read the level built from the committed map at the actor's coordinates.
    function game:cell(_, x, y)
        return level.cells[y + 1] and level.cells[y + 1][x + 1]
    end

    -- This fixture includes only the three passable feature kinds needed to
    -- exercise portal placement and nearby follower routing.
    function game:walkable(_, x, y)
        local feature = self:cell(1, x, y)

        return feature == terrain.DNGN_FLOOR or
            feature == terrain.DNGN_TRANSPORTER or
            feature == terrain.DNGN_TRANSPORTER_LANDING
    end

    -- The saved source record is the runtime's link property owner.
    function game:marker_property(_, x, y, key)
        for _, record in ipairs(level.vault_records) do
            if record.x == x and record.y == y and record.arguments then
                return record.arguments[key]
            end
        end
    end

    -- A landing is deliberately not registered as an ordinary stair.
    function game:stair_at()
        return nil
    end

    -- Keep the cloud duration deterministic while using the production RNG
    -- call shape and source stream selection.
    function game:random(_, bound)
        return bound - 1
    end

    -- Capture the same player messages that the game command emits.
    function game:emit(kind, message)
        self.events[#self.events + 1] = {
            kind = kind,
            message = message,
        }
    end

    return game
end

-- Both stair keys activate the same one-way transporter and learn the
-- destination; ordinary action timing and source cloud stay in force.
local function both_stair_keys(ctx)
    local level, source, destination = source_link(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        source.x, source.y)
    local game = game_context(ctx, player, level)

    for _, downstairs in ipairs({ true, false }) do
        local current = ctx:get(player, component.POSITION)
        local decision = navigation.stairs(game, current, downstairs)

        harness.equal(decision.cost, 10,
            "transporter uses an ordinary movement action")
        harness.equal(decision.intent.kind,
            downstairs and intents.DOWNSTAIRS or intents.UPSTAIRS,
            "stair key keeps its command identity")

        if ctx:has(player, component.INTENT) then
            ctx:set(player, component.INTENT, decision.intent)
        else
            ctx:add(player, component.INTENT, decision.intent)
        end

        stairs.update(game, player, 10)

        local arrived = ctx:get(player, component.POSITION)

        harness.equal(arrived.x, destination.x, "arrival x")
        harness.equal(arrived.y, destination.y, "arrival y")

        local landing_command = navigation.stairs(game, arrived, true)

        harness.falsy(landing_command.intent,
            "landing cannot act as a second outbound portal")

        harness.equal(game.events[#game.events].message,
            "You enter the transporter and appear at another place.",
            "source travel message")

        local knowledge = ctx:get(player,
            component.TRANSPORTER_KNOWLEDGE)

        harness.truthy(knowledge, "destination knowledge is saved")

        ctx:set(player, component.POSITION, {
            level_id = 1,
            x = source.x,
            y = source.y,
        })
    end

    local clouds = ctx:query({ component.WORLD_CLOUD })

    harness.truthy(#clouds > 0,
        "travel leaves translocation energy at the old cell")
end

-- A source with no safe landing refuses passage before spending aut.
local function blocked_landing(ctx)
    local level, source, destination = source_link(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        source.x, source.y)
    local game = game_context(ctx, player, level)

    level.cells[destination.y + 1][destination.x + 1] =
        terrain.DNGN_ROCK_WALL

    local decision = navigation.stairs(game,
        ctx:get(player, component.POSITION), true)

    harness.falsy(decision.intent, "blocked landing accepted a stair intent")
    harness.falsy(decision.cost, "blocked landing spent time")
    harness.equal(decision.message,
        "The transporter is blocked on the other side!",
        "blocked landing explains refusal")
end

-- A creature on the landing relocates to nearby habitat before the player
-- appears; it remains alive and never shares the player's destination cell.
local function occupied_landing(ctx)
    local level, source, destination = source_link(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        source.x, source.y)
    local occupant = fixture.actor(ctx, monsters.MONS_RAT,
        destination.x, destination.y)
    local game = game_context(ctx, player, level)
    local decision = navigation.stairs(game,
        ctx:get(player, component.POSITION), true)

    harness.truthy(decision.intent, "relocatable landing occupant blocked travel")
    ctx:add(player, component.INTENT, decision.intent)
    stairs.update(game, player, 10)

    local moved = ctx:get(occupant, component.POSITION)

    harness.truthy(moved.x ~= destination.x or moved.y ~= destination.y,
        "landing occupant did not relocate")
    harness.equal(ctx:get(player, component.POSITION).x,
        destination.x, "player did not reach occupied landing")
end

-- An occupied landing with nowhere to move its creature must refuse the
-- command before time passes, rather than stacking two actors on one cell.
local function sealed_landing(ctx)
    local level, source, destination = source_link(ctx)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN,
        source.x, source.y)
    fixture.actor(ctx, monsters.MONS_RAT,
        destination.x, destination.y)

    for y = destination.y - 5, destination.y + 5 do
        for x = destination.x - 5, destination.x + 5 do
            if x ~= destination.x or y ~= destination.y then
                level.cells[y + 1][x + 1] = terrain.DNGN_ROCK_WALL
            end
        end
    end

    local game = game_context(ctx, player, level)
    local decision = navigation.stairs(game,
        ctx:get(player, component.POSITION), true)

    harness.falsy(decision.intent,
        "occupied landing without a home accepted travel")
    harness.falsy(decision.cost,
        "occupied landing without a home spent time")
end

-- Friendly followers require a walkable route to the source. An adjacent
-- seeker can follow, while a distant seeker and isolated ally cannot.
local function follower_eligibility(ctx)
    local _, source, destination = source_link(ctx)
    local cells = {}

    for y = 1, 20 do
        cells[y] = {}

        for x = 1, 20 do
            cells[y][x] = terrain.DNGN_FLOOR
        end
    end

    source.x = 2
    source.y = 2
    destination.x = 16
    destination.y = 16
    source.arguments[transport_ids.DESTINATION_X] = "16"
    source.arguments[transport_ids.DESTINATION_Y] = "16"
    cells[3][3] = terrain.DNGN_TRANSPORTER
    cells[17][17] = terrain.DNGN_TRANSPORTER_LANDING

    for y = 0, 7 do
        cells[y + 1][5] = terrain.DNGN_ROCK_WALL
    end

    local level = {
        cells = cells,
        vault_records = { source, destination },
    }
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 2, 2)
    local ally = fixture.actor(ctx, monsters.MONS_RAT, 3, 2)
    local isolated = fixture.actor(ctx, monsters.MONS_RAT, 5, 2)
    local seeker = fixture.actor(ctx, monsters.MONS_RAT, 2, 3)
    local distant = fixture.actor(ctx, monsters.MONS_RAT, 3, 4)

    for _, entity in ipairs({ ally, isolated }) do
        ctx:add(entity, component.VAULT_ACTOR_OVERRIDES, {
            attitude = attitudes.FRIENDLY,
        })
    end

    for _, entity in ipairs({ seeker, distant }) do
        ctx:add(entity, component.AI, {
            behavior = behaviors.SEEK,
        })
    end

    local game = game_context(ctx, player, level)

    harness.truthy(travel.take(game, player, 10),
        "controlled transporter trip failed")

    for _, entity in ipairs({ ally, seeker }) do
        local moved = ctx:get(entity, component.POSITION)

        harness.truthy(moved.x >= 11 and moved.y >= 11,
            "eligible follower stayed at departure")
    end

    for _, entity in ipairs({ isolated, distant }) do
        local stayed = ctx:get(entity, component.POSITION)

        harness.truthy(stayed.x <= 5 and stayed.y <= 4,
            "ineligible follower crossed transporter")
    end
end

-- The policy must remain an actual Lua module, not a fabricated test-only
-- implementation of the game's source marker and movement rules.
function test.run(ctx)
    harness.truthy(type(travel.prepare) == "function",
        "transporter travel policy is available")

    both_stair_keys(ctx)
    blocked_landing(ctx)
    occupied_landing(ctx)
    sealed_landing(ctx)
    follower_eligibility(ctx)
end

return test
