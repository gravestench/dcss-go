local menu = require("policy.input.menu")

local skills = {}

-- Training changes are routed from the skill screen into the session's pending choice.
-- Example: skills.route({ key = "a", skill_ids = ordered_ids }) requests a
-- change for the first displayed skill, subject to adjustability checks.
function skills.route(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    if (input.pending_experience or 0) > 0 and
        (input.key == "/" or input.key == "|" or
            input.key == "*" or input.key == "=") then
        return { action = "none" }
    end

    if input.adjustable == false and
        (input.pending_experience or 0) == 0 then
        if input.key == "/" or input.key == "|" or
            input.key == "*" or input.key == "=" then
            return { action = "none" }
        end

        for index in ipairs(input.skill_ids or {}) do
            if input.key == menu.letter(index) then
                return { action = "none" }
            end
        end
    end

    if input.key == "/" then
        return { action = "toggle_skill_mode" }
    end

    if input.key == "|" then
        return { action = "toggle_skill_focus" }
    end

    for index, id in ipairs(input.skill_ids or {}) do
        if input.key == menu.letter(index) then
            return {
                action = (input.pending_experience or 0) > 0 and
                    "spend_experience_skill" or "change_skill",
                id = id,
            }
        end
    end

    return {
        action = "notice",
        text = "This training control is unavailable in the Go port.",
    }
end

return skills
