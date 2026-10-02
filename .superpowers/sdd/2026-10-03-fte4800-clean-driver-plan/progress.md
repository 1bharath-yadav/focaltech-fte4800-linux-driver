# SDD ledger — plan: docs/superpowers/plans/2026-10-03-fte4800-clean-driver-plan.md

Pre-flight: the protocol layer and compatibility layer share focal_spi.c; no other task-to-task interface conflicts found yet.
Task 1: Ruling: use Python unittest instead of pytest — pytest is unavailable on the target; unittest is in the standard library and preserves a dependency-free source-contract gate — cost if wrong: only the test command/documentation would need changing.
Task 2: Ruling: protocol/fte4800_protocol.h exposes only hardware constants; the frame-capture helper remains private to focal_spi.c because its state object is private — cost if wrong: moving the prototype later, with no ABI impact.
Task 1: Ruling: tests intentionally remain RED until Task 2 because they pin the defect being removed; this plan treats Task 1 as the test-baseline commit rather than a green production milestone — cost if wrong: task bookkeeping would need correction.
