local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local start = require("policy.character.start")
local training_rules = require("policy.character.training")

local function validate(ctx)
    local actor = ctx:player()
    local player = ctx:get(actor, "core.player")
    local skills_component = ctx:get(actor, "core.skills")
    local training = ctx:get(actor, "core.skill_training")
    local progress = ctx:get(actor, "core.progression")

    if not player or not skills_component or not training or not progress then
        error("player lacks saved training state")
    end

    local species = catalog.get("species", player.species_id)
    local job = catalog.get("jobs", player.job_id)
    local starting = start.starting_skills(species, job, player.starting_weapon_id)
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
    local gained = 0

    for index, skill in ipairs(entries) do
        local aptitude = species.aptitudes[skill.id]
        local allowed = training_rules.supported[skill.id] and aptitude and aptitude.allowed

        if not allowed or seen[skill.id] or
            skill.points < (starting_points[skill.id] or 0) or
            skill.points > formulas.skill_points_needed(27, aptitude.value) then
            error("invalid player skill " .. tostring(skill.id))
        end

        if index <= #starting and skill.id ~= starting[index].id then
            error("starting player skill order changed at " .. (index - 1))
        end

        if skill.level ~= formulas.skill_level(skill.points, aptitude.value) then
            error("invalid player skill level for " .. skill.id)
        end

        seen[skill.id] = true
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

    if #training.settings ~= #entries then
        error("player skills lack training settings")
    end

    for _, queue in ipairs({ training.recent_practice, training.recent_all }) do
        for _, id in ipairs(queue) do
            local aptitude = species.aptitudes[id]

            if not training_rules.supported[id] or not aptitude or not aptitude.allowed then
                error("unknown recent skill " .. tostring(id))
            end
        end
    end
end

register.policy({
    id = "save.validate_training",
    run = function(ctx)
        validate(ctx)
        return {}
    end,
})
