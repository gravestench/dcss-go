-- Example: A sacrificed skill is removed from training before XP is apportioned.
local capabilities = require("constants.mutation_capabilities")
local component = require("constants.component")
local effects = require("policy.mutations.effects.registry")
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local forms = require("policy.magic.effects.forms.player")
local rage = require("policy.character.rage")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")

local availability = {}

-- Query mutation restrictions by skill ID before spending or preserving points.
function availability.forbidden_skill(ctx, player, skill_id)
    return effects.sum(ctx, player,
        capabilities.SKILL_FORBIDDEN, skill_id) > 0
end

-- Species and mutation restrictions also apply before a learned spell can be cast.
function availability.forbidden_spell(ctx, player, spell)
    if effects.sum(ctx, player,
        capabilities.SPELL_ID_FORBIDDEN, spell.id) > 0 then
        return true
    end

    for _, school in ipairs(spell.schools or {}) do
        if effects.sum(ctx, player,
            capabilities.SPELL_SCHOOL_FORBIDDEN, school) > 0 then
            return true
        end
    end

    return false
end

-- Source: skills.cc:fixup_skills discards points in a newly useless skill
-- and disables its training. A later mutation loss does not restore them.
-- Drop now-invalid points and training settings when a skill becomes permanently unusable.
function availability.sanitize(ctx, player)
    local skills = ctx:get(player, component.SKILLS)
    local training = ctx:get(player, component.SKILL_TRAINING)

    if not skills or not training then
        return
    end

    local changed_skills = false
    local changed_training = false

    for _, skill in ipairs(skills.entries) do
        if availability.forbidden_skill(ctx, player, skill.id) then
            if skill.level ~= 0 or skill.points ~= 0 then
                skill.level = 0
                skill.points = 0
                changed_skills = true
            end
        end
    end

    local distributed = mutation_levels.effective(ctx, player,
        mutations.MUT_DISTRIBUTED_TRAINING) > 0

    for _, setting in ipairs(training.settings) do
        if not distributed and
            availability.forbidden_skill(ctx, player, setting.id) and
            (setting.enabled or setting.focused) then
            setting.enabled = false
            setting.focused = false
            changed_training = true
        end
    end

    if changed_skills then
        ctx:set(player, component.SKILLS, skills)
    end

    if changed_training then
        ctx:set(player, component.SKILL_TRAINING, training)
    end
end

-- Source: Ru's Sacrifice Skill rechecks every skill against the new
-- aptitude, then recalculates derived HP and MP from those skill levels.
-- After species or mutation changes, disable newly forbidden training and clear stale skill points.
function availability.reassess(ctx, player)
    local identity = ctx:get(player, component.PLAYER)
    local skills = ctx:get(player, component.SKILLS)
    local progress = ctx:get(player, component.PROGRESSION)
    local health = ctx:get(player, component.HEALTH)
    local regeneration = ctx:get(player, component.REGENERATION)
    local magic = ctx:get(player, component.MAGIC)

    if not identity or not skills or not progress or not health or
        not regeneration or not magic then
        error("player lacks state for skill aptitude reassessment")
    end

    local species = catalog.get("species", identity.species_id)

    for _, skill in ipairs(skills.entries) do
        local aptitude = formulas.effective_skill_aptitude(ctx, player,
            species, skill.id)
        local maximum = formulas.skill_points_needed(27, aptitude)

        skill.points = math.min(skill.points, maximum)
        skill.level = formulas.skill_level(skill.points, aptitude)
    end

    ctx:set(player, component.SKILLS, skills)

    local drain = ctx:get(player, "status.drain")
    local drain_loss = drain and drain.amount or 0
    local base_hp = math.max(1, formulas.max_hp(ctx, player,
        progress.level, species, skills.entries) - drain_loss)

    formulas.rescale_health(health, regeneration,
        rage.scale_hp(ctx, player,
            forms.scale_hp(ctx, player, base_hp)))
    ctx:set(player, component.HEALTH, health)
    ctx:set(player, component.REGENERATION, regeneration)

    magic.max = formulas.max_mp(ctx, player, progress.level,
        species, skills.entries)
    magic.current = math.min(magic.current, magic.max)
    ctx:set(player, component.MAGIC, magic)
end

return availability
