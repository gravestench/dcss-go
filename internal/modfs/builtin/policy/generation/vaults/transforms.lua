local directives = require("constants.vault_directives")
local effects = require("constants.vault_effects")

-- Apply DES glyph edits before keyed features bind to their final cells.
local transforms = {}

local function split(text, separator)
    local parts = {}

    for part in (text .. separator):gmatch("(.-)" .. separator) do
        parts[#parts + 1] = part:match("^%s*(.-)%s*$")
    end

    return parts
end

local function candidates(specification)
    local choices = {}

    for token in specification:gmatch("%S+") do
        local glyph, weight = token:match("^(.):(%d+)$")

        if glyph then
            choices[#choices + 1] = {
                glyph = glyph,
                weight = tonumber(weight),
            }
        else
            for index = 1, #token do
                choices[#choices + 1] = {
                    glyph = token:sub(index, index),
                    weight = 10,
                }
            end
        end
    end

    return choices
end

local function draw(random, specification)
    local choices = candidates(specification)
    local total = 0

    for _, choice in ipairs(choices) do
        total = total + choice.weight
    end

    if total == 0 then
        return nil
    end

    local roll = random:roll(total)

    for _, choice in ipairs(choices) do
        if roll < choice.weight then
            return choice.glyph
        end

        roll = roll - choice.weight
    end
end

local function assignment(text)
    local source, mode, target = text:match("^%s*(%S+)%s+([=:])%s*(.-)%s*$")

    if not source then
        source, mode, target = text:match("^%s*([^=:]+)([=:])%s*(.-)%s*$")
    end

    if not source then
        source, mode, target = text:match("^%s*([=:])([=:])%s*(.-)%s*$")
    end

    if not source or source == "" or target == "" then
        return nil
    end

    return source:gsub("%s", ""), mode, target
end

local function subst(cells, argument, random)
    for _, part in ipairs(split(argument, ",")) do
        local source, mode, target = assignment(part)

        if not source then
            return false
        end

        local shared = mode == ":" and draw(random, target)

        for _, row in ipairs(cells) do
            for x, glyph in ipairs(row) do
                if source:find(glyph, 1, true) then
                    row[x] = shared or draw(random, target) or glyph
                end
            end
        end
    end

    return true
end

local function clear(cells, argument)
    for glyph in argument:gmatch("%S") do
        for _, row in ipairs(cells) do
            for x, present in ipairs(row) do
                if present == glyph then
                    row[x] = " "
                end
            end
        end
    end

    return true
end

local function shuffle(cells, argument, random)
    for _, group in ipairs(split(argument, ",")) do
        local original = split(group:gsub("%s", ""), "/")
        local width = #original[1]

        for _, block in ipairs(original) do
            if #block ~= width then
                return false
            end
        end

        local shuffled = {}

        for index, glyph in ipairs(original) do
            shuffled[index] = glyph
        end

        for index = #shuffled, 2, -1 do
            local chosen = random:roll(index) + 1

            shuffled[index], shuffled[chosen] = shuffled[chosen], shuffled[index]
        end

        if #original == 1 then
            original = {}
            shuffled = {}

            for index = 1, #group do
                local glyph = group:sub(index, index)

                if glyph ~= " " then
                    original[#original + 1] = glyph
                    shuffled[#shuffled + 1] = glyph
                end
            end

            for index = #shuffled, 2, -1 do
                local chosen = random:roll(index) + 1

                shuffled[index], shuffled[chosen] = shuffled[chosen], shuffled[index]
            end
        end

        for _, row in ipairs(cells) do
            for x, glyph in ipairs(row) do
                for block_index, block in ipairs(original) do
                    local position = block:find(glyph, 1, true)

                    if position then
                        row[x] = shuffled[block_index]:sub(position, position)

                        break
                    end
                end
            end
        end
    end

    return true
end

local function nsubst_source(cells, sources, spec, random)
    local positions = {}

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if sources:find(glyph, 1, true) then
                positions[#positions + 1] = {
                    x = x,
                    y = y,
                    glyph = glyph,
                }
            end
        end
    end

    local cursor = 1

    local parts = split(spec, "/")

    for index, part in ipairs(parts) do
        local count, mode, target = part:match("^(%d+)%s*([=:])%s*(.*)$")

        if not count then
            count, mode, target = part:match("^(%*)%s*([=:])%s*(.*)$")
        end

        if not count then
            target = part
            count = index == #parts and "*" or "1"
            mode = "="
        end

        local limit = count == "*" and #positions or math.min(#positions, cursor + tonumber(count) - 1)
        local shared = mode == ":" and draw(random, target)

        while cursor <= limit do
            local remaining = #positions - cursor + 1
            local chosen = cursor + random:roll(remaining)

            positions[cursor], positions[chosen] = positions[chosen], positions[cursor]

            local point = positions[cursor]

            cells[point.y][point.x] = shared or draw(random, target) or point.glyph
            cursor = cursor + 1
        end
    end

end

local function nsubst_one(cells, argument, random)
    local sources, _, spec = assignment(argument)

    if not sources then
        return false
    end

    nsubst_source(cells, sources, spec, random)

    return true
end

local function nsubst(cells, argument, random)
    for _, part in ipairs(split(argument, ",")) do
        if not nsubst_one(cells, part, random) then
            return false
        end
    end

    return true
end

function transforms.apply(cells, operation, random)
    if operation.kind == directives.SUBST then
        return subst(cells, operation.argument, random)
    elseif operation.kind == directives.NSUBST then
        return nsubst(cells, operation.argument, random)
    elseif operation.kind == directives.SHUFFLE then
        return shuffle(cells, operation.argument, random)
    elseif operation.kind == directives.CLEAR then
        return clear(cells, operation.argument)
    end

    return false
end

local function octa_room(cells, arguments)
    local width = #cells[1]
    local height = #cells
    local oblique = arguments.oblique

    for y, row in ipairs(cells) do
        for x, glyph in ipairs(row) do
            if arguments.replace:find(glyph, 1, true) then
                local left = math.max(oblique + 1 - x, 0)
                local right = math.max(oblique + x - width, 0)
                local inset = left + right

                if y >= 1 + inset and y <= height - inset then
                    row[x] = arguments.inside
                else
                    row[x] = arguments.outside
                end
            end
        end
    end
end

local function adjacent_smear(cells, x, y, smear, boxy)
    local cardinal = {
        { x = 1, y = 0 },
        { x = -1, y = 0 },
        { x = 0, y = 1 },
        { x = 0, y = -1 },
    }
    local diagonal = {
        { x = 1, y = 1 },
        { x = -1, y = 1 },
        { x = 1, y = -1 },
        { x = -1, y = -1 },
    }

    for _, direction in ipairs(cardinal) do
        if cells[y + direction.y][x + direction.x] == smear then
            return true
        end
    end

    if not boxy then
        for _, direction in ipairs(diagonal) do
            if cells[y + direction.y][x + direction.x] == smear then
                return true
            end
        end
    end

    return false
end

local function smear_map(cells, arguments, random)
    local width = #cells[1]
    local height = #cells
    local attempts = 0
    local maximum = arguments.iterations * 10

    for _ = 1, arguments.iterations do
        local placed = false

        while attempts < maximum and not placed do
            attempts = attempts + 1

            local x = 2 + random:roll(width - 2)
            local y = 2 + random:roll(height - 2)
            local glyph = cells[y][x]

            if arguments.onto:find(glyph, 1, true) and
                adjacent_smear(cells, x, y, arguments.smear, arguments.boxy) then
                cells[y][x] = arguments.smear
                placed = true
            end
        end

        if not placed then
            return
        end
    end
end

function transforms.apply_effect(cells, record, random)
    if record.kind == effects.OCTA_ROOM then
        octa_room(cells, record.arguments)

        return true
    elseif record.kind == effects.SMEAR_MAP then
        smear_map(cells, record.arguments, random)

        return true
    end

    return false
end

function transforms.rotate(cells, quarter_turns)
    local result = cells

    for _ = 1, quarter_turns % 4 do
        local rotated = {}
        local height = #result
        local width = #result[1]

        for y = 1, width do
            rotated[y] = {}

            for x = 1, height do
                rotated[y][x] = result[height - x + 1][y]
            end
        end

        result = rotated
    end

    return result
end

return transforms
