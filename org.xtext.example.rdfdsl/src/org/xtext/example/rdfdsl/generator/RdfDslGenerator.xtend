/*
 * generated by Xtext 2.24.0
 */
package org.xtext.example.rdfdsl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.AbstractGenerator
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.eclipse.xtext.generator.IGeneratorContext
import org.xtext.example.rdfdsl.rdfDsl.Model
import org.xtext.example.rdfdsl.rdfDsl.Namespace
import org.xtext.example.rdfdsl.rdfDsl.Klass
import org.xtext.example.rdfdsl.rdfDsl.Prop

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class RdfDslGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val model = resource.allContents.filter(Model).next

		fsa.generateFile('model.py', model.generate)
	}

	def dispatch String generate(Model model) '''
		import rdflib as rdf		
		RDF  = rdf.Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
		RDFS = rdf.Namespace('http://www.w3.org/2000/01/rdf-schema#')
		OWL  = rdf.Namespace('http://www.w3.org/2002/07/owl#')
		XSD  = rdf.Namespace('http://www.w3.org/2001/XMLSchema#')
		
		g = rdf.Graph()
		g.bind('rdf' , RDF)
		g.bind('rdfs', RDFS)
		g.bind('owl' , OWL)
		g.bind('xsd' , XSD)
		«FOR n : model.namespaces»
			«n.generate»
		«ENDFOR»
		
		print(g.serialize(format="turtle").decode("utf-8"))
	'''

	def dispatch String generate(Namespace ns) '''
		ns = rdf.Namespace(«ns.link»)
		g.bind('«ns.name»', ns)
		«FOR n : ns.classes»
			«n.generate»
		«ENDFOR»
	'''

	def dispatch String generate(Klass klass) '''
		«IF klass.superClass === null »
			parent = OWL.Class
		«ELSE»
			parent = ns['«klass.superClass»']
		«ENDIF»		
		_class = ns['«klass.name»']
		g.add((_class,«IF klass.superClass === null»RDF.type«ELSE»RDFS.subClassOf«ENDIF», parent))
		«FOR p : klass.properties»
		«p.generate»
		«ENDFOR»
	'''

	def dispatch String generate(Prop prop) '''
		entity = ns['«prop.name»']
		g.add((entity,RDF.type, OWL.ObjectProperty))
		g.add((entity,RDFS.domain, _class))
		g.add((entity,RDFS.range,ns['«prop.type»']))
	'''

}