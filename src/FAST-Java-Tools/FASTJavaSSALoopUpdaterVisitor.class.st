Class {
	#name : 'FASTJavaSSALoopUpdaterVisitor',
	#superclass : 'FASTJavaSSAVisitor',
	#instVars : [
		'assignmentFound'
	],
	#category : 'FAST-Java-Tools',
	#package : 'FAST-Java-Tools'
}

{ #category : 'as yet unclassified' }
FASTJavaSSALoopUpdaterVisitor >> revisitLoopBody: aStatementBlock [

	assignmentFound := Set new.
	
	aStatementBlock accept: self
]

{ #category : 'generated' }
FASTJavaSSALoopUpdaterVisitor >> visitFASTJavaAssignmentExpression: aFASTJavaAssignmentExpression [
	
	aFASTJavaAssignmentExpression expression accept: self.
	
	"we keep the newly assigned variable to ensure that only replace the ssa value"
	assignmentFound add: aFASTJavaAssignmentExpression variable localDeclaration
	
]

{ #category : 'generated' }
FASTJavaSSALoopUpdaterVisitor >> visitFASTJavaParameter: aFASTJavaParameter [
	^ self visitFASTTVariableExpression: aFASTJavaParameter
]

{ #category : 'visiting expression' }
FASTJavaSSALoopUpdaterVisitor >> visitFASTJavaVariableExpression: aFASTJavaVariableExpression [

	(assignmentFound includes:
		 aFASTJavaVariableExpression localDeclaration) ifFalse: [
			aFASTJavaVariableExpression localDeclaration isNonLocalDeclaration
				ifFalse: [
						aFASTJavaVariableExpression ssaVersion:
							(self useVariableVersion: aFASTJavaVariableExpression) ] ]
]
