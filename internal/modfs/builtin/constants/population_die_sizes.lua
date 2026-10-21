-- Source branch metadata names these dice instead of storing numeric values.
-- Resolve the names at the population rule so a new branch can reuse them
-- without copying a literal or changing the branch catalog schema.
local sizes = {
    DEFAULT_MON_DIE_SIZE = 12,
    HELL_MON_DIE_SIZE = 6,
    DUNGEON_DEEP_MON_DIE_SIZE = 10,
}

return sizes
