# Initial checks of other task types

[Overview](../README.md) · [Reproduce](reproduce.md)

These checks explore how other MiMo environments run and score work. **None demonstrates a false pass.** Task counts describe the dataset, not the number tested.

| Task type (MiMo name) | Dataset tasks | What was checked | What remains unknown |
| --- | --- | --- | --- |
| Security tasks (`Cyber`) | 1,000 | On image `arvo-v1-35858`, only root could create `/root/last_result.json`, which the grader reads. The `agent` and `verify` users could not. | Whether another route could influence the score |
| Tasks scored against criteria (`Rubric`) | 925 | On one image, a Python startup file in the shared workspace did not run. A system-directory file ran only in that same container. | Whether agent changes could reach the actual verifier, which runs in a separate container |
| Website tasks (`Webdev`) | 2,093 | On one image, page JavaScript ran in Chromium during a local Playwright browser check. | No visual evaluation score was measured |
| Music tasks (`Music`) | 1,000 | No experiment; no task image was available in the inspected dataset. | Untested |

The rubric check used a small replacement `run_verify.py` to test Python startup behavior, not a full task evaluation. The website check changed the page title and text; page JavaScript running is expected browser behavior and does not by itself show a grading bypass.

[Saved evidence](../evidence/preliminary-checks/) also includes an early Python-startup check on a coding image. Its results are separate from the [confirmed coding experiments](coding-results.md).
