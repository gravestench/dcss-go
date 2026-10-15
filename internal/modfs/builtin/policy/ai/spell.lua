local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local statuses = require("policy.magic.effects.statuses.player")
local engulf = require("policy.combat.engulf")

local books_by_id = {}

for _, book in ipairs(catalog.all("monster_spellbooks")) do
    books_by_id[book.id] = book
end

local spell = {}

function spell.choose(ctx, entity, position, player)
    if engulf.silenced(ctx, entity) then
        return nil
    end

    local radius = statuses.silence_radius(ctx, ctx:player())
    local distance = math.max(math.abs(position.x - player.x),
        math.abs(position.y - player.y))

    if radius >= 0 and distance <= radius then
        return nil
    end

    local actor = ctx:get(entity, "core.actor")

    if not actor then
        error("monster " .. ctx:id(entity) .. " has no actor for spell choice")
    end

    local monster = catalog.get("monsters", actor.kind_id)
    local book = books_by_id[monster.spellbook_id]

    if not book then
        return nil
    end

    if #book.slots ~= 1 then
        error("unsupported " .. actor.kind_id .. " spellbook " .. tostring(monster.spellbook_id))
    end

    local slot = book.slots[1]
    local effect = effects.effect(slot.spell_id)

    if not effect.can_cast(ctx, position, player) then
        return nil
    end

    if ctx:random("monster_spell", 200) <= slot.frequency then
        if statuses.enfeeble_antimagic(ctx, entity, slot.flags) then
            return nil
        end

        return {
            kind = 12,
            spell_id = slot.spell_id,
        }
    end

    return nil
end

return spell
