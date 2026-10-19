-- Example: An invalid keyed MONS slot fails at its DES source site before map placement.
local directives = require("constants.vault_directives")
local choice = require("policy.generation.vaults.specs.choice")
local monster = require("policy.generation.vaults.specs.monster")
local item = require("policy.generation.vaults.specs.item")
local resolve = require("policy.generation.vaults.specs.resolve")

local validate = {}

-- Parse authored MONS and ITEM text before placement so malformed keyed slots fail at their source site.
function validate.operation(vault, operation)
    local parser
    local validate_name

    if operation.kind == directives.MONS or operation.kind == directives.KMONS then
        parser = monster
        validate_name = resolve.validate_monster
    elseif operation.kind == directives.ITEM or operation.kind == directives.KITEM then
        parser = item
        validate_name = resolve.validate_item
    else
        return
    end

    local expression = operation.argument

    if operation.kind == directives.KMONS or operation.kind == directives.KITEM then
        expression = expression:match("^[^=:]+[=:]%s*(.*)$")

        if not expression then
            local site = {
                path = vault.path,
                vault_id = vault.id,
                line = operation.line,
                directive = operation.kind,
                glyph = "?",
            }

            choice.fail(site, operation.argument, "missing keyed assignment")
        end
    end

    local site = {
        path = vault.path,
        vault_id = vault.id,
        line = operation.line,
        directive = operation.kind,
        glyph = "?",
    }

    for _, slot in ipairs(parser.parse(expression, site)) do
        for _, selected in ipairs(slot) do
            validate_name(selected, site)
        end
    end
end

return validate
