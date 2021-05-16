package org.xtext.example.rdfdsl.generator

import org.xtext.example.rdfdsl.rdfDsl.CypherQueries
import org.xtext.example.rdfdsl.rdfDsl.Match
import org.xtext.example.rdfdsl.rdfDsl.QueryName
import org.xtext.example.rdfdsl.rdfDsl.CypherQuery
import org.xtext.example.rdfdsl.rdfDsl.Return
import org.xtext.example.rdfdsl.rdfDsl.Node
import org.xtext.example.rdfdsl.rdfDsl.CypherWhere
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.xtext.example.rdfdsl.rdfDsl.CypherRelation
import org.xtext.example.rdfdsl.rdfDsl.Pattern
import org.xtext.example.rdfdsl.rdfDsl.CypherInt
import org.xtext.example.rdfdsl.rdfDsl.CypherString
import org.xtext.example.rdfdsl.rdfDsl.CypherBool
import org.xtext.example.rdfdsl.rdfDsl.CypherDouble
import org.xtext.example.rdfdsl.rdfDsl.Root
import org.eclipse.emf.ecore.resource.Resource
import org.xtext.example.rdfdsl.rdfDsl.Model
import org.xtext.example.rdfdsl.rdfDsl._Class
import org.xtext.example.rdfdsl.rdfDsl._Property
import org.xtext.example.rdfdsl.rdfDsl.Namespace
import org.xtext.example.rdfdsl.rdfDsl.ClassRef
import org.xtext.example.rdfdsl.rdfDsl._Float
import org.xtext.example.rdfdsl.rdfDsl._Integer
import org.xtext.example.rdfdsl.rdfDsl._String
import org.xtext.example.rdfdsl.rdfDsl._Boolean
import org.xtext.example.rdfdsl.rdfDsl.Cardinality
import org.xtext.example.rdfdsl.rdfDsl.Data
import org.xtext.example.rdfdsl.rdfDsl.DataNamespace
import org.xtext.example.rdfdsl.rdfDsl.From
import org.xtext.example.rdfdsl.rdfDsl.Binding
import org.xtext.example.rdfdsl.rdfDsl.PropertyBinding
import org.xtext.example.rdfdsl.rdfDsl.DataProperty
import org.xtext.example.rdfdsl.rdfDsl.CypherProperty
import org.xtext.example.rdfdsl.rdfDsl.Comparison
import org.xtext.example.rdfdsl.rdfDsl.And
import org.xtext.example.rdfdsl.rdfDsl.LessThan
import org.xtext.example.rdfdsl.rdfDsl.Equals
import org.xtext.example.rdfdsl.rdfDsl.GreaterThan
import org.xtext.example.rdfdsl.rdfDsl.GreaterThanOrEquals
import org.xtext.example.rdfdsl.rdfDsl.LessThanOrEquals
import org.xtext.example.rdfdsl.rdfDsl.NotEquals
import org.xtext.example.rdfdsl.rdfDsl.Or
import org.xtext.example.rdfdsl.rdfDsl.Xor
import org.xtext.example.rdfdsl.rdfDsl.ReturnExp
import org.xtext.example.rdfdsl.rdfDsl.Expression
import org.xtext.example.rdfdsl.rdfDsl.Addition
import org.xtext.example.rdfdsl.rdfDsl.Subtraction
import org.xtext.example.rdfdsl.rdfDsl.Modulus
import org.xtext.example.rdfdsl.rdfDsl.Divison
import org.xtext.example.rdfdsl.rdfDsl.Multiplication
import org.xtext.example.rdfdsl.rdfDsl.Identifier

class CypherQueryHelper {

    def void doGenerate(Resource resource, IFileSystemAccess2 fsa) {
        val root = resource.allContents.filter(Root).next
        fsa.generateFile('cypher-query.py', root.generate)
    }

    def static String fixNamespace(
        String link) '''«IF link.replace('"', '').endsWith('#')»«link.replace('"', '')»«ELSE»«link.replace('"', '') + '#'»«ENDIF»'''

