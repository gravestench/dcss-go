-- Bind Souls marks nearby allied natural monsters. A death hook, rather
-- than the spell cast, consumes the corpse and creates the derived undead.
-- This keeps expiry, save/restore, and ordinary monster death in one flow.
local attacks = require("constants.monster_attack_types")
local catalog = require("policy.catalog")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local flags = require("constants.monster_flags")
local holiness = require("constants.monster_holiness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local actors = require("policy.combat.monster_area.actors")
local targets = require("policy.ai.targets")
local necromancy = require("policy.magic.effects.summons.necromancy")
local streams = require("constants.rng_streams")

local bound_souls = {}

-- Source flag and holiness lists are catalogs, so inspect them without
-- assuming import order or a fixed list position.
local function contains(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source mons_can_be_zombified excludes summoned or insubstantial bodies
-- and creatures with no real attack. Natural holiness itself satisfies the
-- source class rule even when the monster leaves no ordinary corpse.
function bound_souls.eligible(ctx, caster, target)
    if target == caster or
        ctx:has(target, component.SUMMON) or
        ctx:has(target, component.MONSTER_BOUND_SOUL) or
        not targets.aligned(ctx, caster, target) then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)
    local definition = actor and catalog.get("monsters", actor.kind_id)

    if not definition or
        not contains(definition.holiness, holiness.NATURAL) or
        contains(definition.flags, flags.NO_ZOMBIE) or
        contains(definition.flags, flags.INSUBSTANTIAL) then
        return false
    end

    for _, attack in ipairs(definition.attacks or {}) do
        if attack.type_id ~= attacks.NONE then
            return true
        end
    end

    return false
end

-- A cast is useful only when at least one visible ally can receive a mark.
function bound_souls.recipients(ctx, caster)
    local recipients = {}

    for _, target in ipairs(actors.los(ctx, caster, 7)) do
        if bound_souls.eligible(ctx, caster, target) then
            recipients[#recipients + 1] = target
        end
    end

    return recipients
end

-- Source mon-cast.cc uses one inclusive 10–30 turn roll per eligible ally.
-- A later cast leaves already marked actors alone until expiry or death.
function bound_souls.mark(ctx, caster, recipients)
    for _, target in ipairs(recipients) do
        local turns = 10 + ctx:random(streams.MONSTER_SPELL, 21)

        ctx:add(target, component.MONSTER_BOUND_SOUL, {
            caster_id = ctx:id(caster),
            expires_aut = ctx:aut() + turns * 10,
        })
    end
end

-- The source death branch takes precedence over player necromancy effects.
-- Derived undead outlive a monster caster. The player handle is an inert
-- permanent storage owner; the victim's live attitude controls allegiance.
function bound_souls.death_hook(ctx, monster, definition, position,
    _, consumed_corpse)
    local mark = ctx:get(monster, component.MONSTER_BOUND_SOUL)

    if not mark or consumed_corpse or mark.expires_aut <= ctx:aut() then
        return false
    end

    local raised = necromancy.raise(ctx, ctx:player(),
        spells.SPELL_BIND_SOULS, monsters.MONS_SIMULACRUM,
        definition.id, position, targets.real_attitude(ctx, monster))

    return raised ~= nil
end

death_hooks.add("combat.bound_soul", bound_souls.death_hook)

return bound_souls
