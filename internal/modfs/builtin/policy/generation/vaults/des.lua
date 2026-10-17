local directives = require("constants.vault_directives")
local depth = require("policy.generation.vaults.depth")

local des = {}

local known_directives = {}

for _, kind in pairs(directives) do
    if kind ~= directives.HOOK_RUN and
        kind ~= directives.HOOK_VETO and
        kind ~= directives.HOOK_POST_PLACE then
        known_directives[kind] = true
    end
end

local function fail(path, line, id, detail)
    local owner = id or "unnamed vault"

    error(string.format("%s:%d: %s: %s", path, line, owner, detail))
end

local function source_lines(source)
    local lines = {}
    local normalized = source:gsub("\r\n", "\n")

    for line in (normalized .. "\n"):gmatch("(.-)\n") do
        lines[#lines + 1] = line
    end

    return lines
end

local function valid_id(id)
    return id and id:match("^[a-z][a-z0-9_]*$") ~= nil
end

local function add_directive(vault, kind, argument, line)
    local operation = {
        kind = kind,
        argument = argument,
        line = line,
    }

    vault.operations[#vault.operations + 1] = operation

    if kind == directives.TAGS then
        for tag in argument:gmatch("%S+") do
            vault.tags[tag] = true
        end
    elseif kind == directives.ORIENT then
        vault.orientation = argument
    elseif kind == directives.DEPTH then
        -- Read after continuations have joined their source lines.
    elseif kind == directives.CHANCE then
        -- Read after continuations have joined their source lines.
    elseif kind == directives.WEIGHT then
        local weight = tonumber(argument)

        if not weight or weight < 1 or weight % 1 ~= 0 then
            fail(vault.path, line, vault.id, "invalid WEIGHT " .. argument)
        end

        vault.weight = weight
    end
end

local function add_hook(vault, text, line)
    local stage, method = text:match('^:%s*vault%.([a-z_]+)%s*%(%s*"([a-z][a-z0-9_]*)"%s*%)%s*$')

    if stage ~= "run" and stage ~= "veto" and
        stage ~= "post_place" then
        fail(vault.path, line, vault.id, "unported inline Lua or malformed vault hook")
    end

    local kind = directives.HOOK_VETO

    if stage == "run" then
        kind = directives.HOOK_RUN
    elseif stage == "post_place" then
        kind = directives.HOOK_POST_PLACE
    end

    vault.operations[#vault.operations + 1] = {
        kind = kind,
        argument = method,
        line = line,
    }
end

local function parse_declaration(vault, text, line)
    if text:sub(1, 1) == ":" then
        add_hook(vault, text, line)

        return
    end

    if text == "{{" or text:match("^veto%s*{{") then
        fail(vault.path, line, vault.id, "unported inline Lua block")
    end

    local kind, argument = text:match("^([A-Z]+):%s*(.*)$")

    if not kind or not known_directives[kind] then
        fail(vault.path, line, vault.id, "unknown DES directive " .. text)
    end

    add_directive(vault, kind, argument, line)
end

local function append_continuation(vault, text, line)
    local operation = vault.operations[#vault.operations]

    if not operation then
        fail(vault.path, line, vault.id, "directive continuation has no owner")
    end

    operation.argument = operation.argument:gsub("\\%s*$", "") .. " " .. text:gsub("^%s+", "")
end

function des.parse(path, source)
    local vault = {
        path = path,
        family = path:match("^vaults/([^/]+)/"),
        tags = {},
        orientation = "float",
        weight = 10,
        depths = {},
        chances = {},
        rows = {},
        operations = {},
    }

    local in_map = false
    local map_seen = false
    local continuing = false

    for line_number, line in ipairs(source_lines(source)) do
        if in_map then
            if line == "ENDMAP" then
                in_map = false
            else
                vault.rows[#vault.rows + 1] = line
            end
        elseif continuing then
            append_continuation(vault, line, line_number)
            continuing = line:match("\\%s*$") ~= nil
        elseif line == "MAP" then
            if not vault.id or map_seen then
                fail(path, line_number, vault.id, "unexpected MAP")
            end

            in_map = true
            map_seen = true
        elseif line:match("^NAME:") then
            if vault.id then
                fail(path, line_number, vault.id, "multiple NAME declarations")
            end

            local id = line:match("^NAME:%s*(%S+)%s*$")

            if not valid_id(id) then
                fail(path, line_number, nil, "invalid NAME " .. line)
            end

            vault.id = id
        elseif line == "" or line:match("^#") then
            -- Source provenance and ported script text stay in DES comments.
        else
            if not vault.id then
                fail(path, line_number, nil, "declaration before NAME")
            end

            parse_declaration(vault, line, line_number)
            continuing = line:match("\\%s*$") ~= nil
        end
    end

    local post_place = false

    for _, operation in ipairs(vault.operations) do
        local site = {
            path = vault.path,
            line = operation.line,
            id = vault.id,
        }

        if operation.kind == directives.DEPTH then
            for _, rule in ipairs(depth.parse_rules(operation.argument, site)) do
                vault.depths[#vault.depths + 1] = rule
            end
        elseif operation.kind == directives.CHANCE then
            vault.chances[#vault.chances + 1] =
                depth.parse_chance(operation.argument, site)
        end

        post_place = post_place or
            operation.kind == directives.HOOK_POST_PLACE
    end

    if in_map or continuing or not map_seen or
        (#vault.rows == 0 and not post_place) then
        fail(path, #source_lines(source), vault.id, "incomplete DES map or directive")
    end

    return vault
end

return des
