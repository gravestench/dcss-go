local banishment = require("policy.combat.monster_hexes.banishment")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local mark = require("policy.combat.monster_hexes.sentinel_mark")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local strip = require("policy.combat.monster_hexes.strip_willpower")

local test = {}

local caster = 101
local player = 202

local function context()
    local ctx = {
        values = {
            [caster] = {
                [component.ACTOR] = {
                    kind_id = monsters.MONS_ORC_WIZARD,
                },
            },

            [player] = {
                [component.PLAYER] = {},
                [component.POSITION] = {
                    level_id = 1,
                    x = 4,
                    y = 4,
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

    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    function ctx:random()
        return 0
    end

    function ctx:walkable()
        return true
    end

    function ctx:actor_at()
        return nil
    end

    function ctx:move_actor(entity, level_id, x, y)
        self.values[entity][component.POSITION] = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    function ctx:emit()
    end

    return ctx
end

function test.run()
    local ctx = context()
    local mark_profile = catalog.get("monster_beams",
        spells.SPELL_SENTINEL_MARK)
    local strip_profile = catalog.get("monster_beams",
        spells.SPELL_STRIP_WILLPOWER)
    local banish_profile = catalog.get("monster_beams",
        spells.SPELL_BANISHMENT)

    harness.truthy(mark.viable(ctx, caster, player, mark_profile),
        "Sentinel Mark can target the player")
    mark.apply(ctx, caster, player, mark_profile)

    harness.truthy(ctx:get(player, component.TRAP_MARK),
        "Sentinel Mark writes its saved tracker")

    strip.apply(ctx, caster, player, strip_profile)

    harness.truthy(ctx:get(player,
        component.PLAYER_STATUS).lowered_will_aut > 0,
        "Strip Willpower writes the saved player status")
    harness.falsy(strip.viable(ctx, caster, player, strip_profile),
        "Strip Willpower avoids an already stripped foe")

    banishment.apply(ctx, caster, player, banish_profile)

    harness.equal(ctx:get(player, component.POSITION).level_id, 1000,
        "Banishment moves its target to the Abyss")
    harness.equal(ctx:get(player, component.BANISHMENT).origin_level_id, 1,
        "Banishment preserves the source level for restore")
end

return test
