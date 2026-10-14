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

local function aptitude_factor(aptitude)
    return float32(1 / math.exp(math.log(2) * aptitude / 4))
end

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

function formulas.experience_needed(level, xp_aptitude)
    if level < 1 or level > 27 then
        error("experience level " .. level .. " is outside 1..27")
    end

    local factor = aptitude_factor(xp_aptitude - 1)

    if factor <= 0 or float32(9 * factor) < 1 then
        error("experience aptitude " .. xp_aptitude .. " has invalid thresholds")
    end

    return math.floor(float32((historical_experience(level) - 1) * factor))
end

function formulas.level_for_experience(total_xp, xp_aptitude)
    if total_xp < 0 then
        error("negative experience " .. total_xp)
    end

    local level = 1

    while level < 27 and total_xp >= formulas.experience_needed(level + 1, xp_aptitude) do
        level = level + 1
    end

    return level
end

function formulas.level_progress(total_xp, level, xp_aptitude)
    local current = formulas.experience_needed(level, xp_aptitude)

    if total_xp < current then
        error("XL" .. level .. " needs at least " .. current .. " experience")
    end

    if level == 27 then
        return 0
    end

    local next_xp = formulas.experience_needed(level + 1, xp_aptitude)

    return math.floor((total_xp - current) * 100 / (next_xp - current))
end

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

function formulas.skill_point_cost(level)
    if level < 1 or level > 27 then
        error("skill cost level " .. level .. " is outside 1..27")
    end

    return point_costs[level]
end

function formulas.skill_aptitude(species, id)
    local aptitude = species.aptitudes[id]

    if not aptitude or not aptitude.allowed then
        error(species.id .. " cannot train " .. id)
    end

    return aptitude.value
end

function formulas.max_hp(level, species, skills)
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

    if not fighting then
        error(species.id .. " lacks Fighting skill")
    end

    local aptitude = formulas.skill_aptitude(species, "SK_FIGHTING")
    local fighting5 = formulas.scaled_skill(fighting, 5, aptitude)
    local fighting3 = formulas.scaled_skill(fighting, 3, aptitude)
    local hp = math.floor(level * 11 / 2) + 8
    hp = hp + math.floor(level * fighting5 / 70) + math.floor((fighting3 + 1) / 2)

    return math.max(1, math.floor(hp * (10 + species.hp) / 10))
end

function formulas.max_mp(level, species)
    if level < 1 or level > 27 then
        error("unsupported baseline MP inputs at XL" .. level .. " for " .. species.id)
    end

    return math.max(0, math.min(23, level) + species.mp_mod)
end

function formulas.needs_manual_stat(level)
    return level >= 3 and level <= 27 and level % 6 == 3
end

function formulas.rescale_health(health, regeneration, next_max)
    local hundredths = math.floor(
        (health.current * 100 + regeneration.hp_progress) * next_max / health.max)
    hundredths = math.max(100, hundredths)
    health.max = next_max
    health.current = math.min(next_max, math.floor(hundredths / 100))
    regeneration.hp_progress = hundredths % 100
end

return formulas
