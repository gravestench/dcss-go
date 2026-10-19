-- Example: A DES NAME selects a Lua hook while the DES MAP remains the placed layout.
local directives = require("constants.vault_directives")

local hooks = {}

-- A .des map is still the authoritative layout. Its family and NAME choose
-- a same-named Lua module only when a directive calls a named hook.
local function handler_path(vault)
    return "policy.generation.vaults." .. vault.family .. "." .. vault.id
end

-- Load the named handler early so missing methods fail before mutating a level.
function hooks.validate(vault)
    local handler

    -- Validate the complete hook contract before placement. This reports a
    -- broken mod at load time instead of only when a rare vault is selected.
    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_RUN or
            operation.kind == directives.HOOK_VETO or
            operation.kind == directives.HOOK_POST_PLACE then
            if handler == nil then
                local ok, loaded = pcall(require, handler_path(vault))

                if not ok then
                    error(string.format("%s:%d: vault %s: handler %s method %s: %s",
                        vault.path, operation.line, vault.id, handler_path(vault),
                        operation.argument, loaded))
                end

                handler = loaded
            end

            if type(handler[operation.argument]) ~= "function" then
                error(string.format("%s:%d: vault %s: missing Lua handler method %s",
                    vault.path, operation.line, vault.id, operation.argument))
            end
        end
    end
end

-- Call only the method declared by the map's pinned hook reference.
function hooks.run(vault, method, api)
    local handler = require(handler_path(vault))
    local callback = handler[method]

    if type(callback) ~= "function" then
        error(string.format("vault %s has no Lua handler method %s", vault.id, method))
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
