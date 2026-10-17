local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local spell = require("policy.ai.spell")

local test = {}

local monster_entity = 101
local player_entity = 202
local monster_position = { level_id = 1, x = 5, y = 5 }
local near_player = { level_id = 1, x = 6, y = 5 }
local far_player = { level_id = 1, x = 7, y = 5 }

local function context(draws, silenced)
    local ctx = {
        used = 0,
        silenced = silenced,
    }

    function ctx:get(entity, id)
        if entity == player_entity and
            id == component.PLAYER_STATUS and self.silenced then
            return { silence_aut = 300 }
        end

        if entity == monster_entity and id == component.ACTOR then
            return { kind_id = monsters.MONS_ENDOPLASM }
        end

        if entity == monster_entity and id == component.HEALTH then
            return { current = 10, max = 10 }
        end

        return nil
    end

    function ctx:query()
        return {}
    end

    function ctx:player()
        return player_entity
    end

    function ctx:id(entity)
        return entity
    end

    function ctx:projectile_clear()
        return true
    end

    function ctx:random(stream, bound)
        harness.equal(stream, "monster_spell", "spell RNG stream")
        self.used = self.used + 1

        local draw = draws[self.used]

        harness.truthy(draw and draw >= 0 and draw < bound,
            "fixture draw fits source bound")

        return draw
    end

    return ctx
end

local function natural_spell_survives_silence()
    local ctx = context({ 0 }, true)
    local intent = spell.choose(ctx, monster_entity, monster_position,
        near_player, false)

    harness.equal(intent.spell_id, spells.SPELL_FREEZE,
        "natural Freeze survives a silence aura")
end

local function with_slots(slots, check)
    local book = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
    local original_get = register.get

    book.slots = slots
    register.get = function(category, id)
        if category == "monster_spellbooks" and id == book.id then
            return book
        end

        return original_get(category, id)
    end

    local okay, problem = pcall(check)

    register.get = original_get

    if not okay then
        error(problem)
    end
end

local function chooses_second_slot()
    local book = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
    local freeze = book.slots[1]

    with_slots({
        { spell_id = freeze.spell_id, frequency = 9, flags = freeze.flags },
        { spell_id = freeze.spell_id, frequency = 18, flags = freeze.flags },
    }, function()
        local ctx = context({ 10 })
        local intent = spell.choose(ctx, monster_entity, monster_position,
            near_player, false)

        harness.equal(intent.spell_id, spells.SPELL_FREEZE,
            "second source slot spell")
        harness.equal(intent.spell_slot, 2,
            "duplicate spell ID retains selected source slot")
        harness.equal(ctx.used, 1, "one source prospect roll")
    end)
end

local function retries_only_after_bad_target()
    local freeze = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
        .slots[1]

    with_slots({
        { spell_id = freeze.spell_id, frequency = 9, flags = freeze.flags },
        { spell_id = spells.SPELL_SLUG_DART, frequency = 18,
            flags = freeze.flags },
    }, function()
        local ctx = context({ 0, 1, 10 })
        local intent = spell.choose(ctx, monster_entity, monster_position,
            far_player, false)

        harness.equal(intent.spell_id, spells.SPELL_SLUG_DART,
            "second attempt can choose a valid target")
        harness.equal(intent.spell_slot, 2,
            "retry retains source slot index")
        harness.equal(ctx.used, 3,
            "failed target uses a preference coin and second roll")

        ctx = context({ 199 })
        intent = spell.choose(ctx, monster_entity, monster_position,
            far_player, false)

        harness.falsy(intent, "no-spell roll does not cast")
        harness.equal(ctx.used, 1,
            "no-spell roll does not make a targeting retry")
    end)
end

local function fleeing_prefers_escape_spell()
    local original_effect = effects.effect

    with_slots({
        {
            spell_id = spells.SPELL_BLINK,
            frequency = 18,
            flags = {},
        },
    }, function()
        effects.effect = function()
            return {
                can_cast = function()
                    return true
                end,
            }
        end

        local ctx = context({ 0 })
        local intent = spell.choose(ctx, monster_entity, monster_position,
            near_player, true)

        harness.equal(intent.spell_id, spells.SPELL_BLINK,
            "fleeing chooses a source escape spell")
        harness.equal(ctx.used, 1,
            "fleeing preference uses its weighted spell roll")
    end)

    effects.effect = original_effect
end

function test.run()
    natural_spell_survives_silence()
    chooses_second_slot()
    retries_only_after_bad_target()
    fleeing_prefers_escape_spell()
end

return test
