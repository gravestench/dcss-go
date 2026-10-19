-- Ghostly Sacrifice plans a live allied donor rather than aiming at a foe.
-- The donor dies first; its cell then becomes the center of a direct blast.
-- Source: mon-cast.cc:_mons_ghostly_sacrifice_target.
local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local decision = require("policy.combat.monster_area.decision")
local display = require("policy.combat.monster_support.display")
local beam_damage = require("policy.combat.monster_beams.damage")
local draining = require("policy.combat.monster_beams.draining")
local flags = require("constants.monster_flags")
local spells = require("ids.spells")
local target_kind = require("constants.target_kind")
local targets = require("policy.ai.targets")
local actors = require("policy.combat.monster_area.actors")

local effect = {}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_GHOSTLY_SACRIFICE)

-- Estimate the same negative-energy resistance that blast contact uses.
-- A fully immune target contributes no foe power to a proposed sacrifice.
local function impact(ctx, victim)
    return beam_damage.resisted(ctx, victim, 100, profile) / 100
end

-- Source class flags identify both unfit projectile donors and harmless
-- donors whose loss carries no extra experience-weighted sacrifice cost.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- The source tracer counts the donor as friendly blast power, then adds
-- twice its experience level as an explicit sacrifice cost.
local function score(ctx, caster, donor, position, definition)
    local victims = actors.blast(ctx, position.level_id,
        position.x, position.y, profile.explosion_radius)
    local foes, friends = decision.weights(ctx, caster,
        victims, impact)

    if not has_flag(definition, flags.NO_THREAT) then
        friends = friends + definition.hd * 2
    end

    return foes, foes + friends
end

-- Choose the best foe-damage fraction above one half, breaking ties in
-- stable actor order so file load order never changes a seeded game.
function effect.plan(ctx, caster)
    local origin = ctx:get(caster, component.POSITION)

    if not origin then
        return nil
    end

    local best = nil
    local best_foes = 1
    local best_total = 2

    for _, donor in ipairs(actors.los(ctx, caster, 7)) do
        if targets.aligned(ctx, caster, donor) then
            local actor = ctx:get(donor, component.ACTOR)
            local definition = catalog.get(categories.MONSTERS,
                actor.kind_id)

            if not has_flag(definition, flags.PROJECTILE) then
                local position = ctx:get(donor, component.POSITION)
                local foes, total = score(ctx, caster, donor,
                    position, definition)

                if total > 0 and
                    foes * best_total > best_foes * total then
                    best = donor
                    best_foes = foes
                    best_total = total
                end
            end
        end
    end

    if not best then
        return nil
    end

    local position = ctx:get(best, component.POSITION)

    return {
        kind = target_kind.CELL,
        entity = best,
        level_id = position.level_id,
        x = position.x,
        y = position.y,
        dx = position.x - origin.x,
        dy = position.y - origin.y,
    }
end

-- A stale plan cannot sacrifice a different actor after movement or death.
-- The ordinary death phase handles the corpse after the blast has fired.
function effect.resolve(ctx, caster, _, _, plan)
    local donor = plan and plan.entity
    local position = donor and ctx:get(donor, component.POSITION)
    local health = donor and ctx:get(donor, component.HEALTH)
    local origin = ctx:get(caster, component.POSITION)

    if not plan or plan.kind ~= target_kind.CELL or
        not position or not health or health.current <= 0 or
        not origin or position.level_id ~= origin.level_id or
        position.level_id ~= plan.level_id or
        position.x ~= plan.x or position.y ~= plan.y or
        not targets.aligned(ctx, caster, donor) then
        error("Ghostly Sacrifice lost its planned ally")
    end

    ctx:emit(channels.SPELL,
        "The " .. display.name(ctx, donor) ..
            "'s animating energy erupts into ghostly fire!")
    -- monster_die is unconditional in source. Ordinary damage can be split
    -- by Injury Bond or reduced by petrification and must not be used here.
    health.current = 0
    ctx:set(donor, component.HEALTH, health)

    return beam.resolve(ctx, caster, nil, profile, plan, draining)
end

return effect
