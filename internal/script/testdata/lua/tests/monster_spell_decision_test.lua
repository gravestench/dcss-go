
local catalog = require("policy.catalog")
local component = require("constants.component")
local effects = require("policy.combat.monster_spells")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local spell = require("policy.ai.spell")
local target_kind = require("constants.target_kind")

local test = {}

local monster_entity = 101
local player_entity = 202
local monster_position = { level_id = 1, x = 5, y = 5 }
local near_player = { level_id = 1, x = 6, y = 5 }
local far_player = { level_id = 1, x = 7, y = 5 }

-- Record spell-stream draws and a fixed target position so planner retries
-- cannot consume extra RNG without a test failure.
local function context(draws, silenced, player_position)
    local ctx = {
        used = 0,
        silence_aura = silenced,
        player_position = player_position or near_player,
    }

    -- Supply positions, spellbook, and intent data for one monster decision turn.
    function ctx:get(entity, id)
        if id == component.POSITION then
            return entity == monster_entity and monster_position or
                self.player_position
        end

        if entity == player_entity and
            id == component.PLAYER_STATUS and self.silence_aura then
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

    -- Exclude extra nearby actors so target selection depends only on the player.
    function ctx:query()
        return {}
    end

    -- Leave optional monster statuses absent unless this fixture enables silence.
    function ctx:has()
        return false
    end

    -- Bind the intended player entity for hostile target selection.
    function ctx:player()
        return player_entity
    end

    -- Preserve the entity ID used by the selected spell plan.
    function ctx:id(entity)
        return entity
    end

    -- Keep projectile paths clear so slot choice, not geometry, decides the spell.
    function ctx:projectile_clear()
        return true
    end

    -- Consume scripted monster-spell draws and reject an unexpected bound.
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

-- Natural spell flags bypass silence even when ordinary speech cannot cast.
local function natural_spell_survives_silence()
    local ctx = context({ 0 }, true)
    local intent = spell.choose(ctx, monster_entity, monster_position,
        near_player, false)

    harness.equal(intent.spell_id, spells.SPELL_FREEZE,
        "natural Freeze survives a silence aura")
end

-- A chosen slot carries its entity target plan through the intent boundary.
local function carries_a_selected_entity_plan()
    local original_effect = effects.effect
    local planned = 0

    -- Supply a controlled effect module so the chosen spell plan can be counted.
    effects.effect = function()
        return {
            -- Assert that planning receives the caster and saved foe, then return an entity target.
            plan = function(ctx, caster, foe)
                harness.equal(caster, monster_entity,
                    "the source actor plans its own spell")
                harness.equal(foe, player_entity,
                    "the current foe is the plan target")
                planned = planned + 1
                harness.equal(ctx:random("monster_spell", 2), 1,
                    "target choice consumes one source draw")

                return {
                    kind = target_kind.ENTITY,
                    entity = foe,
                }
            end,
        }
    end

    local ctx = context({ 0, 1 })
    local okay, intent = pcall(spell.choose, ctx, monster_entity,
        monster_position, near_player, false)

    effects.effect = original_effect

    harness.truthy(okay, "spell planning succeeds: " .. tostring(intent))
    harness.equal(planned, 1, "selected target is planned once")
    harness.equal(ctx.used, 2,
        "one prospect and one target draw are consumed")
    harness.equal(intent.target_kind, target_kind.ENTITY,
        "intent carries an entity plan")
    harness.equal(intent.target_entity, player_entity,
        "intent retains the planned foe")
end

-- Temporarily swap one book’s slots while restoring catalog lookup after each case.
local function with_slots(slots, check)
    local book = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
    local original_get = register.get

    book.slots = slots
    -- Override one spellbook ID while the slot-order helper runs its case.
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

-- Pin the second source slot so duplicate spell IDs retain distinct slot identity.
local function chooses_second_slot()
    local book = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
    local freeze = book.slots[1]

    with_slots({
        { spell_id = freeze.spell_id, frequency = 9, flags = freeze.flags },
        { spell_id = freeze.spell_id, frequency = 18, flags = freeze.flags },
    -- Check the second duplicate spell slot after both slots pass eligibility.
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

-- The planner retries another slot only after target validation fails.
local function retries_only_after_bad_target()
    local freeze = catalog.get("monster_spellbooks", "MST_ENDOPLASM")
        .slots[1]

    with_slots({
        { spell_id = freeze.spell_id, frequency = 9, flags = freeze.flags },
        { spell_id = spells.SPELL_SLUG_DART, frequency = 18,
            flags = freeze.flags },
    -- Force a first-slot targeting failure, then verify retry reaches Slug Dart.
    }, function()
        local ctx = context({ 0, 1, 10 }, false, far_player)
        local intent = spell.choose(ctx, monster_entity, monster_position,
            far_player, false)

        harness.equal(intent.spell_id, spells.SPELL_SLUG_DART,
            "second attempt can choose a valid target")
        harness.equal(intent.spell_slot, 2,
            "retry retains source slot index")
        harness.equal(ctx.used, 3,
            "failed target uses a preference coin and second roll")

        ctx = context({ 199 }, false, far_player)
        intent = spell.choose(ctx, monster_entity, monster_position,
            far_player, false)

        harness.falsy(intent, "no-spell roll does not cast")
        harness.equal(ctx.used, 1,
            "no-spell roll does not make a targeting retry")
    end)
end

-- Fleeing changes slot preference without discarding the selected target.
local function fleeing_prefers_escape_spell()
    local original_effect = effects.effect

    with_slots({
        {
            spell_id = spells.SPELL_BLINK,
            frequency = 18,
            flags = {},
        },
    -- Run the escape preference case with a temporary two-slot book.
    }, function()
        -- Offer a fixed entity-target effect so fleeing preference cannot fail on geometry.
        effects.effect = function()
            return {
                -- Return the player entity in the planned escape target.
                plan = function()
                    return {
                        kind = target_kind.ENTITY,
                        entity = player_entity,
                    }
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

-- Duplicate spell ID retains selected source slot.
function test.run()
    natural_spell_survives_silence()
    carries_a_selected_entity_plan()
    chooses_second_slot()
    retries_only_after_bad_target()
    fleeing_prefers_escape_spell()
end

return test
