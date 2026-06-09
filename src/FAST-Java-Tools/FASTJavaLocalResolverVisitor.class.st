"
A LocalResolverVisitor for Java

There is actually very little to do, most things are in the FASTCore Local resolver
"
Class {
	#name : 'FASTJavaLocalResolverVisitor',
	#superclass : 'FASTJavaVisitor',
	#instVars : [
		'scoper'
	],
	#category : 'FAST-Java-Tools',
	#package : 'FAST-Java-Tools'
}

{ #category : 'api' }
FASTJavaLocalResolverVisitor >> on: aFASTBehaviouralEntity [

	scoper := FASTLocalResolverScoping new.
	aFASTBehaviouralEntity accept: self
]

{ #category : 'generated' }
FASTJavaLocalResolverVisitor >> visitFASTJavaForEachStatement: aFASTJavaForEachStatement [

	"using the identifier as if it was a variable declaration, which is somewhat the case"
	scoper
		scopeAdd: aFASTJavaForEachStatement fieldname name
		declaration: aFASTJavaForEachStatement fieldname.
	aFASTJavaForEachStatement fieldname localDeclaration:
		aFASTJavaForEachStatement fieldname.
	
	aFASTJavaForEachStatement list accept: self.
	aFASTJavaForEachStatement body accept: self
]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTJavaForStatement: aFASTJavaForStatement [

	aFASTJavaForStatement initializer ifNotNil: [ :node | node accept: self].
	aFASTJavaForStatement condition   ifNotNil: [ :node | node accept: self].
	aFASTJavaForStatement incrementor ifNotNil: [ :node | node accept: self].
	aFASTJavaForStatement body accept: self
]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTJavaParameter: aFASTJavaParameter [
	"register a parameter declaration into the current scope"

	scoper
		scopeAdd: aFASTJavaParameter variable name
		declaration: aFASTJavaParameter.

	aFASTJavaParameter variable localDeclaration: aFASTJavaParameter.

]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTJavaVariableDeclarator: aFASTJavaVariableDeclarator [
	"register a variable (structuralEntity) declaration into the current scope"

	scoper
		scopeAdd: aFASTJavaVariableDeclarator variable name
		declaration: aFASTJavaVariableDeclarator.

	aFASTJavaVariableDeclarator variable localDeclaration:
		aFASTJavaVariableDeclarator.

	"visiting the expression in case it accesses another variable"
	aFASTJavaVariableDeclarator expression ifNotNil: [
		aFASTJavaVariableDeclarator expression accept: self ]
]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTJavaVariableExpression: aFASTJavaVariableExpression [
	"reference to an identifier in the AST that must be bound to its declaration"

	scoper bind: aFASTJavaVariableExpression toLocalDeclaration: aFASTJavaVariableExpression name

]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTTBehaviouralEntity: aFASTBehaviouralEntity [

	aFASTBehaviouralEntity parameters do: [ :param | param accept: self].
	aFASTBehaviouralEntity statementBlock accept: self
]

{ #category : 'visiting' }
FASTJavaLocalResolverVisitor >> visitFASTTStatementBlock: aFASTJavaStatementBlock [
	scoper pushScope.

	"visit order is important to ensure declarations are visited before statements"
	(aFASTJavaStatementBlock statements sorted: [:a :b | a startPos < b startPos])
		do: [ :node | node accept: self ].

	^scoper popScope
]
