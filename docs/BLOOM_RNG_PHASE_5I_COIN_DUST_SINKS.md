# Bloom RNG Phase 5I — Coin & Petal Dust Endgame Sinks

## Result

No new currency system was needed.

The existing Season / Workshop loop already makes Coins and Petal Dust useful beyond the first progression pass.

## Repeatable seasonal spend

Season Turn removes non-Legacy Workshop ownership while refunding Workshop Points only.

The six non-Legacy Workshop branches therefore require their normal currency costs again during the next Season.

At the current v1 costs this creates a repeatable seasonal sink of:

- 3,780 Coins across the six non-Legacy branches.
- 126 Petal Dust across the Economy and Bloom branches.

Coins are also reset on Season Turn, so they remain a current-season progression currency rather than an infinite stockpile.

Petal Dust persists across Season Turn and additionally remains spendable on Flower Mastery.

## Guard

`tools/checks/endgame_sinks_check.py` now verifies the repeatable Coin/Dust Workshop spend, Season reset behavior and Petal Dust persistence alongside the duplicate flower/bee sinks.
