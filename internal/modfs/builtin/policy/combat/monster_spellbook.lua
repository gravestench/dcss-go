local catalog = require("policy.catalog")
local component = require("constants.component")
local vault_spells = require("constants.vault_spell_override")
local book_ids = require("ids.monster_spellbooks")

local spellbook = {}

function spellbook.for_actor(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        error("monster " .. ctx:id(entity) .. " has no actor")
    end

    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

    if overrides and overrides.spells[1] == vault_spells.EMPTY_BOOK then
        return nil
    end

    local monster = catalog.get("monsters", actor.kind_id)

    if not monster.spellbook_id or monster.spellbook_id == "" or
        monster.spellbook_id == book_ids.MST_NO_SPELLS then
        return nil
    end

    return catalog.get("monster_spellbooks", monster.spellbook_id)
end

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
