# Deep Elf Fighter implementation plan

1. Write a source-value Deep Elf starting-profile test and a terminal
   start/save round-trip test. Confirm they fail before enabling the species.
2. Add Deep Elf to the focused Fighter support boundary in character rules,
   MP projection, and the species menu. Reuse selected-identity gameplay and
   save paths from the Hill Orc slice.
3. Verify automatic Intelligence growth and preserve impossible-stat save
   rejection. Update current roadmap wording for the third playable species.
4. Run the full Go suite, vet, build, style gate, and diff check; request
   read-only review; commit one category and fast-forward local Go `main`.
