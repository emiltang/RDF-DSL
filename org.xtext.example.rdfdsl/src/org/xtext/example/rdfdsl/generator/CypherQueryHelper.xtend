package org.xtext.example.rdfdsl.generator

import org.xtext.example.rdfdsl.rdfDsl.CypherQueries
import org.xtext.example.rdfdsl.rdfDsl.Match
import org.xtext.example.rdfdsl.rdfDsl.QueryName
import org.xtext.example.rdfdsl.rdfDsl.CypherQuery
import org.xtext.example.rdfdsl.rdfDsl.Return
import org.xtext.example.rdfdsl.rdfDsl.Where
import org.xtext.example.rdfdsl.rdfDsl.Node
import javax.management.relation.Relation
import org.xtext.example.rdfdsl.rdfDsl.CypherWhere
import org.eclipse.xtext.generator.IFileSystemAccess2
import org.xtext.example.rdfdsl.rdfDsl.CypherRelation
import org.xtext.example.rdfdsl.rdfDsl.Pattern
import org.xtext.example.rdfdsl.rdfDsl.CypherInt
import org.xtext.example.rdfdsl.rdfDsl.CypherString
import org.xtext.example.rdfdsl.rdfDsl.CypherBool
import org.xtext.example.rdfdsl.rdfDsl.CypherDouble

class CypherQueryHelper {

	def void doGenerate(CypherQueries cypherQueries, IFileSystemAccess2 fsa) {
		fsa.generateFile('cypher-query.py', cypherQueries.generate)
	}

	def dispatch String generate(CypherQueries it) '''
		«FOR name : names»
			«name.generate»
		«ENDFOR»
	'''

	def dispatch String generate(QueryName it) '''
		PREFIX : <«namespace»>
		«query.generate»
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
		«FOR id : ids SEPARATOR ' '»?«id»«ENDFOR»
	'''

	def dispatch String generate(Match it) '''
		«FOR pattern : from.pattern»
			?«from.identifier» «pattern.generate».
		«ENDFOR»
		«FOR pattern : to.pattern»
			?«from.identifier» «pattern.generate».
		«ENDFOR»
		«IF from.type !== null»?«from.identifier» owl:class «from.type».«ENDIF»
		«IF to.type !== null»?«to.identifier» owl:class «to.type».«ENDIF»
		«from.generate» «relation.generate» «to.generate». 
	'''

	def dispatch String generate(CypherInt it) '''«value»'''
	
	def dispatch String generate(CypherDouble it) '''«value»'''
	

	def dispatch String generate(CypherBool it) '''«value.toLowerCase»'''

	def dispatch String generate(CypherString it) '''"«value»"'''

	def dispatch String generate(Pattern it) ''':«property» «value.generate»'''

	def dispatch String generate(CypherWhere it) '''
		«IF negation === null»
			?«identifier» :«property» «string».
		«ELSE»
			FILTER NOT EXSITS {
				?«identifier» :«property» "«string»".
			}
		«ENDIF»
	'''

	def dispatch String generate(Node it) '''?«identifier»'''

	def dispatch String generate(CypherRelation it) ''':«id»'''

}
