package arch;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Automated Clean Architecture layer dependency checks (ArchUnit) plus
 * naming/test-coverage checks that mirror the TypeScript/Python arch-test
 * parity matrix (layer dependency direction, domain purity, no circular
 * refs, file naming, domain file -> test file exists). The build fails on
 * any violation. File-naming (PascalCase) is enforced separately by
 * Checkstyle's TypeName module, not duplicated here.
 */
class DependencyTest {

    private static final String BASE_PACKAGE = "{{BASE_PACKAGE}}";

    private final JavaClasses classes = new ClassFileImporter()
            .importPackages(BASE_PACKAGE);

    @Test
    void domainShouldNotDependOnOtherLayers() {
        // The domain layer must not depend on other layers
        noClasses()
                .that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("..application..", "..infrastructure..", "..presentation..")
                .check(classes);
    }

    @Test
    void applicationShouldNotDependOnInfrastructureOrPresentation() {
        // The application layer must not depend on infrastructure or presentation
        noClasses()
                .that().resideInAPackage("..application..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("..infrastructure..", "..presentation..")
                .check(classes);
    }

    @Test
    void infrastructureShouldNotDependOnPresentation() {
        // The infrastructure layer must not depend on presentation
        noClasses()
                .that().resideInAPackage("..infrastructure..")
                .should().dependOnClassesThat()
                .resideInAPackage("..presentation..")
                .check(classes);
    }

    @Test
    void domainShouldNotDependOnExternalLibraries() {
        // The domain layer may only depend on itself and the JDK
        classes()
                .that().resideInAPackage("..domain..")
                .should().onlyDependOnClassesThat()
                .resideInAnyPackage("..domain..", "java..", "javax..")
                .check(classes);
    }

    @Test
    void layersShouldBeFreeOfCycles() {
        // No circular dependencies between the top-level layer packages
        slices()
                .matching(BASE_PACKAGE + ".(*)..")
                .should().beFreeOfCycles()
                .check(classes);
    }

    @Test
    void domainClassesShouldHaveMatchingTests() {
        String basePackagePath = BASE_PACKAGE.replace('.', '/');
        Path domainDir = Paths.get("src/main/java", basePackagePath, "domain");
        Path testDir = Paths.get("src/test/java", basePackagePath, "domain");

        if (!Files.isDirectory(domainDir)) {
            return;
        }

        List<String> violations = new ArrayList<>();
        try (var stream = Files.list(domainDir)) {
            for (Path file : (Iterable<Path>) stream::iterator) {
                String name = file.getFileName().toString();
                if (!name.endsWith(".java") || name.equals("package-info.java")) {
                    continue;
                }
                String className = name.substring(0, name.length() - ".java".length());
                Path expected = testDir.resolve(className + "Test.java");
                if (!Files.exists(expected)) {
                    violations.add(name + " -> " + testDir.getFileName() + "/" + className + "Test.java missing");
                }
            }
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }

        assertTrue(violations.isEmpty(), violations.size() + " missing test file(s):\n" + String.join("\n", violations));
    }
}
