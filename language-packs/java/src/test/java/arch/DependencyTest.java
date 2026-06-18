package arch;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Automated Clean Architecture layer dependency checks (ArchUnit).
 * The build fails on any violation.
 */
class DependencyTest {

    private final JavaClasses classes = new ClassFileImporter()
            .importPackages("{{BASE_PACKAGE}}");

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
}
