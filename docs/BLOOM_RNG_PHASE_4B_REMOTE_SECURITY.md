# Bloom RNG Phase 4B — Remote / Security Pass

## Scope

This pass hardens the existing server-authoritative gameplay path without moving business logic to the client.

## Remote contract

`RemoteService` now validates requests before they enter gameplay services:

- unknown actions are rejected;
- payload arguments must be scalar values only;
- Roll request IDs must be bounded positive integers;
- flower and bee slots are bounded by configured capacity maxima;
- dissolve quantities are positive bounded integers;
- IDs are short bounded strings;
- activity phases are whitelisted;
- actions that take no arguments reject injected payloads;
- StateRequest revisions must be bounded non-negative integers.

The existing per-player token bucket remains the first spam gate.

## Server authority retained

Lower gameplay services remain the source of truth for:

- Roll progression unlock and cooldown;
- bee ownership and equipped-copy counts;
- flower ownership/free copies;
- planting proximity;
- activity expiry, step order and proximity;
- Workshop parent/progression/currency costs;
- trial sector and shrine distance;
- Season eligibility, token and stale-profile protection.

The remote schema layer only rejects malformed input early; it does not duplicate reward or economy decisions.

## Verification

`tools/checks/remote_security_check.py` compares routed actions against validator coverage and asserts the critical server-authority guards above.
