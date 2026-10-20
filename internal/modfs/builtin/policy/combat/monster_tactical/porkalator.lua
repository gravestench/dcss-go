local attitudes = require("constants.attitude")
local component = require("constants.component")
local death_hooks = require("policy.combat.death_hooks")
local hit_points = require("policy.population.hit_points")
local monsters = require("ids.monsters")
local catalog = require("policy.catalog")
local targets = require("policy.ai.targets")
local tactical = require("constants.monster_tactical")
local forms = require("policy.magic.effects.forms.player")
local form_ids = require("constants.form_ids")

local pork = {}

-- Save the whole original identity before fixed-form polymorph replaces it.
-- The separate Kirke-band marker identifies naturally spawned hogs, which
-- have no previous body and will need a newly generated human HP maximum.
function pork.remember(ctx, target)
    if ctx:has(target, tactical.PORKALATOR_ORIGINAL) then
        return
    end

    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local marker = ctx:get(target, component.MONSTER_POLYMORPH)

    ctx:add(target, tactical.PORKALATOR_ORIGINAL, {
        kind_id = actor.kind_id,
        speed = actor.speed,
        max_hp = health.max,
        polymorph_original_kind_id = marker and
            marker.original_kind_id or "",
    })
end

-- Source mons_is_mons_class also recognizes a unique that was polymorphed
-- before death. The saved original-kind marker lets that death free hogs.
local function was_kirke(ctx, dead, definition)
    if definition.id == monsters.MONS_KIRKE then
        return true
    end

    local form = ctx:get(dead, component.MONSTER_POLYMORPH)

    return form and form.original_kind_id == monsters.MONS_KIRKE
end

-- Only a current hog body is released. A shapeshifter that moved on from
-- hog form keeps its own shape; the stored marker remains harmless to it.
local function is_hog(actor)
    return actor.kind_id == monsters.MONS_HOG or
        actor.kind_id == monsters.MONS_HELL_HOG or
        actor.kind_id == monsters.MONS_HOLY_SWINE
end

-- Store good-neutral independently of vault overrides, whose authored values
-- must remain intact. An already peaceful hog keeps its existing attitude.
local function free_hostile_hog(ctx, target, kind_id, original_kind_id)
    if targets.real_attitude(ctx, target) == attitudes.HOSTILE then
        ctx:add(target, tactical.KIRKE_FREED, {
            freed = true,
            kind_id = kind_id,
            original_kind_id = original_kind_id,
        })
    end
end

-- Rebuild only the body fields Porkalator changed. The actor entity, position,
-- current effects, inventory, and AI remain the same across floor boundaries.
local function restore_body(ctx, target, kind_id, speed, maximum, prior_form)
    local actor = ctx:get(target, component.ACTOR)
    local health = ctx:get(target, component.HEALTH)
    local ratio = health.current / health.max

    actor.kind_id = kind_id
    actor.speed = speed
    health.max = maximum
    health.current = math.max(1, math.floor(ratio * maximum))
    ctx:set(target, component.ACTOR, actor)
    ctx:set(target, component.HEALTH, health)

    if prior_form ~= "" then
        ctx:set(target, component.MONSTER_POLYMORPH, {
            original_kind_id = prior_form,
        })
    else
        ctx:remove(target, component.MONSTER_POLYMORPH)
    end
end

-- The original band hog had no saved prior actor. Source dactions.cc creates
-- a fresh human profile on release, while preserving the hog's injury ratio.
local function restore_band_hog(ctx, target)
    local human = catalog.get("monsters", monsters.MONS_HUMAN)
    local maximum = hit_points.roll(ctx, human.average_hp_10x)

    restore_body(ctx, target, human.id, human.speed, maximum, "")
    ctx:remove(target, component.FOLLOWER)
    ctx:remove(target, component.BAND_ORIGIN)
    ctx:remove(target, tactical.KIRKE_BAND)
end

-- A spelled hog carries its exact earlier kind and HP maximum. No random
-- human is generated for this path, even when the original kind was human.
local function restore_spell_hog(ctx, target, original)
    restore_body(ctx, target, original.kind_id, original.speed,
        original.max_hp, original.polymorph_original_kind_id)
    ctx:remove(target, tactical.PORKALATOR_ORIGINAL)
end

-- Theory of operation: every floor's actors remain in the ECS even while
-- their AI is inactive. Kirke's death visits all of them once, so a hog on an
-- away floor is already restored when that floor is activated or saved.
-- The source queues this as a delayed action because it unloads whole floors.
function pork.restore_on_kirke_death(ctx, dead, definition)
    if not was_kirke(ctx, dead, definition) then
        return false
    end

    for _, target in ipairs(ctx:query({
        component.ACTOR,
        component.HEALTH,
    })) do
        local actor = ctx:get(target, component.ACTOR)
        local health = ctx:get(target, component.HEALTH)

        if target ~= dead and health.current > 0 and is_hog(actor) then
            local original = ctx:get(target, tactical.PORKALATOR_ORIGINAL)
            local band = ctx:get(target, tactical.KIRKE_BAND)

            if original or band then
                if original then
                    local base = original.polymorph_original_kind_id

                    if base == "" then
                        base = original.kind_id
                    end

                    free_hostile_hog(ctx, target, original.kind_id, base)
                    restore_spell_hog(ctx, target, original)
                else
                    free_hostile_hog(ctx, target,
                        monsters.MONS_HUMAN, monsters.MONS_HUMAN)
                    restore_band_hog(ctx, target)
                end
            end
        end
    end

    -- fineff.cc reverts the player only after releasing monster hogs. This
    -- forcibly ends Pig Form even though the hex made it uncancellable.
    local player = ctx:player()
    local player_form = player and ctx:get(player, component.PLAYER_FORM)

    if player_form and player_form.form_id == form_ids.PIG then
        forms.finish(ctx, player)
    end

    return false
end

death_hooks.add("porkalator.kirke", pork.restore_on_kirke_death)

return pork
