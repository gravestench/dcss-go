local colors = require("policy.presentation.colors")

local help = {}

local lines = {
    "Dungeon Crawl Stone Soup - Help",
    "",
    "Movement: h j k l, y u b n, arrow keys",
    "Wait: . or s     Pick up: g ,     Drop: d     Wield: w",
    "Wear: W     Take off: T     Esc interrupts equipment delay",
    "Put on jewellery: P     Remove jewellery: R",
    "Doors: O open, C close (direction if prompted)",
    "Fire: f     Throw: F     Aim: direction, Tab, Enter, Esc",
    "Evoke wand: V     Select by inventory letter, then aim",
    "Stairs: < or >",
    "Inventory: i     Skills: m     Mutations: A     Help: ?",
    "Save and exit: S (confirm), Ctrl-S (now)",
    "Abandon character: Ctrl-Q (confirm)",
    "Quaff: q (curing, might)         Run right: L (unavailable)",
    "Other unported commands explain their unavailable status.",
    "",
    "Esc - Return",
}

function help.rows()
    local writes = {}

    for index, line in ipairs(lines) do
        writes[#writes + 1] = {
            x = 0,
            y = index - 1,
            text = line,
            fg = index == 1 and colors.yellow or colors.light_grey,
        }
    end

    return { writes = writes }
end

function help.nearby(input)
    local names = {}

    for _, entity in ipairs(input.entities or {}) do
        if entity.role == "monster" and entity.name and entity.name ~= "" then
            names[#names + 1] = "a " .. entity.name
        end
    end

    table.sort(names)

    local writes = {}

    for index, name in ipairs(names) do
        writes[#writes + 1] = {
            x = 0,
            y = index - 1,
            text = name,
            fg = colors.light_grey,
        }
    end

    return { writes = writes }
end

function help.messages(input)
    local history = {}

    for _, message in ipairs(input.history or {}) do
        history[#history + 1] = message
    end

    if input.notice and input.notice ~= "" then
        history[#history + 1] = input.notice
    end

    local writes = {}
    local first = math.max(1, #history - input.height + 1)

    for index = first, #history do
        writes[#writes + 1] = {
            x = 0,
            y = index - first,
            text = history[index]:match("^%s*(.-)%s*$"),
            fg = colors.light_grey,
        }
    end

    return { writes = writes }
end

function help.confirm(input)
    local prompt = "Save game and exit? (Y/n)"

    if input.abandon then
        prompt = "Are you sure you want to abandon this character? (y/N)"
    end

    return {
        writes = {
            { x = 0, y = 0, text = prompt, fg = colors.light_grey },
        },
    }
end

function help.status(input)
    local writes = {}

    if input.kind == "small_terminal" then
        writes[1] = {
            x = 0,
            y = 0,
            text = "Your terminal window is too small; please resize to at least 79,24",
            fg = colors.light_grey,
        }
    elseif input.kind == "stat_choice" then
        writes[1] = {
            x = 0,
            y = input.height - 1,
            text = "Increase (S)trength, (I)ntelligence, or (D)exterity?",
            fg = colors.light_grey,
        }
    elseif input.kind == "death" then
        writes = {
            { x = 0, y = 0, text = "You die...", fg = colors.light_red },
            { x = 0, y = 2, text = "Press Enter to return to startup.", fg = colors.light_grey },
            { x = 0, y = 4, text = "Morgue and high scores are unavailable in the Go port.",
                fg = colors.brown },
        }
    elseif input.kind == "modal_notice" then
        if input.notice and input.notice ~= "" then
            writes[1] = {
                x = 0,
                y = input.height - 1,
                text = input.notice,
                fg = colors.light_red,
            }
        end
    else
        error("unknown status screen " .. tostring(input.kind))
    end

    return { writes = writes }
end

function help.run_nearby(_, input)
    return help.nearby(input)
end

function help.run_messages(_, input)
    return help.messages(input)
end

function help.run_confirm(_, input)
    return help.confirm(input)
end

function help.run_status(_, input)
    return help.status(input)
end

register.policy({ id = "presentation.help", run = help.rows })
register.policy({ id = "presentation.nearby", run = help.run_nearby })
register.policy({ id = "presentation.messages", run = help.run_messages })
register.policy({ id = "presentation.confirm", run = help.run_confirm })
register.policy({ id = "presentation.status", run = help.run_status })

return help
