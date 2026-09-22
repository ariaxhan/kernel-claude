# Tests

`./tests/run-tests.sh` runs every suite (~30s). `./tests/run-tests.sh <suite>` runs one.
`./tests/run-tests.sh --changed` runs only suites whose paths changed (table at the top of the runner).

| Suite | Guards |
|---|---|
| security_hooks | secret detection, auto-approve, fail-closed |
| circuit_breaker | blocking guards never trip the breaker; trip and reset |
| corpus | gates refuse real host payload shapes |
| hooks | hooks/plugin/marketplace JSON, loader schema, session-start smoke |
| runtime_upgrade | upgrade never overwrites user files; failed replace keeps original |
| agentdb | learn, recall, dedup, archive, human_only, decay, SQL injection |
| migrations | schema parity, fresh apply, preflight repair |
| manifest | schemas parse, example validates, missing field rejected, git_diff injection |
| governance | generated files match source, adapters, verdict adjudication |

Only safety and data-integrity tests belong here. Docs, frontmatter and cosmetic checks do not.