    def dispatch String generate(Root it) '''
        import rdflib
        
        graph = rdflib.Graph()
        
        RDF  = rdflib.Namespace('http://www.w3.org/1999/02/22-rdf-syntax-ns#')
        RDFS = rdflib.Namespace('http://www.w3.org/2000/01/rdf-schema#')
        OWL  = rdflib.Namespace('http://www.w3.org/2002/07/owl#')
        XSD  = rdflib.Namespace('http://www.w3.org/2001/XMLSchema#')
        
        graph.bind('rdf', RDF)
        graph.bind('rdfs', RDFS)
        graph.bind('owl', OWL)
        graph.bind('xsd', XSD)
        
        model = «"'''"»
            «model.generate»
        «"'''"»
        graph.parse(data=model, format='turtle')
        
        data = «"'''"»
            «data.generate»
        «"'''"»
        graph.parse(data=data, format='turtle')
        
        «cypherQuery.generate»
    '''

    def dispatch String generate(CypherQueries it) '''
        «FOR query : names»
            «query.generate»
        «ENDFOR»
        
        «FOR query : names»
            [print(r) for r in «query.name»()]
        «ENDFOR»
    '''

    def dispatch String generate(QueryName it) '''
        def «name»():
            a = «"'''"»
            PREFIX : <«namespace»> 
            PREFIX owl: <http://www.w3.org/2002/07/owl#> 
            PREFIX rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> 
            
            «query.generate»
            «"'''"»
            return graph.query(a)
    '''

    def dispatch String generate(CypherQuery it) '''
        SELECT «^return.generate»
        WHERE {
        	«FOR match : match»
        	    «match.generate»
        	«ENDFOR»
        	«FOR where : where»
        	    «where.generate»
        	«ENDFOR»
        }
    '''

    def dispatch String generate(Return it) '''
        «FOR id : ids SEPARATOR ' '»«id.generate»«ENDFOR»
    '''

    def dispatch String generate(ReturnExp it) '''
        «IF newId ===null»
            «id.generate»
        «ELSE»
            («id.generate» AS ?«newId»)
        «ENDIF»
    '''

    def dispatch String generate(Addition it) '''«right.generate»+«left.generate»'''

    def dispatch String generate(Subtraction it) '''«right.generate»+«left.generate»'''

    def dispatch String generate(Modulus it) '''«right.generate»+«left.generate»'''

    def dispatch String generate(Divison it) '''«right.generate»+«left.generate»'''

    def dispatch String generate(Multiplication it) '''«right.generate»*«left.generate»'''

    def dispatch String generate(Match it) '''
        «FOR pattern : from.pattern»
            ?«from.name» «pattern.generate» .
        «ENDFOR»
        «IF to !== null»
            «FOR pattern : to.pattern»
                ?«to.name» «pattern.generate» .
            «ENDFOR»
        «ENDIF»
        «IF from.type !== null»
            ?«from.name» a :«from.type»  .
        «ENDIF»
        «IF to !== null && to.type !== null»
            ?«to.name» a :«to.type» .
        «ENDIF»
        «IF to !== null»
            «from.generate» «relation.generate» «to.generate» . 
        «ENDIF»
    '''

    def dispatch String generate(CypherInt it) '''«value»'''

    def dispatch String generate(CypherDouble it) '''«value»'''

    def dispatch String generate(CypherBool it) '''«value.toLowerCase»'''

    def dispatch String generate(CypherString it) '''"«value»"'''

    def dispatch String generate(Pattern it) ''':«property» «value.generate»'''

    /**
     * TODO: XOR is hard
     */
    def dispatch String generate(CypherWhere it) '''
        «IF operator === null»
            «comparison.generate»
        «ELSEIF operator instanceof And»
            «comparison.generate»
            «otherComparison.generate»
        «ELSEIF operator instanceof Or»
            {
                «comparison.generate»
            } UNION {
                «otherComparison.generate»
            }
        «ELSEIF operator instanceof Xor»
            {
                «comparison.generate»
                MINUS {
                    «otherComparison.generate»
                }
            } UNION {
                «otherComparison.generate»
                MINUS {
                     «comparison.generate»
                }
            }
        «ENDIF»
    '''

    def dispatch String generate(LessThan it) '''<'''

    def dispatch String generate(GreaterThanOrEquals it) '''>='''

    def dispatch String generate(LessThanOrEquals it) '''<='''

    def dispatch String generate(GreaterThan it) '''>'''

    def dispatch String generate(NotEquals it) '''!='''

    def dispatch String generate(Equals it) '''='''

    def dispatch String generate(Identifier it) '''?«identifier.name»'''

    def dispatch String generate(Comparison it) '''
        «IF negation !== null»FILTER NOT EXSITS {«ENDIF»
        «left.generate» ?c«left.identifier.name» .
        FILTER (?c«left.identifier.name» «operator.generate» «right.generate»)
        «IF negation !== null»}«ENDIF»
    '''

    def dispatch String generate(CypherProperty it) '''?«identifier.name» :«property»'''

    def dispatch String generate(Node it) '''?«name»'''

    def dispatch String generate(CypherRelation it) ''':«id»'''

    /******** Model ********/
    def dispatch String generate(Model model) '''
        @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix owl:  <http://www.w3.org/2002/07/owl#> .
        @prefix xsd:  <http://www.w3.org/2001/XMLSchema#> .
        
