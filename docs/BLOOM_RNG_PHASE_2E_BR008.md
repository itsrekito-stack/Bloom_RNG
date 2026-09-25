# Bloom RNG Phase 2E — BR-008 Roulette Request Correlation

## Verification result

BR-008 was still present on current main.

The visual generation protected most tween work, but the landing coroutine cleared `RouletteLanding` unconditionally after cancellation. A sufficiently fast STOP → START → new landing sequence could therefore let an old coroutine clear the new landing state.

Roll Ack messages also had no request identity, so a late failed Ack from an older auto-roll session could disable a newly restarted session.

## Fix

- Client roll requests now carry a monotonic RequestId.
- The server echoes RequestId in Reward and Ack payloads.
- Client tracks the RollSession that created each request.
- Rewards from an older session are ignored visually; the server grant remains authoritative.
- Failed Acks stop Auto only when they belong to the current RollSession.
- Settle StepRoulette calls now carry the roulette generation.
- Landing cleanup returns immediately when its generation is stale and cannot clear a newer landing.

## Product behavior preserved

Pressing STOP still hides roulette immediately.

A reward that was already granted server-side after STOP does not resurrect roulette.

Normal roll results remain represented only by the roulette; the removed RewardReveal behavior is not restored.

## Acceptance

Roblox Studio should stress:

1. start Auto;
2. STOP while request is pending;
3. START immediately;
4. repeat while settle animation is active;
5. inject/observe cooldown or rate-limit Ack;
6. verify old Reward/Ack never stops or overwrites the new visual session.
