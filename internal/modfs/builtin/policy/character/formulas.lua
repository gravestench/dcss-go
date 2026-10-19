-- Example: A skill aptitude changes the rounded point cost at the next skill level.
local mutation_effects = require("policy.mutations.effects.registry")
local mutation_capabilities = require("constants.mutation_capabilities")
local jewellery_capabilities = require("constants.jewellery_capabilities")

local formulas = {}

formulas.max_level = 27

-- The source rounds the aptitude factor and its product to IEEE float32
-- before truncating. Keep that behavior in Lua's double-number runtime.
local function float32(value)
    if value == 0 then
        return 0
    end

    local exponent = math.floor(math.log(value) / math.log(2))
    local power = 2 ^ exponent

    if value < power then
        exponent = exponent - 1
    elseif value >= power * 2 then
        exponent = exponent + 1
    end

    local quantum = 2 ^ (exponent - 23)
    local units = value / quantum
    local lower = math.floor(units)
    local fraction = units - lower

    if fraction > 0.5 or (fraction == 0.5 and lower % 2 == 1) then
        lower = lower + 1
    end

    return lower * quantum
end

-- Round the source exponential aptitude factor to float32 before skill-point arithmetic.
local function aptitude_factor(aptitude)
    return float32(1 / math.exp(math.log(2) * aptitude / 4))
end

-- The breakpoint terms reproduce the nonuniform DCSS point curve.
local function historical_skill_cost(level)
    local points = 25 * level * (level + 1)

    for _, breakpoint in ipairs({ 9, 18, 26 }) do
        if level > breakpoint then
            local offset = level - breakpoint
            points = points + 25 * offset * (offset + 1) / 2
        end
    end

    return points
end

-- Apply the historical point curve and aptitude multiplier only for valid skill levels.
function formulas.skill_points_needed(level, aptitude)
    if level < 0 or level > 27 then
        error("skill level " .. level .. " is outside 0..27")
    end

    local factor = aptitude_factor(aptitude)

    if factor <= 0 or float32(50 * factor) < 1 then
        error("skill aptitude " .. aptitude .. " has invalid thresholds")
    end

    return math.floor(float32(historical_skill_cost(level) * factor))
end

-- Locate the attained level from accumulated points under the species aptitude.
function formulas.skill_level(points, aptitude)
    if points < 0 then
        error("negative skill points " .. points)
    end

    formulas.skill_points_needed(1, aptitude)

    for level = 27, 1, -1 do
        if points >= formulas.skill_points_needed(level, aptitude) then
            return level
        end
    end

    return 0
end

-- Include progress to the next level when a derived formula asks for fractional skill.
function formulas.scaled_skill(skill, scale, aptitude)
    formulas.skill_points_needed(1, aptitude)

    if skill.level == 27 then
        return 27 * scale
    end

    local previous = formulas.skill_points_needed(skill.level, aptitude)
    local next_points = formulas.skill_points_needed(skill.level + 1, aptitude)

    return skill.level * scale +
        math.floor((skill.points - previous) * scale / (next_points - previous))
end

-- Level XP thresholds change slope at the source game breakpoints.
local function historical_experience(level)
    if level == 1 then
        return 1
    elseif level == 2 then
        return 10
    elseif level == 3 then
        return 30
    elseif level == 4 then
        return 70
    elseif level < 13 then
        local offset = level - 4

        return 10 + 10 * offset + 60 * 2 ^ offset
    end

    local offset = level - 12

    return 16675 + 5985 * offset + 4235 * offset * offset
end

-- Scale the source level threshold by species XP aptitude after validating its range.
function formulas.experience_needed(level, xp_aptitude)
    if level < 1 or level > 128 then
        error("experience level " .. level .. " is outside 1..128")
    end

    local factor = aptitude_factor(xp_aptitude - 1)

    if factor <= 0 or float32(9 * factor) < 1 then
        error("experience aptitude " .. xp_aptitude .. " has invalid thresholds")
    end

    return math.floor(float32((historical_experience(level) - 1) * factor))
end

-- Walk thresholds only up to the current cap so surplus XP does not create an illegal level.
function formulas.level_for_experience(total_xp, xp_aptitude, maximum)
    if total_xp < 0 then
        error("negative experience " .. total_xp)
    end

    local level = 1

    maximum = maximum or formulas.max_level

    while level < maximum and
        total_xp >= formulas.experience_needed(level + 1, xp_aptitude) do
        level = level + 1
    end

    return level
end

-- Report progress within the current threshold interval, including capped-level behavior.
function formulas.level_progress(total_xp, level, xp_aptitude, maximum)
    local current = formulas.experience_needed(level, xp_aptitude)

    if total_xp < current then
        error("XL" .. level .. " needs at least " .. current .. " experience")
    end

    if level >= (maximum or formulas.max_level) then
        return 0
    end

    local next_xp = formulas.experience_needed(level + 1, xp_aptitude)

    return math.floor((total_xp - current) * 100 / (next_xp - current))
end

