local catalog = require("policy.catalog")
local fighter = require("policy.combat.fighter")
local spells = require("policy.combat.spells")

local spellbooks = {}

for _, book in ipairs(require("data.monster_spellbooks").books) do
    spellbooks[book.id] = book
end

local function adjacent(a, b)
    return a.level_id == b.level_id and
        math.abs(a.x - b.x) <= 1 and math.abs(a.y - b.y) <= 1 and
        (a.x ~= b.x or a.y ~= b.y)
end

register.system({
    id = "attack.spell",
    scope = "active",
    query = {},
    after = { "world.doors" },
    before = { "world.movement" },
    update = function(ctx, caster)
        local intent = ctx:get(caster, "core.intent")

        if not intent or intent.kind ~= 12 then
            return
        end

        local player = ctx:player()
        local actor = ctx:get(caster, "core.actor")
        local caster_pos = ctx:get(caster, "core.position")
        local player_pos = ctx:get(player, "core.position")
        local caster_health = ctx:get(caster, "core.health")
        local player_health = ctx:get(player, "core.health")

        if not actor or not caster_pos or not player_pos or not caster_health or
            not player_health or caster_health.current <= 0 or player_health.current <= 0 or
            caster_pos.level_id ~= player_pos.level_id then
            error("monster cannot cast on distant or dead player")
        end

        local definition = catalog.get("monsters", actor.kind_id)
        catalog.get("spells", intent.spell_id)
        local book = spellbooks[definition.spellbook_id]

        if not book or #book.slots ~= 1 or book.slots[1].spell_id ~= intent.spell_id then
            error(actor.kind_id .. " has invalid spell book")
        end

        if actor.kind_id == "MONS_ENDOPLASM" and intent.spell_id == "SPELL_FREEZE" then
            if not adjacent(caster_pos, player_pos) then
                error("endoplasm cannot Freeze distant player")
            end

            local damage = spells.freeze(ctx, definition.hd)
            player_health.current = math.max(0, player_health.current - damage)
            ctx:set(player, "core.health", player_health)
            ctx:emit("combat", "You are frozen.")

            return
        end

        if actor.kind_id == "MONS_DART_SLUG" and intent.spell_id == "SPELL_SLUG_DART" then
            if not ctx:projectile_clear(caster_pos.level_id, caster_pos.x, caster_pos.y,
                player_pos.x, player_pos.y) then
                error("dart slug has no clear shot")
            end

            local defense = fighter.defense(ctx)
            local outcome = spells.slug_dart(ctx, definition.hd, defense)
            local combat = ctx:get(player, "core.combat")

            if not combat then
                error("player has no combat state")
            end

            combat.shield_blocks = outcome.shield_blocks
            player_health.current = math.max(0, player_health.current - outcome.damage)
            ctx:set(player, "core.combat", combat)
            ctx:set(player, "core.health", player_health)

            local message = "The slug dart misses you."

            if outcome.kind == "block" then
                message = "You block the slug dart."
            elseif outcome.kind == "hit" then
                message = "The slug dart hits you for " .. outcome.damage .. " damage."
            end

            ctx:emit("combat", message)

            return
        end

        error("unsupported monster spell " .. intent.spell_id)
    end,
})
