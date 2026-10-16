local directives = require("constants.vault_directives")

local hooks = {}

local function handler_path(vault)
    return "policy.generation.vaults.arrival." .. vault.id
end

function hooks.validate(vault)
    local handler

    for _, operation in ipairs(vault.operations) do
        if operation.kind == directives.HOOK_RUN or
            operation.kind == directives.HOOK_VETO then
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

function hooks.run(vault, method, api)
    local handler = require(handler_path(vault))
    local callback = handler[method]

    if type(callback) ~= "function" then
        error(string.format("vault %s has no Lua handler method %s", vault.id, method))
    end

    return callback(api)
end

local function emit_into(operations, api)
    local emitter = {}

    setmetatable(emitter, { __index = api })

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