-- Map total spent training XP to the current per-point cost bracket.
function formulas.skill_cost_level(spent_xp)
    if spent_xp < 0 then
        error("negative spent skill experience " .. spent_xp)
    end

    local level = 1

    while level < 27 and spent_xp >= 13 * formulas.experience_needed(level + 1, 1) do
        level = level + 1
    end

    return level
end

local point_costs = {
    1, 2, 3, 4, 5, 7, 8, 9, 13, 22, 37, 48, 73, 98,
    125, 145, 170, 190, 212, 225, 240, 255, 260, 265, 265, 265, 265,
}

-- Read the source cost table only after bounding its level index.
function formulas.skill_point_cost(level)
    if level < 1 or level > 27 then
        error("skill cost level " .. level .. " is outside 1..27")
    end

    return point_costs[level]
end

-- Reject unavailable skills before callers try to price their points.
function formulas.skill_aptitude(species, id)
    local aptitude = species.aptitudes[id]

    if not aptitude or not aptitude.allowed then
        error(species.id .. " cannot train " .. id)
    end

    return aptitude.value
end

-- Source: skills.cc:species_apt subtracts Unskilled after the species
-- aptitude lookup. This applies to training, skill progress, and display.
function formulas.effective_skill_aptitude(ctx, player, species, id)
    local aptitude = formulas.skill_aptitude(species, id)
    local penalty = mutation_effects.sum(ctx, player,
        mutation_capabilities.SKILL_APTITUDE_PENALTY)

    return aptitude - penalty
end

-- Fighting contributes through two differently scaled terms before percentage modifiers.
function formulas.max_hp(ctx, player, level, species, skills)
    if level < 1 or level > 27 then
        error("invalid HP level " .. level)
    end

    local fighting

    for _, skill in ipairs(skills) do
        if skill.id == "SK_FIGHTING" then
            fighting = skill
            break
        end
    end

    fighting = fighting or {
        level = 0,
        points = 0,
    }

    local aptitude = formulas.effective_skill_aptitude(ctx, player,
        species, "SK_FIGHTING")
    local fighting5 = formulas.scaled_skill(fighting, 5, aptitude)
    local fighting3 = formulas.scaled_skill(fighting, 3, aptitude)
    local hp = math.floor(level * 11 / 2) + 8
    hp = hp + math.floor(level * fighting5 / 70) + math.floor((fighting3 + 1) / 2)

    hp = math.floor(hp * (10 + species.hp) / 10)

    hp = hp + mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_FLAT)

    local percent = 100 + mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_PERCENT)

    return math.max(1, math.floor(hp * percent / 100))
end

-- Spellcasting and half Invocations compete for the skill contribution before MP bonuses apply.
function formulas.max_mp(ctx, player, level, species, skills)
    if level < 1 or level > 27 then
        error("unsupported baseline MP inputs at XL" .. level .. " for " .. species.id)
    end

    if mutation_effects.sum(ctx, player,
        mutation_capabilities.HP_CASTING) > 0 then
        return 0
    end

    local spellcasting = 0
    local invocations = 0

    for _, skill in ipairs(skills or {}) do
        if skill.id == "SK_SPELLCASTING" then
            local aptitude = formulas.effective_skill_aptitude(ctx, player,
                species, skill.id)
            spellcasting = formulas.scaled_skill(skill, 100, aptitude)
        elseif skill.id == "SK_INVOCATIONS" then
            local aptitude = formulas.effective_skill_aptitude(ctx, player,
                species, skill.id)
            invocations = formulas.scaled_skill(skill, 100, aptitude)
        end
    end

    local highest = math.max(spellcasting, math.floor(invocations / 2))
    local scaled = math.min(2300, level * 100)
    scaled = scaled + highest + math.floor(math.min(800, highest, level * 100) / 2)
    scaled = math.floor(scaled *
        (100 + mutation_effects.sum(ctx, player,
            mutation_capabilities.MP_PERCENT)) / 100)

    local jewellery_effects = require("policy.inventory.jewellery_effects")

    return math.max(0, math.floor(scaled / 100) + species.mp_mod +
        jewellery_effects.sum(ctx, player,
            jewellery_capabilities.MAX_MP))
end

-- Gate manual choices to source level milestones and mutation exceptions.
function formulas.needs_manual_stat(ctx, player, level)
    if level < 3 or level > 27 then
        return false
    end

    if mutation_effects.base_sum(ctx, player,
        mutation_capabilities.DIVINE_ATTRIBUTES) > 0 then
        return level % 3 == 0
    end

    return level % 6 == 3
end

-- Divine Attributes grants a larger choice than the ordinary one-point increase.
function formulas.manual_stat_amount(ctx, player)
    if mutation_effects.base_sum(ctx, player,
        mutation_capabilities.DIVINE_ATTRIBUTES) > 0 then
        return 4
    end

    return 2
end

-- Carry fractional regeneration progress across a maximum-HP change.
function formulas.rescale_health(health, regeneration, next_max)
    local hundredths = math.floor(
        (health.current * 100 + regeneration.hp_progress) * next_max / health.max)
    hundredths = math.max(100, hundredths)
    health.max = next_max
    health.current = math.min(next_max, math.floor(hundredths / 100))
    regeneration.hp_progress = hundredths % 100
end

return formulas
