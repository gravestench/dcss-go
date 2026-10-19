local modal = require("policy.input.modal")

local mutations = {}

-- The mutation screen routes navigation and close keys without changing mutation state.
-- Example: mutations.route({ key = "pgdown", page = 0, pages = 3 }) asks for
-- page one; the terminal then redraws from the same ECS mutation records.
function mutations.route(input)
    local key = input.key
    local page = input.page
    local pages = input.pages

    if input.selected and input.selected ~= "" then
        if key == "esc" or key == "enter" then
            return { action = "mutation_close_detail" }
        end

        if key == "?" then
            return modal.route(input)
        end
    else
        if key == "esc" or key == "?" then
            return modal.route(input)
        end

        for _, option in ipairs(input.options or {}) do
            if option.key == key then
                return {
                    action = "mutation_detail",
                    id = option.id,
                }
            end
        end
    end

    if key == "pgdown" or key == "down" or key == "space" then
        return {
            action = "mutation_page",
            page = math.min(page + 1, pages - 1),
        }
    end

    if key == "pgup" or key == "up" then
        return {
            action = "mutation_page",
            page = math.max(page - 1, 0),
        }
    end

    return {
        action = "notice",
        text = "This mutation control is unavailable in the Go port.",
    }
end

return mutations
