local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local slow = require("policy.combat.monster_hexes.slow")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

function test.run()
    local caster = 101
    local player = 202
    local ctx = {
        values = {
            [caster] = {
                [component.ACTOR] = {
                    kind_id = monsters.MONS_ORC_WIZARD,
                },
            },

            [player] = {
                [component.PLAYER] = {},
            },
        },
    }

    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:random()
        return 0
    end

    local profile = catalog.get("monster_beams", spells.SPELL_SLOW)

    slow.apply(ctx, caster, player, profile)

    local status = ctx:get(player, component.PLAYER_SLOW)

    harness.equal(status.remaining_aut, 100,
        "Slow applies the source minimum ten turns to a player")
end

return test
