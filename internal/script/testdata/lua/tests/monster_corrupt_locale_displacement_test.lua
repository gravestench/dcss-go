local component = require("constants.component")
local fixture = require("tests.monster_ally_support_fixture")
local harness = require("tests.harness")
local items = require("ids.items")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local effects = require("policy.combat.monster_spells")
local terrain = require("constants.terrain")

local test = {}

local function setup(ctx, occupant_kind)
    local caster = fixture.actor(ctx, monsters.MONS_MLIOGLOTL, 10, 10)
    local occupant = fixture.actor(ctx, occupant_kind, 12, 10)
    local player = fixture.actor(ctx, monsters.MONS_HUMAN, 0, 0)
    local game = fixture.context(ctx, player)

    game.visible_cells = function()
        return { { x = 12, y = 10 } }
    end
    game.set_cell = function(self, _, x, y, feature)
        self.cells[x .. ":" .. y] = feature
    end
    game.random = function(_, stream, bound)
        if bound == 4001 then
            return 3000 -- source proto rock wall
        elseif bound == 2 then
            return 1 -- retain the solid proto-feature
        end

        return ctx:random(stream, bound)
    end

    return game, caster, occupant, player
end

-- abyss.cc:_corrupt_square_monster pushes floor items and creatures before
-- committing a temporary wall, then saves its original feature for expiry.
function test.run(ctx)
    local game, caster, occupant, player = setup(ctx,
        monsters.MONS_ORC)
    local item = ctx:create()

    ctx:add(item, component.ITEM, {
        kind_id = items.MI_DART,
        quantity = 1,
        plus = 0,
        charges = 0,
        ego = "",
    })
    ctx:add(item, component.POSITION, {
        level_id = 1, x = 12, y = 10,
    })

    local effect = effects.effect(spells.SPELL_CORRUPT_LOCALE)

    effect.resolve(game, caster, player, nil,
        effect.plan(game, caster, player))

    harness.equal(game:cell(1, 12, 10), terrain.DNGN_ROCK_WALL,
        "corruption places a wall after clearing its destination")
    harness.falsy(game:actor_at(1, 12, 10),
        "the former occupant is pushed away")
    local item_position = ctx:get(item, component.POSITION)

    harness.falsy(item_position.x == 12 and item_position.y == 10,
        "floor item is pushed off the new wall")
    harness.truthy(ctx:get(occupant, component.POSITION),
        "displaced actor retains a saved position")
    harness.equal(#ctx:query({ component.TEMPORARY_TERRAIN }), 1,
        "wall has a saved temporary-terrain restoration marker")
    require("policy.save.clouds").validate(game)

    local stationary = fixture.actor(ctx, monsters.MONS_OBSIDIAN_STATUE,
        14, 10)

    game.visible_cells = function()
        return { { x = 14, y = 10 } }
    end
    effect.resolve(game, caster, player, nil,
        effect.plan(game, caster, player))
    harness.equal(game:cell(1, 14, 10), terrain.DNGN_FLOOR,
        "an immovable actor makes solid corruption fall back to floor")
    harness.equal(ctx:get(stationary, component.POSITION).x, 14,
        "stationary actor is not displaced")

    game.aut = function()
        return 200
    end
    require("systems.world_temporary_terrain").update(game, player)
    harness.equal(game:cell(1, 12, 10), terrain.DNGN_FLOOR,
        "saved temporary wall restores its original floor on expiry")
    harness.equal(#ctx:query({ component.TEMPORARY_TERRAIN }), 0,
        "expired marker is removed from saved ECS state")

    game.cells["16:10"] = terrain.DNGN_TREE
    game.visible_cells = function()
        return { { x = 16, y = 10 } }
    end
    effect.resolve(game, caster, player, nil,
        effect.plan(game, caster, player))
    harness.equal(game:cell(1, 16, 10), terrain.DNGN_DEMONIC_TREE,
        "flavor-only corruption makes trees demonic")
end

return test
