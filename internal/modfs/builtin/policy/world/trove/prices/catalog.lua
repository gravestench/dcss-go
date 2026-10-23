-- Theory of operation: price kinds beyond the three source Trove kinds live
-- in separate Lua modules. The layered VFS lists effective files, so a mod
-- adds a kind with one file and may replace that same path later. These
-- modules use the existing saved price fields and provide their own match,
-- debit, display, and receipt rules without changing the Go engine.
-- Example: policy/world/trove/prices/gold.lua can return a policy whose id
-- is "gold" and whose commit function debits a character wallet.
local catalog = {}
local trove = require("constants.trove")
local policies

-- Discover effective modules once per ruleset. Sorting comes from the VFS,
-- but selection is by kind ID, never by file or load order.
local function load()
    if policies then
        return policies
    end

    policies = {}

    for _, path in ipairs(mod.paths("policy/world/trove/prices", ".lua")) do
        if path ~= "policy/world/trove/prices/catalog.lua" then
            local module_name = path:sub(1, -5):gsub("/", ".")
            local policy = require(module_name)

            if type(policy) ~= "table" or type(policy.id) ~= "string" or
                policy.id == "" or policy.id:find("|", 1, true) or
                policy.id == trove.PRICE_ITEM or
                policy.id == trove.PRICE_RUNE or
                policy.id == trove.PRICE_NO_PIETY or
                type(policy.valid) ~= "function" or
                type(policy.name) ~= "function" or
                type(policy.match) ~= "function" or
                type(policy.commit) ~= "function" or
                type(policy.valid_receipt) ~= "function" then
                error("invalid Trove price policy " .. path)
            end

            if policies[policy.id] then
                error("duplicate Trove price policy " .. policy.id)
            end

            policies[policy.id] = policy
        end
    end

    return policies
end

-- A missing kind is an invalid modded gate, not a free entrance.
function catalog.get(kind)
    return load()[kind]
end

return catalog
