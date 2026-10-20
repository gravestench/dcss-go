-- AI roles persist in the Go-hosted actor store and are consumed by Lua
-- decisions and save rules. Import these names instead of retyping them.
local behaviors = {
    SLEEP = "sleep",
    WANDER = "wander",
    SEEK = "seek",
    LEGACY_CHASE = "chase",
}

return behaviors
