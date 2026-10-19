-- The custom cloud effect runs through the same dispatch table as built-in clouds.
-- Example: applying CLOUD_TEST_CUSTOM emits the silver haze cloud message.

local custom = {}

-- Emit a distinct cloud message through the common effect API, proving a
-- mod-added cloud handler is dispatched like an embedded one.
function custom.apply(ctx)
    ctx:emit("cloud", "The silver haze shimmers.")
end

return custom
