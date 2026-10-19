
local catalog = require("policy.catalog")
local component = require("constants.component")
local drain = require("policy.combat.monster_hexes.drain_magic")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")

local test = {}

-- Drain Magic removes the source averaged enchantment amount.
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

    -- Read caster and defender records from one store for the MP-drain calculation.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Detect only stored magic components when applying Drain Magic.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Persist the reduced MP so the averaged drain can be asserted.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- Use maximum bounded rolls for the source averaged enchantment amount.
    function ctx:random(_, bound)
        return bound - 1
    end

    -- Ignore combat prose while testing the numeric MP result.
    function ctx:emit()
    end

    local profile = catalog.get("monster_beams", spells.SPELL_DRAIN_MAGIC)

    drain.apply(ctx, caster, player, profile)

    harness.equal(ctx:get(player, component.MAGIC).current, 4,
        "Drain Magic removes the source averaged enchantment amount")
end

return test
