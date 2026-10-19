
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

-- Store positional and status components so the hex effects can be checked
-- after application, including the original level for banishment restore.
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

    -- Read position and world-hex records from the live fixture store.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Check presence of a saved status before a second world effect.
    function ctx:has(entity, id)
        return self:get(entity, id) ~= nil
    end

    -- Create a newly applied Banishment or Sentinel Mark component.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- Persist a changed position or duration after a world hex.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- Force low world-hex draws so target and duration branches are stable.
    function ctx:random()
        return 0
    end

    -- Permit fixture destinations while Banishment placement is checked.
    function ctx:walkable()
        return true
    end

    -- Leave candidate destinations vacant for the relocation policy.
    function ctx:actor_at()
        return nil
    end

    -- Record the resolved destination to test source-level preservation.
    function ctx:move_actor(entity, level_id, x, y)
        self.values[entity][component.POSITION] = {
            level_id = level_id,
            x = x,
            y = y,
        }
    end

    -- Ignore prose while asserting world and position components.
    function ctx:emit()
    end

    return ctx
end

-- Banishment preserves the source level for restore.
function test.run()
    local ctx = context()
    local mark_profile = catalog.get("monster_beams",
        spells.SPELL_SENTINEL_MARK)
    local strip_profile = catalog.get("monster_beams",
        spells.SPELL_STRIP_WILLPOWER)
    local banish_profile = catalog.get("monster_beams",
        spells.SPELL_BANISHMENT)

    -- Sentinel Mark and Strip Willpower differ in recast viability.
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

    -- Banishment moves to the Abyss while retaining the departure level.
    harness.equal(ctx:get(player, component.POSITION).level_id, 1000,
        "Banishment moves its target to the Abyss")
    harness.equal(ctx:get(player, component.BANISHMENT).origin_level_id, 1,
        "Banishment preserves the source level for restore")
end

return test
