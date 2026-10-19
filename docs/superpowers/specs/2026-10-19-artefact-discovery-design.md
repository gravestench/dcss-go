# Artefact discovery design

## Purpose

The current item policy treats an artefact weapon or armour as type-known
because its base kind has no shared appearance pool. That can show a random
artefact's true name before identification. The next item-domain slice makes
artefact discovery belong to each physical item while ordinary potion,
scroll, wand, and jewellery discovery continues to belong to the player's
known-kind catalog. The source name database is a later content category;
this slice makes the existing committed true and appearance names display at
the right time.

## Source behavior

`item-name.cc:item_type_known` checks an item's own type flag before shared
kind knowledge, then explicitly excludes artefacts from that shared path.
`artefact.cc:get_artefact_name` chooses the true name only after item type
knowledge; otherwise it chooses the saved appearance. Most fixed artefacts
whose true name equals their appearance start fully identified. The source
exception is a fixed artefact with the `unided` flag. Random artefacts begin
unidentified, even when the ordinary base kind is known. An Identify scroll
reveals type, pluses, and properties. Shops expose identified stock and a
purchase retains that per-item state. A discovered artefact must not reveal
other items of the same base kind.

## Ownership and flow

The existing `item.artefact` ECS component keeps true name, appearance,
properties, and per-property knowledge. `item.identification` keeps the
per-item type, plus, and full-property flags. The Lua identification policy
owns the source rule for when a fixed artefact self-identifies and chooses
which name the player sees. Until the source random-name database is ported,
random artefacts use its non-descript fallback without exposing a jewellery
subtype. Self-identification is derived from immutable definition fields.
Generation initializes the mutable per-property knowledge map consistently
with that rule, without storing another automatic-identification flag. All
other artefacts start unknown. A type reveal marks an
artefact instance, while ordinary pooled kinds still update the player's
shared knowledge. A full property reveal also marks the artefact's known
property map so the two saved components agree. Shop and Identify flows call
these existing policy methods instead of gaining artefact-specific handlers.

## Mod and save contract

A mod-added fixed artefact follows the same rule from its `name`,
`appearance`, and `flags` fields. An absent appearance means the true name is
also its appearance. The `unided` flag suppresses automatic identification
even when those strings match. Save validation accepts per-item type flags
for artefacts without ordinary appearance pools and rejects impossible
knowledge on non-artefact items. The ruleset hash continues to cover content
and policy file overrides.

## Verification

Lua tests cover a hidden named fixed artefact, a self-identifying fixed
artefact, an `unided` fixed artefact, a random artefact, Identify, shop stock,
shared-kind isolation, per-property knowledge, and save validation. A Go
restore test proves per-item discovery survives serialization. Run focused
tests, the complete Lua rules suite once after the domain change, relevant
Go item tests, package compilation, style, and diff checks. Commit this
category, fast-forward `main`, and push the fork.
