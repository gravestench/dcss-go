-- The clearing reshapes its trees and altar sites for the two source layouts.
-- The selected count comes from the saved Temple plan, not from a new roll.
local count = require("policy.generation.vaults.temple.altar_count")
local directives = require("constants.vault_directives")

local handler = {}

-- Source DES directives remain ordered within each count-specific layout.
local arrangements = {
    ["11"] = {
        {
            kind = directives.SUBST,
            argument = "< = {, w = ., \" : t', ( = B, C = ., U = T, z = x",
        },
        {
            kind = directives.SHUFFLE,
            argument = "xGTUu",
        },
        {
            kind = directives.SUBST,
            argument = "u = t",
        },
        {
            kind = directives.FTILE,
            argument = "' = floor_dirt",
        },
    },
    ["14"] = {
        {
            kind = directives.SUBST,
            argument = "( = {, < = w",
        },
        {
            kind = directives.SHUFFLE,
            argument = "'\"w / \"'W",
        },
        {
            kind = directives.SUBST,
            argument = "\"W = t, CT = B, z = ., Ux : GUUTTxt",
        },
        {
            kind = directives.FTILE,
            argument = "'w = floor_dirt",
        },
        {
            kind = directives.FTILE,
            argument = "\" = floor_grass",
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
