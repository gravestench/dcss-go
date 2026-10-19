-- Class policies register as their files are discovered by the layered VFS.
local catalog = {}
local policies = {}
local order = {}

-- Derive the class policy module once from the registered object class ID.
local function policy_path(class_id)
    local name = class_id:lower():gsub("^obj_", "")

    return "policy/item_generation/classes/" .. name .. ".lua"
end

-- Example: catalog.register(classes.OBJ_GOLD, gold_policy) binds gold's eligibility and roll hooks.
-- Reject duplicate classes and incomplete hook tables at load time so generation never falls through silently.
function catalog.register(class_id, policy)
    if type(class_id) ~= "string" or
        not class_id:match("^OBJ_[A-Z0-9_]+$") then
        error("invalid item generation class " .. tostring(class_id))
    end

    if policies[class_id] then
        error("duplicate item generation policy " .. policy_path(class_id))
    end

    if type(policy) ~= "table" or
        type(policy.eligible) ~= "function" or
        type(policy.weight) ~= "function" or
        type(policy.roll) ~= "function" then
        error(policy_path(class_id) .. " requires eligible, weight, roll")
    end

    policies[class_id] = policy
    order[#order + 1] = class_id
end

-- Fail an unsupported class before any subtype draw.
function catalog.policy(class_id)
    local policy = policies[class_id]

    if not policy then
        error("missing item generation policy " .. policy_path(class_id))
    end

    return policy
end

-- Expose registered class IDs for generator validation.
function catalog.classes()
    local classes = {}

    for index, class_id in ipairs(order) do
        classes[index] = class_id
    end

    return classes
end

-- Keep the module path available for diagnostics and loader registration.
function catalog.path(class_id)
    return policy_path(class_id)
end

return catalog
