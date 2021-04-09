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
import org.xtext.example.rdfdsl.rdfDsl._Class
import org.xtext.example.rdfdsl.rdfDsl._Property
import org.xtext.example.rdfdsl.rdfDsl.Cardinality
import org.xtext.example.rdfdsl.rdfDsl._Float
import org.xtext.example.rdfdsl.rdfDsl._Integer
import org.xtext.example.rdfdsl.rdfDsl._String
import org.xtext.example.rdfdsl.rdfDsl._Boolean
import org.xtext.example.rdfdsl.rdfDsl.ClassRef
import org.xtext.example.rdfdsl.rdfDsl.Data
import org.xtext.example.rdfdsl.rdfDsl.Root
import org.xtext.example.rdfdsl.rdfDsl.Query
import org.xtext.example.rdfdsl.rdfDsl.DataNamespace
import org.xtext.example.rdfdsl.rdfDsl.From
import org.xtext.example.rdfdsl.rdfDsl.Binding
import org.xtext.example.rdfdsl.rdfDsl.PropertyBinding
import org.xtext.example.rdfdsl.rdfDsl.DataProperty
import org.xtext.example.rdfdsl.rdfDsl.Select
import org.xtext.example.rdfdsl.rdfDsl.Where
import org.xtext.example.rdfdsl.rdfDsl.Triple
import org.xtext.example.rdfdsl.rdfDsl.Predicate
import org.xtext.example.rdfdsl.rdfDsl.QueryObject
import org.xtext.example.rdfdsl.rdfDsl.QueryID
import org.xtext.example.rdfdsl.rdfDsl.QueryLiteral

/**
 * Generates code from your model files on save.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#code-generation
 */
class RdfDslGenerator extends AbstractGenerator {

	override void doGenerate(Resource resource, IFileSystemAccess2 fsa, IGeneratorContext context) {
		val root = resource.allContents.filter(Root).next
		root.model !== null ? fsa.generateFile('model.py', root.model.generate)
		root.data !== null ? fsa.generateFile('data.py', root.data.generate)
		root.query !== null ? fsa.generateFile('query.py', root.query.generate)
	}

	def dispatch String generate(Query query) '''
		import rdflib as rdf
		query =[
		«FOR select : query.select»
			«select.generate»,
		«ENDFOR»
		]
		g = rdf.Graph()
		g.parse("temp.ttl", format="turtle")
		for q in query:
		    k = g.query(q)
		    for l in k:
		        print(l)
	'''

	def dispatch String generate(Select select) '''
		«"'''"»
		SELECT«FOR single : select.selectList» ?«single»«ENDFOR»
		«select.where.generate»
		«"'''"»
	'''

	def dispatch String generate(Where where) '''
		WHERE {
			«FOR trip : where.constraintList»
				«trip.generate»
			«ENDFOR»
		}
	'''

	def dispatch String generate(Triple trip) '''
		?«trip.subject» «trip.predicate.generate» «trip.object.generate» .
	'''

	def dispatch String generate(QueryID queryID) '''?«queryID.id»'''

	def dispatch String generate(QueryLiteral queryLit) '''"«queryLit.id»"'''

	def dispatch String generate(Predicate pred) '''«pred.namespace»:«pred.property»'''

	def dispatch String generate(Data data) '''
		import rdflib as rdf
		RDF  = rdf.Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
		RDFS = rdf.Namespace('http://www.w3.org/2000/01/rdf-schema#')
		OWL  = rdf.Namespace('http://www.w3.org/2002/07/owl#')
		XSD  = rdf.Namespace('http://www.w3.org/2001/XMLSchema#')
		g = rdf.Graph()
		g.parse("temp.ttl", format='turtle')
		
		«FOR dataNamespace : data.namespaces»
			«dataNamespace.generate»
		«ENDFOR»
		
