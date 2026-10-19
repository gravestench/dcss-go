-- The custom trap effect runs when its modded trap id activates.
-- Example: triggering TRAP_TEST_CUSTOM emits its custom echo message.

local effect = {}

-- Emit a distinct trap message when activated so the test can detect that
-- a new modded trap reached the common effect dispatcher.
function effect.trigger(ctx)
    ctx:emit("trap", "The custom echo answers.")
end

return effect
