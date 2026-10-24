-- Direct constriction and engulf share actor::can_engulf's body rules.
-- Contact handlers own their separate chance, capacity, and saved status.
local catalog = require("policy.catalog")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local form_ids = require("constants.form_ids")
local monsters = require("ids.monsters")
local mutations = require("ids.mutations")
local size = require("constants.size")
local player_confusion = require("policy.magic.player_confusion")
local forms = require("policy.magic.effects.forms.player")
local mutation_levels = require("policy.mutations.levels")
local monster_profile = require("policy.combat.monster_profile")
local invisibility = require("policy.potions.invisibility")
local vision = require("policy.character.vision")

local eligibility = {}

-- Catalog flags are lists; a missing list means the body has no such trait.
local function has_flag(values, wanted)
    for _, value in ipairs(values or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Compare the current transformed player body with a monster's projected
-- body. A polymorphed monster is not necessarily its catalog species.
local function body(ctx, entity)
    if ctx:has(entity, component.PLAYER) then
        local choice = ctx:get(entity, component.PLAYER)
        local species = catalog.get("species", choice.species_id)
        local base = catalog.get("monsters", species.monster_id)
        local form_size = forms.modifiers(ctx, entity).size

        return size.rank[form_size] or size.rank[base.size_id]
    end

    local actor = ctx:get(entity, component.ACTOR)

    if not actor then
        return nil
    end

    local base = catalog.get("monsters", actor.kind_id)
    local definition = monster_profile.definition(ctx, entity, base)

    return size.rank[definition.size_id]
end

-- Source res_constrict rejects spiny, insubstantial, and jelly bodies.
-- Player transformations supply their own current body rather than the
-- species profile's ordinary monster flags.
local function immune(ctx, victim)
    if ctx:has(victim, component.PLAYER) then
        local form = ctx:get(victim, component.PLAYER_FORM)

        return mutation_levels.effective(ctx, victim,
                mutations.MUT_SPINY) > 0 or
            form and (form.form_id == form_ids.WISP or
                form.form_id == form_ids.STORM)
    end

    local actor = ctx:get(victim, component.ACTOR)

    if not actor then
        return true
    end

    local base = catalog.get("monsters", actor.kind_id)
    local definition = monster_profile.definition(ctx, victim, base)

    return definition.genus_id == monsters.MONS_JELLY or
        has_flag(definition.flags, flags.INSUBSTANTIAL) or
        has_flag(definition.flags, flags.SPINY)
end

-- The confused source cannot coordinate a grip, even when its contact
-- would otherwise hit. The player's confusion uses a different status.
local function confused(ctx, attacker)
    if ctx:has(attacker, component.PLAYER) then
        return player_confusion.active(ctx, attacker)
    end

    local status = ctx:get(attacker, component.MONSTER_CONFUSION)

    return status and status.remaining_aut > 0
end

-- Source actor::can_engulf requires same-level adjacency, visibility,
-- enough body size, and a body that can physically be held.
function eligibility.can_engulf(ctx, attacker, victim)
    local source = ctx:get(attacker, component.POSITION)
    local target = ctx:get(victim, component.POSITION)
    local source_health = ctx:get(attacker, component.HEALTH)
    local target_health = ctx:get(victim, component.HEALTH)

    if not source or not target or not source_health or
        source_health.current <= 0 or not target_health or
        target_health.current <= 0 or
        source.level_id ~= target.level_id or
        math.max(math.abs(source.x - target.x),
            math.abs(source.y - target.y)) ~= 1 or
        confused(ctx, attacker) or immune(ctx, victim) or
        (ctx:has(victim, component.PLAYER) and
            not invisibility.visible_to(ctx, victim, attacker)) then
        return false
    end

    local source_size = body(ctx, attacker)
    local target_size = body(ctx, victim)

    if not source_size or not target_size or
        source_size < target_size then
        return false
    end

    local radius = ctx:has(attacker, component.PLAYER) and
        vision.radius(ctx, attacker) or 7

    return ctx:visible(source.level_id, source.x, source.y,
        radius, target.x, target.y)
end

return eligibility