		g.serialize("temp.ttl", 'turtle')
	'''

	def dispatch String generate(DataNamespace dataNs) '''
		«IF dataNs.link.replace('"', '').endsWith('#')»		
			dns = rdf.Namespace(«dataNs.link»)
		«ELSE»
			dns = rdf.Namespace("«dataNs.link.replace('"', '')+"#"»")
		«ENDIF»
		g.bind('«dataNs.name»', dns)
		
		«dataNs.from.generate»
		
		«FOR bind : dataNs.bindings»
			«bind.generate»
		«ENDFOR»
		
		«FOR pbind : dataNs.propBind»
			«pbind.generate»
		«ENDFOR»
		
	'''

	def dispatch String generate(PropertyBinding pbind) '''
		current = «pbind.name»
		«FOR dprop : pbind.property»
			«dprop.generate»
		«ENDFOR»
	'''

	def dispatch String generate(DataProperty dprop) '''
		«IF dprop.value.nullOrEmpty»
			g.add( (current, «dprop.prop», rdf.Literal(«dprop.SValue»)) )
		«ELSE»
			«FOR _val : dprop.value»
				g.add( (current, «dprop.prop», «_val») )
			«ENDFOR»
		«ENDIF»
	'''

	def dispatch String generate(From from) '''
		«IF from.importedNs.replace('"', '').endsWith('#')»		
			ins = rdf.Namespace(«from.importedNs»)
		«ELSE»
			ins = rdf.Namespace("«from.importedNs.replace('"', '')+"#"»")
		«ENDIF»
		«FOR prop : from.listProp»
			«prop» = ins['«prop»']
		«ENDFOR»
	'''

	def dispatch String generate(Binding binding) '''
		«FOR _var : binding.varList»
			«_var» = dns["«_var»"]
			g.add( («_var», RDF.type, «binding.entity») )
		«ENDFOR»
		
	'''

	def dispatch String generate(Model model) '''
		import rdflib as rdf		
		RDF  = rdf.Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
		RDFS = rdf.Namespace('http://www.w3.org/2000/01/rdf-schema#')
		OWL  = rdf.Namespace('http://www.w3.org/2002/07/owl#')
		XSD  = rdf.Namespace('http://www.w3.org/2001/XMLSchema#')
		
		g = rdf.Graph()
		g.bind('rdf', RDF)
		g.bind('rdfs', RDFS)
		g.bind('owl', OWL)
		g.bind('xsd', XSD)
		
		«FOR namespace : model.namespaces»
			«namespace.generate»
		«ENDFOR»
		
		print(g.serialize(format="turtle").decode("utf-8"))
		g.serialize("temp.ttl", 'turtle')
	'''

	def dispatch String generate(Namespace namespace) '''
		«IF namespace.link.replace('"', '').endsWith('#')»		
			ns = rdf.Namespace(«namespace.link»)
		«ELSE»
			ns = rdf.Namespace("«namespace.link.replace('"', '')+"#"»")
		«ENDIF»
		g.bind('«namespace.name»', ns)
		
		«FOR _class : namespace.classes»
			«_class.generate»
		«ENDFOR»
	'''

	def dispatch String generate(_Class _class) '''
		«IF _class.superClass === null»
			parent = OWL.Class
			_type = RDF.type
		«ELSE»
			parent = ns['«_class.superClass»']
			_type = RDFS.subClassOf
		«ENDIF»		
		_class = ns['«_class.name»']
		g.add((_class, _type, parent))
		
		g.add((_class, RDF['label'], rdf.Literal('«_class.name»')))
		
		«FOR property : _class.properties»
			«property.generate»
		«ENDFOR»
	'''

	def dispatch String generate(_Property property) '''
		prop = ns['«property.name»']
		prop_type = «IF property.type instanceof ClassRef»OWL.ObjectProperty«ELSE»OWL.DataProperty«ENDIF»
		g.add((prop, RDF.type, prop_type))
		g.add((prop, RDFS.domain, _class))
		g.add((prop, RDFS.range, «property.type.generate»))
		
		«IF property.cardinality !== null»
			«property.cardinality.generate»
		«ENDIF»
	'''

	def dispatch String generate(Cardinality cardinality) '''
		cardmin_entity = ns['_%s_%s_cardmin' % (_class.split('#')[-1], prop.split('#')[-1])]
		g.add( (_class, OWL.equivalentClass, cardmin_entity) )
		g.add( (cardmin_entity, RDF.type, OWL.Restriction) )
		g.add( (cardmin_entity, OWL.onProperty, prop) )
		g.add( (cardmin_entity, OWL.minCardinality, rdf.Literal(«cardinality.min», datatype=XSD.integer)) )
		
		«IF cardinality.max != '*'»
			cardmax_entity = ns['_%s_%s_cardmax' % (_class.split('#')[-1], prop.split('#')[-1])]
			g.add( (_class, OWL.equivalentClass, cardmax_entity) )
			g.add( (cardmax_entity, RDF.type, OWL.Restriction) )
			g.add( (cardmax_entity, OWL.onProperty, prop) )
			g.add( (cardmax_entity, OWL.maxCardinality, rdf.Literal(«cardinality.max», datatype=XSD.integer)) )
		«ENDIF»
		
	'''

	def dispatch String generate(_Float type) '''XSD.float'''

	def dispatch String generate(_Integer type) '''XSD.integer'''

	def dispatch String generate(_String type) '''XSD.string'''
	
	def dispatch String generate(_Boolean type) '''XSD.boolean'''

	def dispatch String generate(ClassRef type) '''ns['«type.id»']'''

}
