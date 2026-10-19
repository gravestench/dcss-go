local catalog = require("policy.catalog")
local component = require("constants.component")
local drain = require("policy.combat.monster_hexes.drain_magic")
local harness = require("tests.harness")
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
                [component.MAGIC] = {
                    current = 5,
                    max = 5,
                },
            },
        },
    }

    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:random(_, bound)
        return bound - 1
    end

    function ctx:emit()
    end

    local profile = catalog.get("monster_beams", spells.SPELL_DRAIN_MAGIC)

    drain.apply(ctx, caster, player, profile)

    harness.equal(ctx:get(player, component.MAGIC).current, 4,
        "Drain Magic removes the source averaged enchantment amount")
end

return test
