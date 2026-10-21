-- The source clear stone walls become saved ECS cells, and the Royal Jelly
-- death hook changes the real terrain service used by other game rules.
local component = require("constants.component")
local effects = require("constants.vault_effects")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monster_ids = require("ids.monsters")
local names = require("constants.slime_pit")
local population = require("policy.population.slime_seal")
local save = require("policy.save.slime_seal")
local schema = require("schemas.world_slime_seal")
local seal = require("policy.combat.monster_death.slime_pit")
local terrain = require("constants.terrain")

local test = {}

-- The game fixture delegates ECS operations to production Akara state.
-- Its sparse terrain map only replaces the host grid for these two cells.
local function world(ctx)
    local game = fixture.observed_context(ctx)

    game.messages = {}

    function game:set_cell(_, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end

    function game:emit(_, message)
        self.messages[#self.messages + 1] = message
    end

    return game
end

-- Build a minimal saved source view using the same feature and schema IDs
-- that production population and save validation import.
local function source_record(index, x)
    return {
        index = index,
        kind = effects.MARKER,
        source_id = names.MAP_ID,
        identity = names.SEAL_MARKER,
        x = x,
        y = 10,
    }
end

-- A historical vault origin survives polymorph, so the death rule can
-- recognize its owner without reconstructing the current monster body.
local function royal_jelly(ctx, source_id)
    local actor = fixture.actor(ctx,
        monster_ids.MONS_ROYAL_JELLY, 5, 10, 100)

    ctx:add(actor, component.VAULT_ORIGIN, {
        level_id = 1,
        vault_id = source_id,
        record_index = 3,
        occurrence = 1,
        spawn_x = 5,
        spawn_y = 10,
        kind_id = monster_ids.MONS_ROYAL_JELLY,
    })

    return actor
end

-- Restore checks every source wall before and after the source death
-- callback, and rejects missing, duplicate, or falsely released cells.
function test.run(ctx)
    harness.equal(schema.id, component.SLIME_SEAL,
        "test imports production seal schema")

    local game = world(ctx)
    local first = source_record(1, 12)
    local second = source_record(2, 13)
    local level = {
        id = 1,
        vault_records = { first, second },
    }
    local input = {
        levels = { level },
    }

    game:set_cell(1, 12, 10, terrain.DNGN_CLEAR_STONE_WALL)
    game:set_cell(1, 13, 10, terrain.DNGN_CLEAR_STONE_WALL)

    local one = population.materialize(game, level, first)
    local two = population.materialize(game, level, second)

    harness.equal(one.index, 1, "first source index")
    harness.equal(two.index, 2, "second source index")
    save.validate(game, input)

    local unrelated = royal_jelly(ctx, "unrelated_map")

    seal.on_death(game, unrelated)
    harness.equal(game:cell(1, 12, 10),
        terrain.DNGN_CLEAR_STONE_WALL,
        "unrelated Royal Jelly cannot open the seal")

    local source = royal_jelly(ctx, names.MAP_ID)

    seal.on_death(game, source)
    harness.equal(game:cell(1, 12, 10), terrain.DNGN_FLOOR,
        "first source wall fell")
    harness.equal(game:cell(1, 13, 10), terrain.DNGN_FLOOR,
        "second source wall fell")
    harness.equal(#game.messages, 1, "collapse is announced once")
    save.validate(game, input)

    seal.on_death(game, source)
    harness.equal(#game.messages, 1, "released seal is idempotent")

    game:set_cell(1, 12, 10, terrain.DNGN_CLEAR_STONE_WALL)
    harness.falsy(pcall(save.validate, game, input),
        "forged released wall was accepted")
    game:set_cell(1, 12, 10, terrain.DNGN_FLOOR)

    local original = {}

    for _, entity in ipairs(game:query({ component.SLIME_SEAL })) do
        original[entity] = true
    end

    local extra = population.materialize(game, level, first)

    harness.equal(extra.index, 1, "duplicate uses first source")
    harness.falsy(pcall(save.validate, game, input),
        "duplicate source seal was accepted")

    -- A deleted cell is just as invalid as a duplicate: a later death
    -- would leave its authored wall sealed forever.
    for _, entity in ipairs(game:query({ component.SLIME_SEAL })) do
        local state = game:get(entity, component.SLIME_SEAL)

        if not original[entity] or state.record_index == second.index then
            game:remove(entity, component.SLIME_SEAL)
        end
    end

    harness.falsy(pcall(save.validate, game, input),
        "missing source seal was accepted")
end

return test
