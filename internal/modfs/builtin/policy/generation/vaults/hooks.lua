-- Example: A DES NAME selects a Lua hook while the DES MAP remains the placed layout.
local directives = require("constants.vault_directives")

local hooks = {}

-- A .des map is still the authoritative layout. Its family and NAME choose
-- a same-named Lua module only when a directive calls a named hook.
local function handler_path(vault, method)
    local module_name, callback_name = method:match(
        "^([a-z][a-z0-9_]*)%.([a-z][a-z0-9_]*)$")

    module_name = module_name or vault.id
    callback_name = callback_name or method

    if vault.family == "layout" then
        return "policy.generation.layouts." .. module_name, callback_name
    end

    return "policy.generation.vaults." .. vault.family .. "." ..
        module_name, callback_name
end

-- Load the named handler early so missing methods fail before mutating a level.
function hooks.validate(vault)
    -- Validate the complete hook contract before placement. This reports a
    -- broken mod at load time instead of only when a rare vault is selected.
    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_RUN or
            operation.kind == directives.HOOK_VALIDATE or
            operation.kind == directives.HOOK_VETO or
            operation.kind == directives.HOOK_POST_PLACE then
            local path, callback = handler_path(vault, operation.argument)
            local ok, handler = pcall(require, path)

            if not ok then
                error(string.format("%s:%d: vault %s: handler %s method %s: %s",
                    vault.path, operation.line, vault.id, path,
                    callback, handler))
            end

            if type(handler[callback]) ~= "function" then
                error(string.format("%s:%d: vault %s: missing Lua handler method %s",
                    vault.path, operation.line, vault.id, callback))
            end
        end
    end
end

-- Call only the method declared by the map's pinned hook reference.
function hooks.run(vault, method, api)
    local path, callback_name = handler_path(vault, method)
    local handler = require(path)
    local callback = handler[callback_name]

    if type(callback) ~= "function" then
        error(string.format("vault %s has no Lua handler method %s", vault.id, callback_name))
    end

    return callback(api)
end

-- Capture emitted directives as typed operations at the hook's source position.
local function emit_into(operations, api)
    local emitter = {}

    -- A hook can read the vault API and append typed directives, but cannot
    -- mutate the parsed source operation list while it is being traversed.
    setmetatable(emitter, { __index = api })

    -- Reject nonstring directives before their text reaches the DES operation parser.
    function emitter:emit(kind, argument)
        if type(kind) ~= "string" or type(argument) ~= "string" then
            error("vault hook must emit a directive kind and string argument")
        end

        operations[#operations + 1] = {
            kind = kind,
            argument = argument,
        }
    end

    return emitter
end

-- Insert hook emissions where their source directive occurred rather than appending them after the map.
function hooks.expand(vault, api)
    local operations = {}

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_RUN then
            local emitter = emit_into(operations, api)

            hooks.run(vault, operation.argument, emitter)
        else
            operations[#operations + 1] = operation
        end
    end

    return operations
end

return hooks
