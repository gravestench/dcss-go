-- Pan has one live depth but many successive regions. Reserve a storage-ID
-- stride above ordinary branch ranges so a new region can be populated while
-- the old one remains intact for rollback, then retire the old level.
return {
    LEVEL_ID_STRIDE = 10000,
}
