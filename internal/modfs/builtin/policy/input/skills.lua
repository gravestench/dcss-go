local menu = require("policy.input.menu")

local skills = {}

function skills.route(input)
    local navigation = menu.close_or_help(input)

    if navigation then
        return navigation
    end

    if input.adjustable == false then
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
                action = "change_skill",
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
