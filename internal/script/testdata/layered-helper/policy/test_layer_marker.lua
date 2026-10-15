local marker = require("lib.test_layer_marker")

local policy = {}

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
