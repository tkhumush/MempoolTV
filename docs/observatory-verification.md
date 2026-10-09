# Observatory salvage verification

## Changes

- Correct epoch math: at height 2015, one block remains until the retarget at
  2016; at height 2016, the new epoch has 2016 blocks remaining. This agrees
  with the provider's `remainingBlocks` and `progressPercent` conventions.
- Preserve optional `loadingIndicators` in WebSocket decoding and model state.
  A loading-only frame does not reset measured queue, fees, or arrival rate.
- Share persisted seen-hash read/write logic between LiveSession and tests,
  keeping the existing defaults key. Expose synchronous event reduction for
  network-free tests; inactive-session gating stays at the event stream consumer.
- Use a tested milliseconds-to-Date property for the provider's retarget
  estimate. Future estimates are intentionally distinct from observations.

## WP1 audit

Reviewed `Observatory/` and its shared transaction model for invented medians,
percentile expansion, projected-block fabrication, missing values replaced with
zero, fee/reward double counting, and transaction ranking/value errors.

- Overview displays the supplied projection array and optional median directly.
  `feeRange` is not expanded into invented transactions or percentiles.
- Mosaic area uses supplied fractional vsize, and colors use supplied effective
  package fee rates. Tiny transactions are grouped only within their fee band.
- Backlog aggregates all 39 provider buckets. Unknown lengths, negative values,
  and nonfinite sizes are unavailable; measured all-zero buckets remain valid.
- Missing metrics display `Unavailable`. The remaining numeric fallbacks are
  navigation indexes and layout denominators, not substitute network data.
  The `0.8...1.2` range in LiveSession is reconnect jitter, not fabricated fees.
- Dossier displays protocol subsidy, measured total fees, and coinbase reward
  separately. Upstream reward is the coinbase output sum, already including
  claimed fees; no fees are added to it. Protocol subsidy is labeled separately
  because historical coinbases can underclaim the allowed reward.
- Dossier transactions remain in block order with paginated loading, exclude
  coinbase, and use weight / 4 for fractional vsize. Output totals include change
  and are labeled as outputs, not economic value transferred or a top-ten list.

Upstream sources checked on 2026-10-09:

- [WS fields and subscriptions](https://github.com/mempool/mempool/blob/master/backend/src/api/websocket-handler.ts)
- [Reward and fee semantics](https://github.com/mempool/mempool/blob/master/backend/src/api/blocks.ts)
- [Statistics bucket boundaries](https://github.com/mempool/mempool/blob/master/backend/src/api/statistics/statistics.ts)
- [Epoch and retarget estimates](https://github.com/mempool/mempool/blob/master/backend/src/api/difficulty-adjustment.ts)

## Validation and Mac handoff

Tests use the existing Swift Testing `memTVTests` target and filesystem-synced
source membership. They use fixed JSON fixtures and isolated UserDefaults suites;
no tests start a live socket or perform HTTP requests.

Coverage: replay and restart persistence, bounded history, silent snapshots,
celebration coalescing and dossier suppression, partial WS messages, explicit
zeros versus absent fields, loading indicators, template snapshot/delta and
sequence recovery, mosaic conservation/non-overlap/color order, backlog totals
and invalid schemas, largest-remainder rounding, epoch boundaries, retarget date
units, subsidy/reward semantics, timezone offsets, observation date validation,
and comparison-at-24h-ago price selection and tolerances.

`git diff --check` passes. Swift and Xcode are not installed on the Linux editing
host: these tests have been reviewed by inspection, not compiled or executed.

On the Mac:

1. Open `memTV/memTV.xcodeproj`, select the memTV scheme and an Apple TV simulator,
   and run the `memTVTests` target. Resolve any compiler/platform findings before
   merging; no project-file registration should be needed.
2. Smoke-test initial synchronization, reconnect/relaunch replay suppression,
   rapid blocks during a celebration, and a new block while the dossier is open.
3. Check the epoch clock against the provider, future retarget date formatting,
   hot-left mosaic colors, and separate subsidy/fees/inclusive reward labels.
4. Check remote focus restoration, reduced-motion celebration, and ambient
   rotation on tvOS; these require UI/device validation beyond the unit tests.
