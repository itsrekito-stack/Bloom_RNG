# Bloom RNG Phase 2F — BR-006 Public Replication Scaling

## Previous behavior

Every second the server built one global array containing all equipped bee frames and one global array containing all public activity tokens, then broadcast both arrays to every connected player.

The client discarded other-player bees when ShowOtherPollinators was disabled and discarded tokens when HideOtherPlayersTokens was enabled. This meant bandwidth and client deserialization cost were paid before the preference filter.

## New behavior

Public replication remains bounded to a one-second cadence by `BloomConfig.PublicSyncSeconds`.

The server now builds bee frames once, grouped by owner, and sends each recipient only:

- their own bee frames, always;
- other-player bee frames when ShowOtherPollinators is enabled and the other garden is within PublicReplicationRadius.

Other activity tokens are sent only when:

- HideOtherPlayersTokens is false;
- the token belongs to another player;
- the token is within PublicReplicationRadius of the recipient.

The current radius is 180 studs. Center-to-sector distance is roughly 165–170 studs in LocationsConfig, so nearby center/sector activity remains visible while distant sectors/opposite plots stop producing irrelevant traffic.

Empty recipient-specific arrays are still sent so clients remove models/tokens that moved out of range or became hidden by settings.

## Complexity

This removes the O(all public entities) payload from every recipient.

Bee frames are grouped by owner, so visibility is decided once per owner/recipient pair rather than once per bee. Token filtering remains per visible candidate because tokens have independent positions.

This does not claim exact bandwidth savings without Roblox network profiling.

## Safety

No reward, activity collection, bee simulation, ownership, or server authority changed. This only changes public presentation replication.

The recipient's own bee frames are never distance-filtered.

## Acceptance remaining

Roblox Studio should verify two or more players:

- ShowOtherPollinators ON/OFF removes/restores nearby bees;
- walking farther than the radius removes distant bees;
- HideOtherPlayersTokens ON/OFF clears/restores nearby public tokens;
- own bees remain visible;
- personal activity prompts continue through the separate Activities event.
