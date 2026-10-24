# Monster Contact Acid and Distortion

## Intent

Complete the special effects of source monster attacks that use acid splash
or distortion. Reach Tongue is an acid attack after its two-cell contact;
Rift is a distortion attack after its three-cell contact. Ordinary Acid and
Distort use the same effect owners. Both player and monster defenders must
receive the effect through the live melee path.

## Source behavior

`melee-attack.cc` groups `AF_REACH_TONGUE` with `AF_ACID` and `AF_RIFT` with
`AF_DISTORT`. The attack flavour runs on a successful damaging contact;
the source's damageless exception list contains neither family. Acid splash
uses the existing player acid brand packet or the existing monster acid
resistance and corrosion owner. Distortion uses the same weighted spatial
damage, blink, and banishment outcomes as the existing distortion brand.
Movement attacks exclude blink and banishment against the player.

## Ownership

Keep the flavour aliases in `constants.attack_flavours`. The monster attack
flavour policy chooses the effect and supplies its resolved contact to the
existing acid and distortion owners. It does not copy the random table or
relocation rules. A monster target gets its current health, definition,
and kill credit in the brand owner's normal hit envelope.

## Verification

Exercise player and monster victims with production ECS schemas. Check both
aliases, damage and corrosion, distortion's damage and movement outcomes,
zero damage, misses, and the live melee routing where deterministic contact
can be forced. Run the Lua rule suite and affected Go tests at the category
boundary, then commit and push this contiguous attack-flavour category.
