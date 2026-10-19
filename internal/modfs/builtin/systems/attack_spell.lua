local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local spellbook = require("policy.combat.monster_spellbook")
local target = require("policy.combat.monster_spell_target")
local targets = require("policy.ai.targets")
local intents = require("constants.intent")
local hex_status = require("policy.combat.monster_hexes.status")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local spell_flags = require("constants.monster_spell_flags")

local system = {}

-- Theory of operation: The spell intent gate leaves allied constructs to their own decision system while spending spell
-- energy.
-- Monster spell intent is resolved before movement can change a chosen spell target.
function system.update(ctx, caster)
    local intent = ctx:get(caster, "core.intent")

    if not intent or intent.kind ~= intents.SPELL then
        return
    end

    -- Construct abilities resolve in their own Lua decision policy.
    -- They retain spell-speed energy without using a monster spellbook.
    if ctx:has(caster, "magic.summon") and
        targets.allied(ctx, caster) then
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

    catalog.get("spells", intent.spell_id)
    local book = spellbook.for_actor(ctx, caster)

    local slot = spellbook.slot(book, intent.spell_slot, intent.spell_id)

    local effect = effects.effect(intent.spell_id)
    local plan = target.read(intent)

    effect.resolve(ctx, caster, player, slot, plan)

    if hex_status.sapped(ctx, caster) then
        for _, flag in ipairs(slot.flags or {}) do
            if flag == spell_flags.WIZARD then
                enfeeble.apply_sap_antimagic(ctx, caster)

                break
            end
        end
    end
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
