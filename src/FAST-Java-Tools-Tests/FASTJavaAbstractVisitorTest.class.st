Class {
	#name : 'FASTJavaAbstractVisitorTest',
	#superclass : 'TestCase',
	#category : 'FAST-Java-Tools-Tests',
	#package : 'FAST-Java-Tools-Tests'
}

{ #category : 'as yet unclassified' }
FASTJavaAbstractVisitorTest >> getFASTMethodEntityForSource: sourceCode [

	^ (JavaSmaCCProgramNodeImporterVisitor new parseCodeMethodString:
		  sourceCode) allFASTJavaMethodEntity first
]
