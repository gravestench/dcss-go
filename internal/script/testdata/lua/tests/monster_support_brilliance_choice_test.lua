local choice = require("policy.ai.spell")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")

local test = {}

-- The first source 200-point roll selects no spell, while the extra
-- Brilliance roll picks a real book slot. The proxy supplies only the
-- host-selected player and deterministic RNG to production AI policy.
local function game_context(ctx, player)
    local game = setmetatable({}, { __index = ctx })
    local draws = { 199, 0 }
    local index = 0

    function game.player()
        return player
    end

    function game.random(_, stream, bound)
        harness.equal(stream, "monster_spell",
            "spell selection uses its named stream")
        harness.equal(bound, 200,
            "both candidate draws use the source book range")

        index = index + 1

        return draws[index] or 0
    end

    function game.projectile_clear()
        return true
    end

    function game.walkable()
        return true
    end

    function game.actor_at(_, level_id, x, y)
        local position = ctx:get(player, component.POSITION)

        if position.level_id == level_id and
            position.x == x and position.y == y then
            return player
        end

        return nil
    end

    return game
end

-- Only an empowered actual caster gets a second prospect after no spell.
function test.run(ctx)
    local caster = ctx:create()
    local player = ctx:create()

    ctx:add(caster, component.ACTOR, {
        kind_id = monsters.MONS_ORC_WIZARD,
        speed = 10,
    })

    ctx:add(caster, component.HEALTH, {
        current = 20,
        max = 20,
    })

    ctx:add(caster, component.POSITION, {
        level_id = 1,
        x = 1,
        y = 1,
    })

    ctx:add(player, component.POSITION, {
        level_id = 1,
        x = 3,
        y = 1,
    })

    local origin = ctx:get(caster, component.POSITION)
    local destination = ctx:get(player, component.POSITION)

    harness.falsy(choice.choose(game_context(ctx, player), caster,
        origin, destination, false),
        "ordinary caster stops after its no-spell result")

    ctx:add(caster, component.MONSTER_EMPOWERED_SPELLS, {
        remaining_aut = 100,
    })

    harness.truthy(choice.choose(game_context(ctx, player), caster,
        origin, destination, false),
        "Brilliance grants one extra source spell prospect")
end

return test
