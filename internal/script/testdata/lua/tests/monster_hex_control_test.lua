
local catalog = require("policy.catalog")
local component = require("constants.component")
local confuse = require("policy.combat.monster_hexes.confuse")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local paralyse = require("policy.combat.monster_hexes.paralyse")
local spells = require("ids.spells")
local zap = require("policy.magic.effects.zaps.ids").component

local test = {}

local caster = 101
local player = 202
local monster = 303

-- The fake world stores player and monster statuses through the same API.
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
                    x = 7,
                    y = 7,
                },
            },

            [monster] = {
                [component.ACTOR] = {
                    kind_id = monsters.MONS_RAT,
                },
                [component.HEALTH] = {
                    current = 10,
                    maximum = 10,
                },
                [component.POSITION] = {
                    level_id = 1,
                    x = 2,
                    y = 1,
                },
            },
        },
    }

    -- Read the saved player status after Confuse and Paralyse resolve.
    function ctx:get(entity, id)
        return self.values[entity] and self.values[entity][id]
    end

    -- Supply the observer while keeping this duration test offscreen.
    function ctx:player()
        return player
    end

    -- Mutations are absent in this isolated control-duration fixture.
    function ctx:query()
        return {}
    end

    -- No player message is expected from the monster-only status path.
    function ctx:visible()
        return false
    end

    -- Create newly applied control effects in the fixture store.
    function ctx:add(entity, id, value)
        self.values[entity][id] = value
    end

    -- Persist timer changes on repeated control applications.
    function ctx:set(entity, id, value)
        self.values[entity][id] = value
    end

    -- Choose low source rolls to expose the minimum-duration clamp.
    function ctx:random()
        return 0
    end

    -- Ignore prose so only saved duration values decide the control result.
    function ctx:emit()
    end

    return ctx
end

-- Paralyse applies the source minimum two player turns.
function test.run()
    local ctx = context()
    local confusion = catalog.get("monster_beams", spells.SPELL_CONFUSE)
    local paralysis = catalog.get("monster_beams", spells.SPELL_PARALYSE)

    confuse.apply(ctx, caster, player, confusion)
    paralyse.apply(ctx, caster, player, paralysis)

    -- Player durations have source minimums; monsters use separate saved
    -- confusion and paralysis components.
    harness.equal(ctx:get(player, zap.PLAYER_CONFUSION).remaining_aut,
        50, "Confuse applies the source minimum five player turns")
    harness.equal(ctx:get(player, component.PLAYER_PARALYSIS).remaining_aut,
        20, "Paralyse applies the source minimum two player turns")

    confuse.apply(ctx, caster, monster, confusion)
    paralyse.apply(ctx, caster, monster, paralysis)

    harness.truthy(ctx:get(monster, component.MONSTER_CONFUSION),
        "Confuse writes the saved monster status")
    harness.truthy(ctx:get(monster, component.PARALYSIS),
        "Paralyse writes the saved monster status")
end

return test
