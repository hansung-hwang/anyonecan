package arch;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Project-specific architecture rules.
 *
 * {@code DependencyTest.java} in this directory is framework-owned -- {@code upgrade}
 * overwrites it when the shared 5-check parity matrix improves. This file is never
 * touched by upgrade (seeded once, then yours), so it's the right place for a
 * project-specific invariant an architecture test can enforce -- e.g. "module X must
 * not be imported at top level" or "layer Y must not depend on package Z". Add one
 * {@code @Test} method per invariant as they come up; there being nothing here yet is
 * the expected starting state.
 */
class ProjectRulesTest {

    @Test
    void placeholder() {
        // Keeps the test class from being empty; replace as rules are added.
        assertTrue(true);
    }
}
