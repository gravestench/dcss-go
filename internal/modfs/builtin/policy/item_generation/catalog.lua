-- Class policies register as their files are discovered by the layered VFS.
local catalog = {}
local policies = {}
local order = {}

local function policy_path(class_id)
    local name = class_id:lower():gsub("^obj_", "")

    return "policy/item_generation/classes/" .. name .. ".lua"
end

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

function catalog.policy(class_id)
    local policy = policies[class_id]

    if not policy then
        error("missing item generation policy " .. policy_path(class_id))
    end

    return policy
end

function catalog.classes()
    local classes = {}

    for index, class_id in ipairs(order) do
        classes[index] = class_id
    end

    return classes
end

function catalog.path(class_id)
    return policy_path(class_id)
end

return catalog
