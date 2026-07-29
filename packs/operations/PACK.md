---
name: operations
kind: domain-pack
description: Infrastructure, access, and running systems. Loaded when the router classifies domain=operations.
---

# Operations pack

Loaded on demand. Universal rules live in the kernel core and are not repeated here.

Most work in this domain classifies as protected. That is correct, not friction:
operations changes are frequently irreversible, frequently quiet when wrong, and
frequently affect people who did not ask for them.

## Evidence that matters

The running system, never the change record. `applied` is not `working`. Read the
live state: the actual DNS answer, the actual certificate expiry, the actual
running revision, the actual permission grant.

Know the blast radius before acting. Who else is served by this thing, and what
happens to them if it is wrong for ten minutes.

Know the rollback before the change. If you cannot say how to undo it, you are not
ready to do it.

## Execution patterns

**direct** — a single reversible operation with a known effect. Do it, confirm
against the live system.

**gated** — the default here. State the change, the blast radius, the verification,
and the rollback. Execute. Confirm live. Most infrastructure work is this shape.

**trajectory** — tuning under observation: capacity, alert thresholds, performance
under real load. Each measurement informs the next adjustment.

## Verification

Confirm against the running system, not the change record. Query the live
resource. Watch the metric move. Exercise the path a user would take.

For access changes, verify both directions: the intended grant works, and the
thing that should still be denied is still denied. A permission change verified
only in the permissive direction is half-tested.

Deployment: verified means the deployed artifact serves the expected response, not
that the pipeline turned green.

## Hazards

- **Irreversible by default.** Deletes, DNS propagation, key rotation, and
  migrations are hard or slow to undo. Snapshot first.
- **Credential exposure.** Secrets belong in a keychain or environment, never in
  the tree, the logs, or a commit message. A leak means rotate and scrub, in that
  order.
- **Silent partial application.** A change that succeeded on three of five nodes
  looks like success. Check the whole set.
- **Verification against your own change record.** The most common false green.
- **Cost.** Provisioning has a bill. Name it before creating it.

## Optional skills

`app-dev` (build and store pipelines) · `ship` (release gating)

Reproduction-first debugging and code-review ceremony do not apply here unless the
operation is implemented as code under review.
