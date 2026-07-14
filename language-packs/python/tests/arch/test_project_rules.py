"""Project-specific architecture rules.

`test_dependencies.py` in this directory is framework-owned -- `upgrade`
overwrites it when the shared 5-check parity matrix improves. This file is
never touched by upgrade (seeded once, then yours), so it's the right place
for a project-specific invariant an architecture test can enforce -- e.g.
"module X must not be imported at top level" or "layer Y must not depend on
package Z". Add one `test_*` function per invariant as they come up; there
being nothing here yet is the expected starting state.
"""
from __future__ import annotations


def test_placeholder() -> None:
    """Keeps pytest from erroring on an empty test file; replace as rules are added."""
    assert True
