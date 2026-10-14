# Dart slug projectile implementation plan

1. Extend ordinary-monster XP inputs for spellcasters and add the source-backed
   dart slug profile and generated-floor roster entry. Test the changed XP rule.
2. Add a focused projectile rule with the source shield, evasion, damage, and
   AC phase order. Test bounded draws and outcomes with a scripted roller.
3. Add a level-owned clear-shot query and generalize one-slot monster spell
   selection for Freeze and Slug Dart. Test obstruction and source frequency.
4. Resolve Slug Dart through the spell system against live player defence,
   record combat events, and preserve deterministic save continuation.
5. Update the port inventory and roadmap. Run integrated verification, review
   the diff, commit this category, and merge it into local Go main.
