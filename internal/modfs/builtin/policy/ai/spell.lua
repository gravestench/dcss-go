local catalog = require("policy.catalog")
local common = require("policy.ai.common")

local books_by_id = {}

for _, book in ipairs(require("data.monster_spellbooks").books) do
    books_by_id[book.id] = book
end

local spell = {}

function spell.choose(ctx, entity, position, player)
    local actor = ctx:get(entity, "core.actor")

    if not actor then
        error("monster " .. ctx:id(entity) .. " has no actor for spell choice")
    end

    local spell_id

    if actor.kind_id == "MONS_ENDOPLASM" and common.adjacent(position, player) then
        spell_id = "SPELL_FREEZE"
    elseif actor.kind_id == "MONS_DART_SLUG" and
        ctx:projectile_clear(position.level_id, position.x, position.y, player.x, player.y) then
        spell_id = "SPELL_SLUG_DART"
    end

    if not spell_id then
        return nil
    end

    local monster = catalog.get("monsters", actor.kind_id)
    local book = books_by_id[monster.spellbook_id]

    if not book or #book.slots ~= 1 or book.slots[1].spell_id ~= spell_id then
        error("unsupported " .. actor.kind_id .. " spellbook " .. tostring(monster.spellbook_id))
    end

    if ctx:random("monster_spell", 200) <= book.slots[1].frequency then
        return {
            kind = 12,
            spell_id = spell_id,
        }
    end

    return nil
end

return spell
