-- Build one effective ruleset from bundled files and the active mod layers.
-- Validate content before loading policies so broken references fail at boot.
-- Systems come last because their scheduler registrations depend on those rules.

-- The sorted domain order is part of the ruleset contract. New files in a
-- domain tree are discovered without editing this entrypoint.
-- Component schemas must exist before content and policy register references.
mod.load_tree("schemas")
mod.load_tree("content")
require("content.validation").check()
-- Catalog validation uses the winning definition from each VFS layer.
mod.load_tree("policy")
require("policy.clouds.catalog").validate()
require("policy.shops.catalog").validate()
require("policy.traps.catalog").validate()
require("policy.traps.zot.catalog").validate()
require("policy.item_generation.validate").check()
require("policy.generation.vaults.catalog").load()
require("policy.mutations.effects.registry").validate()
require("policy.potions").validate()
require("policy.scrolls").validate()
-- Register turn systems after all policies have resolved their dependencies.
mod.load_tree("systems")
mod.load_tree("generation")
mod.load_tree("ui")
