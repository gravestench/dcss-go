# Ordinary animal combat implementation plan

1. Add source-backed tests for quokka HP, plain bite input, XP range, player bump defense, death/corpse identity, save continuation, and unsupported monster rejection.
2. Replace rat-only combat and XP functions with an ordinary animal path driven by catalog definitions; update the supported fixture and death pipeline.
3. Extend save validation for both animals while loading earlier rat-only version-6 saves. Keep player attacks and UI messages keyed by live target identity.
4. Run focused tests, then full Go tests/vet/build and a read-only whole-branch review. Commit the category and fast-forward Go `main`.
