-- An infinite Lua update tests the runtime instruction budget for modded systems.
-- Theory of operation: execute an endless loop inside a registered update;
-- the sandbox instruction budget must interrupt it and return control.

register.system{
    id = "test.loop",
    -- Deliberately avoid yielding or changing state so only the instruction
    -- budget can terminate this fixture's runaway callback.
    update = function()
        while true do
        end
    end,
}
