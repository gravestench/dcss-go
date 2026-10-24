-- Terrain effects retain their caster identity. A pacified or dead caster
-- releases only its own markers, while later map edits remain authoritative.
local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local temporary = require("policy.world.temporary_terrain")
local terrain = require("constants.terrain")

local test = {}

-- Two live casters each seal a door. Releasing one must preserve the
-- other's seal and keep both ECS marker records consistent with terrain.
function test.run(ctx)
    local game = fixture.observed_context(ctx)
    local first = fixture.actor(ctx, monsters.MONS_VAULT_WARDEN,
        10, 10, 20)
    local second = fixture.actor(ctx, monsters.MONS_VAULT_WARDEN,
        12, 10, 20)

    game.cells["10:11"] = terrain.DNGN_CLOSED_DOOR
    game.cells["12:11"] = terrain.DNGN_CLOSED_DOOR

    local placed, first_marker = temporary.place(game, first,
        monsters.MONS_VAULT_WARDEN, 1, 10, 11,
        terrain.DNGN_SEALED_DOOR, 100)
    local _, second_marker = temporary.place(game, second,
        monsters.MONS_VAULT_WARDEN, 1, 12, 11,
        terrain.DNGN_SEALED_DOOR, 100)

    harness.truthy(placed)
    harness.equal(game:cell(1, 10, 11), terrain.DNGN_SEALED_DOOR)
    temporary.release_source(game, first)
    harness.equal(game:cell(1, 10, 11), terrain.DNGN_CLOSED_DOOR)
    harness.equal(game:cell(1, 12, 11), terrain.DNGN_SEALED_DOOR)
    harness.falsy(game:has(first_marker, component.TEMPORARY_TERRAIN))
    harness.truthy(game:has(second_marker, component.TEMPORARY_TERRAIN))

    -- A later permanent edit must not be overwritten by stale expiry.
    game:set_cell(1, 12, 11, terrain.DNGN_STONE_WALL)
    temporary.release_source(game, second)
    harness.equal(game:cell(1, 12, 11), terrain.DNGN_STONE_WALL)
end

return test
