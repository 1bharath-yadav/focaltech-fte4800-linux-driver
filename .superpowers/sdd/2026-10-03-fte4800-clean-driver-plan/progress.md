# SDD ledger — plan: docs/superpowers/plans/2026-10-03-fte4800-clean-driver-plan.md

Pre-flight: the protocol layer and compatibility layer share focal_spi.c; no other task-to-task interface conflicts found yet.
Task 1: Ruling: use Python unittest instead of pytest — pytest is unavailable on the target; unittest is in the standard library and preserves a dependency-free source-contract gate — cost if wrong: only the test command/documentation would need changing.
