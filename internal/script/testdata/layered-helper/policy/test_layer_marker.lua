-- The probe returns the loaded helper marker to test layer precedence.
-- Example: test.layer_marker returns the marker from the highest VFS layer.

local marker = require("lib.test_layer_marker")

local policy = {}

-- Return the helper imported through the VFS, so a test can observe which
-- layer supplied a same-path Lua module.
function policy.read()
    return {
        value = marker,
    }
end

register.policy({
    id = "test.layer_marker",
    run = policy.read,
})

return policy
