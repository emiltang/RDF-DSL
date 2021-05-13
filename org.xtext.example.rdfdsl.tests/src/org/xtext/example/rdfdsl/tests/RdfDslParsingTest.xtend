package org.xtext.example.rdfdsl.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.xtext.example.rdfdsl.rdfDsl.Root
import org.eclipse.xtext.xbase.testing.CompilationTestHelper
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.io.BufferedReader
import java.io.InputStreamReader
import java.io.BufferedWriter
import java.io.OutputStreamWriter

/**
 * https://www.eclipse.org/forums/index.php/t/326416/
 * https://dietrich-it.de/xtext/2012/05/08/unittesting-xtend-generators/
 */
@ExtendWith(InjectionExtension)
@InjectWith(RdfDslInjectorProvider)
class RdfDslParsingTest {

    @Inject extension CompilationTestHelper

    @Inject
    ParseHelper<Root> parseHelper

    @Inject IGenerator2 generator

    @Test
    def void loadModel() {
        val result = parseHelper.parse('''
            model namespace uni "http://sdu.dk"
            	class Student
            		property amountOfGlasses Integer
            				cardinality 0 .. *
            			property hasGlasses Boolean
            			property hasName String
            			property hasCourse String
            	class Engineer : Student
            	class Mathematician: Student
        ''')
        Assertions::assertNotNull(result)
        val errors = result.eResource.errors
        Assertions::assertTrue(errors.isEmpty, '''Unexpected errors: «errors.join(", ")»''')
    }

    @Test
    def void test() {
        val dsl = '''
            model 
            	namespace uni "http://sdu.dk"
            		class Student
            			property hasName String
            		class Engineer : Student
            data
                namespace group "http://MDSD.dk/our_group_data#"
                from "http://sdu.dk#" [ hasName, Engineer, ]
                
                emil is Engineer
                
                emil:
                    hasName "Emil" 
            CypherQuery
                myquery"http://sdu.dk#"
                    MATCH (ee :Engineer {hasName:"emil"})
                    RETURN ee; 
        '''
        dsl.assertCompilesTo('''asd''')
    }

    @Test
    def void test_simple_cypher_match() {
        val result = parseHelper.parse('''
            model 
                namespace uni "http://sdu.dk"
                    class Student
                        property hasName String
                    class Engineer : Student
            data
                namespace group "http://MDSD.dk/our_group_data#"
                from "http://sdu.dk#" [ hasName, Engineer ]
                    emil is Engineer
                    emil:
                        hasName "Emil" 
            CypherQuery
                myquery"http://sdu.dk#"
                    MATCH (e :Engineer {hasName:"emil"})
                    RETURN e; 
        ''')
        val fsa = new InMemoryFileSystemAccess()
        generator.doGenerate(result.eResource, fsa, null);
        Assertions::assertTrue(fsa.allFiles.containsKey(IFileSystemAccess2::DEFAULT_OUTPUT + "cypher-query.py"))

        val CharSequence file = fsa.textFiles.get(IFileSystemAccess2::DEFAULT_OUTPUT + "cypher-query.py")

        val builder = new ProcessBuilder("python");
        builder.redirectErrorStream(true)
        val process = builder.start

        val response = new StringBuffer();

        try (val stdin = new BufferedWriter(new OutputStreamWriter(process.outputStream))) {
            stdin.write(file.toString)
        }
        try (
            val stdout = new BufferedReader(new InputStreamReader(process.inputStream));
        ) {
            var String m
            while ((m = stdout.readLine()) !== null) {
                response.append(m)
            }
        }
        Assertions::assertEquals(1, response.toString.lines.count)
        Assertions::assertTrue(response.toString.contains("emil"))
    }
}
