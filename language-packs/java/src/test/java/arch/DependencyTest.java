package arch;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * Clean Architecture 레이어 의존성 자동 검증 (ArchUnit).
 * 위반 시 빌드가 실패합니다.
 */
class DependencyTest {

    private final JavaClasses classes = new ClassFileImporter()
            .importPackages("{{BASE_PACKAGE}}");

    @Test
    void domainShouldNotDependOnOtherLayers() {
        // domain 레이어는 다른 레이어에 의존하지 않는다
        noClasses()
                .that().resideInAPackage("..domain..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("..application..", "..infrastructure..", "..presentation..")
                .check(classes);
    }

    @Test
    void applicationShouldNotDependOnInfrastructureOrPresentation() {
        // application 레이어는 infrastructure·presentation에 의존하지 않는다
        noClasses()
                .that().resideInAPackage("..application..")
                .should().dependOnClassesThat()
                .resideInAnyPackage("..infrastructure..", "..presentation..")
                .check(classes);
    }

    @Test
    void infrastructureShouldNotDependOnPresentation() {
        // infrastructure 레이어는 presentation에 의존하지 않는다
        noClasses()
                .that().resideInAPackage("..infrastructure..")
                .should().dependOnClassesThat()
                .resideInAPackage("..presentation..")
                .check(classes);
    }
}
