local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local availability = require("policy.character.skill_availability")
local component = require("constants.component")
local distributed = require("policy.character.distributed_training")

local function initial_skills(origin)
    local skills = {}

    for encoded in origin.initial_skills:gmatch("[^;]+") do
        local id, points = encoded:match("^(SK_[A-Z_]+):(%d+)$")

        if not id then
            error("invalid initial skill record")
        end

        skills[#skills + 1] = {
            id = id,
            points = tonumber(points),
        }
    end

    if #skills == 0 then
        error("missing initial skill record")
    end

    return skills
end

local function validate(ctx)
    local actor = ctx:player()
    local player = ctx:get(actor, component.PLAYER)
    local skills_component = ctx:get(actor, component.SKILLS)
    local training = ctx:get(actor, component.SKILL_TRAINING)
    local progress = ctx:get(actor, component.PROGRESSION)

    if not player or not skills_component or not training or not progress then
        error("player lacks saved training state")
    end

    local species = catalog.get("species", player.species_id)
    local origin = ctx:get(actor, "character.origin")

    if not origin then
        error("player lacks character origin")
    end

    local starting = initial_skills(origin)
    local entries = skills_component.entries
    local available = training.available_xp
    local spent = training.spent_xp

    if available < 0 or spent < 0 or available + spent ~= progress.total_xp * 10 then
        error("player skill experience disagrees with earned XP")
    end

    if training.cost_level ~= formulas.skill_cost_level(spent) then
        error("invalid player skill cost level " .. training.cost_level)
    end

    if #training.recent_practice > 100 or #training.recent_all > 100 then
        error("player skill practice history exceeds 100")
    end

    local starting_points = {}

    for _, skill in ipairs(starting) do
        starting_points[skill.id] = skill.points
    end

    local seen = {}
    local by_id = {}
    local gained = 0

    for index, skill in ipairs(entries) do
        local declared = species.aptitudes[skill.id]
        local allowed = declared and declared.allowed
        local forbidden = availability.forbidden_skill(ctx, actor,
            skill.id)

        if not allowed or seen[skill.id] then
            error("invalid player skill " .. tostring(skill.id))
        end

        local aptitude = formulas.effective_skill_aptitude(ctx, actor,
            species, skill.id)
        local minimum = forbidden and 0 or
            (starting_points[skill.id] or 0)

        if skill.points < minimum or
            skill.points > formulas.skill_points_needed(27, aptitude) or
            (forbidden and skill.points ~= 0) then
            error("invalid player skill " .. tostring(skill.id))
        end

        if index <= #starting and skill.id ~= starting[index].id then
            error("starting player skill order changed at " .. (index - 1))
        end

        if skill.level ~= formulas.skill_level(skill.points, aptitude) then
            error("invalid player skill level for " .. skill.id)
        end

        seen[skill.id] = true
        by_id[skill.id] = skill
        gained = gained + skill.points - (starting_points[skill.id] or 0)
    end

    if gained > spent then
        error("player skill points exceed spent skill experience")
    end

    for _, skill in ipairs(starting) do
        if not seen[skill.id] then
            error("missing starting skill " .. skill.id)
        end
    end

    local settings = {}

    for _, setting in ipairs(training.settings) do
        if not seen[setting.id] or settings[setting.id] or
            (setting.focused and not setting.enabled) then
            error("invalid player skill training setting " .. tostring(setting.id))
        end

        settings[setting.id] = true
    end

    if distributed.active(ctx, actor) then
        if not training.manual then
            error("distributed training cannot be automatic")
        end

        for _, setting in ipairs(training.settings) do
            if setting.focused or
                (by_id[setting.id].level < 27 and not setting.enabled) then
                error("invalid distributed training setting " .. setting.id)
            end
        end

        local expected = {}
        distributed.include_skills(expected, species)

        for _, skill in ipairs(expected) do
            if not seen[skill.id] then
                error("distributed training lacks skill " .. skill.id)
            end
        end
    end

    if #training.settings ~= #entries then
        error("player skills lack training settings")
    end

    for _, queue in ipairs({ training.recent_practice, training.recent_all }) do
        for _, id in ipairs(queue) do
            local aptitude = species.aptitudes[id]

            if not aptitude or not aptitude.allowed then
                error("unknown recent skill " .. tostring(id))
            end
        end
    end
end

local module = {}

function module.run(ctx)
    validate(ctx)
    return {}
end

register.policy({
    id = "save.validate_training",
    run = module.run,
})

return module