        «FOR namespace : model.namespaces»
            «namespace.generate»
        «ENDFOR»
    '''

    def dispatch String generate(Namespace it) '''
        @prefix : <«link.fixNamespace»> .
        
        «FOR _class : classes»
            «_class.generate»
        «ENDFOR»
    '''

    def dispatch String generate(^_Class it) '''
        :«name» 
            «IF superClass === null»a owl:Class«ELSE»rdfs:subClassOf :«superClass»«ENDIF» ;
            rdf:label "«name»" .
        
        «FOR property : properties»
            «property.generate(it)»
        «ENDFOR»
    '''

    def String generate(_Property it, _Class _class) '''
        :«name» rdfs:type 
            «IF type instanceof ClassRef»owl:ObjectProperty«ELSE»owl:DataProperty«ENDIF» ;
            rdfs:domain :«_class.name» ;
            rdfs:range «type.generate» .
        
        «IF cardinality !== null»
            «cardinality.generate(_class, it)»
        «ENDIF»
    '''

    def dispatch String generate(ClassRef it) ''':«id»'''

    def dispatch String generate(_Float _) '''xsd:float'''

    def dispatch String generate(_Integer _) '''xsd:integer'''

    def dispatch String generate(_String _) '''xsd:string'''

    def dispatch String generate(_Boolean _) '''xsd:boolean'''

    def String generate(Cardinality it, _Class _class, _Property _property) '''
        :«_class.name» owl:equivalentClass :_«_class.name»_«_property.name»_cardmin .
        :_«_class.name»_«_property.name»_cardmin
            a owl:Restriction ;
            owl:onProperty :«_property.name» ;
            owl:minCardinality «min» .
        «IF max != '*'»
            :«_class.name» owl:equivalentClass :_«_class.name»_«_property.name»_cardmax .
            :_«_class.name»_«_property.name»_cardmax
                a owl:Restriction ;
                owl:onProperty :«_property.name» ;
                owl:minCardinality «max» .
        «ENDIF»
    '''

    /******** Data ********/
    def dispatch String generate(Data it) '''
        «FOR dataNamespace : namespaces»
            «dataNamespace.generate»
        «ENDFOR»        
    '''

    def dispatch String generate(DataNamespace it) '''
        @prefix : <«link.fixNamespace»> .
        «from.generate»
        «FOR binding : bindings»
            «binding.generate»
        «ENDFOR»
        «FOR pbind : propBind»
            «pbind.generate»
        «ENDFOR»
    '''

    def dispatch String generate(From it) '''
        @prefix data: <«importedNs.fixNamespace»> .
    '''

    def dispatch String generate(Binding it) '''
        «FOR variable : varList»
            :«variable» a data:«entity» .
        «ENDFOR»
    '''

    def dispatch String generate(PropertyBinding it) '''
        «FOR property : property»
            «property.generate(it)»
        «ENDFOR»
    '''

    def generate(DataProperty it, PropertyBinding propertyBinding) '''
        «IF value.nullOrEmpty»
            :«propertyBinding.name» data:«prop» «SValue.toLowerCase» .
        «ELSE»
            «FOR value : value»
                :«propertyBinding.name» data:«prop» :«value» .
            «ENDFOR»
        «ENDIF»
    '''

}
