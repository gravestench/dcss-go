local spells = require("ids.spells")
local component = require("constants.component")
local catalog = require("policy.catalog")
local sphere = require("policy.magic.effects.summons.battlesphere")
local intents = require("constants.intent")
local schools = require("constants.spell_schools")

-- Check spell schools before mirroring; a successful non-conjuration cast must leave the sphere idle.
local function conjuration(spell)
    if spell.id == spells.SPELL_BATTLESPHERE or
        spell.id == spells.SPELL_SPELLFORGED_SERVITOR then
        return false
    end

    for _, school in ipairs(spell.schools or {}) do
        if school == schools.CONJURATION then
            return true
        end
    end

    return false
end

-- Player and monster spell systems signal only completed casts. Source:
-- spl-summoning.cc:battlesphere_can_mirror and trigger_battlesphere.
-- Theory of operation: A successful conjuration signal triggers the sphere before movement changes its line of fire.
local system = {}

-- Consume the player_spell_success signal before the next phase.

-- A battlesphere reacts to its owner's conjuration after the cast and before
-- movement. The active actor must be the one named by the cast signal.
function system.update(ctx, entity)
    local success = entity == ctx:player() and
        #ctx:signals("player_spell_success") > 0

    for _, caster in ipairs(ctx:signals("monster_spell_success")) do
        if caster == entity then
            success = true
        end
    end

    if not success then
        return
    end

    local intent = ctx:get(entity, component.INTENT)

    if intent and (intent.kind == intents.PLAYER_SPELL or
        intent.kind == intents.SPELL) and
        conjuration(catalog.get("spells", intent.spell_id)) then
        sphere.fire(ctx, entity)
    end
end

register.system({
    id = "magic.summon.battlesphere",
    scope = "active",
    query = {},
    after = { "attack.player_spell", "attack.spell" },
    before = { "world.movement" },
    update = system.update,
})

return system
