local catalog = require("policy.catalog")
local effects = require("policy.combat.monster_spells")
local spellbook = require("policy.combat.monster_spellbook")
local target = require("policy.combat.monster_spell_target")
local targets = require("policy.ai.targets")
local intents = require("constants.intent")
local hex_status = require("policy.combat.monster_hexes.status")
local enfeeble = require("policy.magic.effects.statuses.enfeeble")
local spell_flags = require("constants.monster_spell_flags")
local component = require("constants.component")

local system = {}

-- Theory of operation: A spellbook slot and saved foe identify an ordinary
-- monster cast. Constructs use the same intent number without a book slot;
-- their own system resolves those abilities. Casts resolve before movement
-- can change the selected target.
function system.update(ctx, caster)
    local intent = ctx:get(caster, "core.intent")

    if not intent or intent.kind ~= intents.SPELL then
        return
    end

    -- Construct abilities resolve in their own Lua decision policy.
    -- Allegiance does not change that ownership: hostile Marshlight
    -- foxfire also has no spellbook slot, yet spends spell-speed energy.
    if (not intent.spell_slot or intent.spell_slot == 0) and
        ctx:has(caster, component.SUMMON) then
        return
    end

    local foe = intent.foe_entity
    local actor = ctx:get(caster, "core.actor")
    local caster_pos = ctx:get(caster, "core.position")
    local foe_pos = foe and ctx:get(foe, "core.position")
    local caster_health = ctx:get(caster, "core.health")
    local foe_health = foe and ctx:get(foe, "core.health")

    if not actor or not caster_pos or not foe_pos or not caster_health or
        not foe_health or caster_health.current <= 0 or
        foe_health.current <= 0 or
        caster_pos.level_id ~= foe_pos.level_id or
        not targets.enemy(ctx, caster, foe) then
        error("monster cannot cast on distant, dead, or allied foe")
    end

    catalog.get("spells", intent.spell_id)
    local book = spellbook.for_actor(ctx, caster)

    local slot = spellbook.slot(book, intent.spell_slot, intent.spell_id)

    local effect = effects.effect(intent.spell_id)
    local plan = target.read(intent)

    effect.resolve(ctx, caster, foe, slot, plan)

    -- A successful monster conjuration may queue its own battlesphere.
    -- Keep the event tied to completed book casts, never construct abilities.
    ctx:signal("monster_spell_success", caster)

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
