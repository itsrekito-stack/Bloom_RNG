# Bloom RNG Phase 2C — BR-007 Workshop GUI Lifecycle

## Scope

BR-007 only. The authored WorkshopTemplate and gameplay rules are preserved.

## Implementation

- WorkshopRuntime is cloned once per open session and kept mounted while Workshop remains open.
- State refreshes reuse that same shell instead of ClearPanel + Clone.
- Workshop pan and wheel bindings are installed once per open session instead of being disconnected/rebound on every state update.
- Node visual state (owned, revealed, available, selected and transparency) is patched in place.
- Node input handlers are bound once and read current state through node attributes / current UI state, so purchases and affordability changes do not require new connections.
- Selecting a node reuses the shell and only updates its visuals.
- Pan position and zoom remain owned by the live canvas until Workshop closes.

## Safety

Server Workshop state remains authoritative. No costs, prerequisites, rewards, capacities or Respec behavior changed.

Closing Workshop still disconnects pan/wheel input and the next open creates a fresh runtime shell.

## Relationship to BR-005

BR-005 reduced unnecessary full state delivery. BR-007 removes the remaining clone/rebind churn when legitimate state updates arrive while Workshop is open.

## Verification still required in Roblox Studio

- pan while state changes arrive;
- mouse-wheel capture and world-camera isolation;
- hover tooltip after a purchase;
- select → purchase → selected/owned color transition;
- close/reopen;
- Respec;
- 1920×1080, 1366×768 and 1280×720.
