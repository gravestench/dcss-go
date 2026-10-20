-- The lava triangle moves the entrance and altar sites with each supported count.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["9"] = {
        {
            kind = directives.SUBST,
            argument = "c = {, C = B, `G = l, defDEFA = ., a = T",
        },
    },
    ["13"] = {
        {
            kind = directives.SUBST,
            argument = "d = {, D = B, `G = l, cefCEFA = ., a = T",
        },
    },
    ["16"] = {
        {
            kind = directives.SUBST,
            argument = "e = {, E = B, `G = l, acdfCDF = ., A : TUV...",
        },
    },
    ["19"] = {
        {
            kind = directives.SUBST,
            argument = "f = {, F = B, `acdeCDE = .",
        },
    },
    ["21"] = {
        {
            kind = directives.SUBST,
            argument = "f = {, FG = B, `acdeCDE = .",
        },
    },
    default = {
        {
            kind = directives.SUBST,
            argument = "c = {, C = B, `G = l, defDEFA = ., A = T",
        },
    },
}

-- Apply only the selected arm. Emitting through the vault API keeps the
-- source order relative to the static directives around this hook.
local function configure(api)
    local selected = arrangements[count.selected(api)] or arrangements.default or {}

    for _, operation in ipairs(selected) do
        api:emit(operation.kind, operation.argument)
    end
end

handler.configure = configure

return handler
