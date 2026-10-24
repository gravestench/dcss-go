local catalog = require("policy.catalog")
local component = require("constants.component")
local vault_spells = require("constants.vault_spell_override")
local book_ids = require("ids.monster_spellbooks")
local spell_flags = require("constants.monster_spell_flags")
local source_spellbook = require("policy.monsters.source_spellbook")
local beast_profile = require("policy.monsters.mutant_beast.profile")

local spellbook = {}

-- Example: spellbook.for_actor(ctx, entity) with EMPTY_BOOK override -> no available spellbook
-- A vault EMPTY_BOOK override suppresses casting even when the monster catalog names a spellbook.
function spellbook.for_actor(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        error("monster " .. ctx:id(entity) .. " has no actor")
    end

    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

    if overrides and overrides.spells[1] == vault_spells.EMPTY_BOOK then
        return nil
    end

    if overrides and overrides.spells[1] then
        return source_spellbook.parse(overrides.spells[1])
    end

    -- The beast's saved facets replace the generic empty catalog book.
    -- An authored vault spell override above still has precedence.
    local beast = ctx:get(entity, component.MONSTER_MUTANT_BEAST)

    if beast then
        return beast_profile.spellbook(beast)
    end

    -- Source living spells carry one custom slot at frequency 200. The
    -- component survives save/restore; the original tome need not survive.
    local living = ctx:get(entity, component.SUMMON_LIVING_SPELL)

    if living then
        return {
            slots = {
                {
                    spell_id = living.spell_id,
                    frequency = 200,
                    flags = {
                        spell_flags.MAGICAL,
                    },
                },
            },
        }
    end

    -- Player-ghost spells are picked when the illusion is created. Rebuild
    -- only a temporary slot view so later player study cannot change it.
    local illusion = ctx:get(entity, component.PLAYER_ILLUSION)

    if illusion then
        if #illusion.spell_ids ~= #illusion.frequencies then
            error("player illusion spell IDs and frequencies differ")
        end

        local slots = {}

        for index, id in ipairs(illusion.spell_ids) do
            slots[index] = {
                spell_id = id,
                frequency = illusion.frequencies[index],
                flags = {
                    spell_flags.WIZARD,
                },
            }
        end

        return #slots > 0 and { slots = slots } or nil
    end

    -- A spellforged servitor keeps the caster's eligible book on its own
    -- component. Reconstruct only the immutable slot view on each read;
    -- selection and execution still use ordinary monster spell policy.
    local servitor = ctx:get(entity, component.SUMMON_SERVITOR)

    if servitor and #servitor.spell_ids > 0 then
        if #servitor.spell_ids ~= #servitor.frequencies then
            error("servitor spell IDs and frequencies differ")
        end

        local slots = {}

        for index, id in ipairs(servitor.spell_ids) do
            slots[index] = {
                spell_id = id,
                frequency = servitor.frequencies[index],
                flags = {
                    spell_flags.WIZARD,
                },
            }
        end

        return { slots = slots }
    end

    -- MST_GHOST has no static catalog row. Pan lords keep their selected
    -- spell slots on the actor, just as source ghost demons do.
    local lord = ctx:get(entity, component.PANDEMONIUM_LORD)

    if lord then
        if #lord.spell_ids ~= #lord.frequencies then
            error("Pan lord spell IDs and frequencies differ")
        end

        local slots = {}

        for index, id in ipairs(lord.spell_ids) do
            slots[index] = {
                spell_id = id,
                frequency = lord.frequencies[index],
                flags = {
                    spell_flags.MAGICAL,
                },
            }
        end

        return #slots > 0 and { slots = slots } or nil
    end

    local monster = catalog.get("monsters", actor.kind_id)

    if not monster.spellbook_id or monster.spellbook_id == "" or
        monster.spellbook_id == book_ids.MST_NO_SPELLS or
        monster.spellbook_id == book_ids.MST_GHOST then
        return nil
    end

    return catalog.get("monster_spellbooks", monster.spellbook_id)
end

-- The selected slot must still contain the requested spell when an intent is resolved.
function spellbook.slot(book, index, spell_id)
    if type(index) ~= "number" or index < 1 or
        index ~= math.floor(index) then
        error("invalid monster spell slot " .. tostring(index))
    end

    local selected = book and book.slots[index]

    if not selected or selected.spell_id ~= spell_id then
        error("spell " .. tostring(spell_id) ..
            " is not in selected monster spell slot " .. index)
    end

    return selected
end

return spellbook
