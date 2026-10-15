local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")

local spellbooks = {}

for _, book in ipairs(catalog.all("monster_spellbooks")) do
    spellbooks[book.id] = book
end

local system = {}

function system.update(ctx, caster)
    local intent = ctx:get(caster, "core.intent")

    if not intent or intent.kind ~= 12 then
        return
    end

    -- Construct abilities resolve in their own Lua decision policy.
    -- They retain spell-speed energy without using a monster spellbook.
    if ctx:has(caster, "magic.summon") then
        return
    end

    local player = ctx:player()
    local actor = ctx:get(caster, "core.actor")
    local caster_pos = ctx:get(caster, "core.position")
    local player_pos = ctx:get(player, "core.position")
    local caster_health = ctx:get(caster, "core.health")
    local player_health = ctx:get(player, "core.health")

    if not actor or not caster_pos or not player_pos or not caster_health or
        not player_health or caster_health.current <= 0 or
        player_health.current <= 0 or
        caster_pos.level_id ~= player_pos.level_id then
        error("monster cannot cast on distant or dead player")
    end

    local definition = catalog.get("monsters", actor.kind_id)
    catalog.get("spells", intent.spell_id)
    local book = spellbooks[definition.spellbook_id]

    if not book or #book.slots ~= 1 or
        book.slots[1].spell_id ~= intent.spell_id then
        error(actor.kind_id .. " has invalid spell book")
    end

    local effect = effects.effect(intent.spell_id)

    if not effect.can_cast(ctx, caster_pos, player_pos) then
        error(actor.kind_id .. " cannot cast " .. intent.spell_id ..
            " at the player")
    end

    effect.resolve(ctx, caster, player, definition, player_health)
end

register.system({
    id = "attack.spell",
    scope = "active",
    query = {},
    after = { "world.doors" },
    before = { "world.movement" },
    update = system.update,
})

return system
