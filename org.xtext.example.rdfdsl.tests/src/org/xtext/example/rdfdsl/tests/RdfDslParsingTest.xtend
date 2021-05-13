package org.xtext.example.rdfdsl.tests

import com.google.inject.Inject
import org.eclipse.xtext.testing.InjectWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.util.ParseHelper
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.^extension.ExtendWith
import org.xtext.example.rdfdsl.rdfDsl.Model
import org.xtext.example.rdfdsl.rdfDsl.Root
import org.eclipse.xtext.xbase.testing.CompilationTestHelper
import org.eclipse.xtext.generator.InMemoryFileSystemAccess
import org.xtext.example.rdfdsl.generator.RdfDslGenerator
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.generator.IGenerator2
import org.eclipse.xtext.generator.IFileSystemAccess2
import java.io.BufferedInputStream
import java.io.BufferedReader
import java.io.InputStreamReader

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
		println(result)
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
						property amountOfGlasses Integer
							cardinality 0 .. *
						property hasGlasses Boolean
						property hasName String
						property hasCourse String
					class Engineer : Student
					class Mathematician: Student
			query 
				from uni "http://sdu.dk#"
				from people "http://MDSD.dk/our_group_data#"
				qname1
					SELECT name
					WHERE
						student uni:hasCourse "V&V"
						student uni:hasName name
		'''
		dsl.assertCompilesTo('''asd''')
	}

	@Test
	def void test2() {
		val result = parseHelper.parse('''
		model 
				namespace uni "http://sdu.dk"
					class Student
						property amountOfGlasses Integer
							cardinality 0 .. *
						property hasGlasses Boolean
						property hasName String
						property hasCourse String
					class Engineer : Student
					class Mathematician: Student
			query 
				from uni "http://sdu.dk#"
				from people "http://MDSD.dk/our_group_data#"
				qname1
					SELECT name
					WHERE
						student uni:hasCourse "V&V"
						student uni:hasName name
		''')
		println(result)
		val fsa = new InMemoryFileSystemAccess()
		generator.doGenerate(result.eResource, fsa, null);
		Assertions::assertTrue(fsa.allFiles.containsKey(IFileSystemAccess2::DEFAULT_OUTPUT + "model.py"))
			
		val process = Runtime.runtime.exec('''python -c «fsa.allFiles.get(IFileSystemAccess2::DEFAULT_OUTPUT + "model.py")»''')
		
		val err = new BufferedReader(new InputStreamReader(process.errorStream))
		var String e
		while ((e = err.readLine()) !== null) {
			println(e)
		}
		
		val in = new BufferedReader(new InputStreamReader(process.inputStream))
		var String m 
		while ((m = in.readLine()) !== null) {
			println(m)
		}
	}
}
