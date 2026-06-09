Class {
	#name : 'FASTJavaSSAVisitor',
	#superclass : 'FASTJavaVisitor',
	#instVars : [
		'variableVersions',
		'isBeingAssigned'
	],
	#category : 'FAST-Java-Tools',
	#package : 'FAST-Java-Tools'
}

{ #category : 'visiting' }
FASTJavaSSAVisitor class >> on: anAST [

	^self new
		on: anAST 
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> assignmentVariableVersion: aFASTJavaVariableExpression [

	^(self createVariableVersion: aFASTJavaVariableExpression)
		newVersionNumber;
		yourself
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> createVariableVersion: aFASTJavaVariableExpression [

	| newSSA |
	newSSA := FASTVariableVersionSSA for: aFASTJavaVariableExpression.
	aFASTJavaVariableExpression localDeclaration activeVersion
		ifNotNil: [ :lastSSA | newSSA version: lastSSA version ].
	
	aFASTJavaVariableExpression localDeclaration activeVersion: newSSA.
	
	variableVersions add: aFASTJavaVariableExpression localDeclaration.

	^newSSA 
]

{ #category : 'initialization' }
FASTJavaSSAVisitor >> initialize [

	super initialize.

	isBeingAssigned := false
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> notAssigned: aBlock [
	"turn inAssignment to false during evaluation of aBlock, then turn it back to what it was"

	| wasAssignment |
	wasAssignment := isBeingAssigned.
	isBeingAssigned := false.

	aBlock value.

	isBeingAssigned := wasAssignment 
]

{ #category : 'api' }
FASTJavaSSAVisitor >> on: anAST [

	FASTJavaLocalResolverVisitor new on: anAST.

	variableVersions := Set new.

	anAST accept: self.

	^ anAST
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> threeWaysPhiVersions: preVersions branch1: branch1 branch2: branch2 [
	"compares the current versions of variables (in #branch1 and branch2) with the one that were
	 before the conditional statement (#preVersion)
	 If there is a difference, conditional created a new version and we need to create a
	 phi function joining the versin before (it may not exist) with the new version"

	| only1 only2 |
	
	only1 := self variableVersionsIn: branch1 notIn: branch2.
	only2 := self variableVersionsIn: branch2 notIn: branch1.

	self twoWaysPhiVersions: preVersions  branch: only1.
	self twoWaysPhiVersions: preVersions  branch: only2.

	self twoWaysPhiVersions: (branch1 difference: only1) branch: (branch2 difference: only2)
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> twoWaysPhiVersions: preVersions branch: branch [
	"compares the current versions of variables (in #variableVersions) with the one that were
	 before (the conditional statement)
	 If there is a difference, conditional created a new version and we need to create a
	 phi function joining the versin before (it may not exist) with the new version"
	| phi |

	branch do: [ :newVersion |
		(preVersions includes: newVersion) 
			ifFalse: [
				phi := FASTVariablePhiVersionSSA for:
					(preVersions
						detect: [ :previousVersion | previousVersion sameVariableAs: newVersion ]
						ifOne: [ :previousVersion | { previousVersion . newVersion } ]
						ifNone: [ { newVersion } ]).

				newVersion localDeclaration activeVersion: phi]
	]
]

{ #category : 'visiting - statements' }
FASTJavaSSAVisitor >> updateSSAValuesOfLoopBody: body forVariable: vv [

	| localUses lastVersion |
	localUses := vv localUses.
	lastVersion := vv activeVersion.

	localUses do: [ :lu |
			(lu allContainers includes: body) ifTrue: [
					lu containers first class = FASTJavaAssignmentExpression
						ifTrue: [
								lu containers first variable = lu
									ifTrue: [ lastVersion := lu ssaVersion ]
									ifFalse: [ lu ssaVersion: lastVersion ] ]
						ifFalse: [ lu ssaVersion: lastVersion ] ] ]
]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> useVariableVersion: aFASTFortranVariable [

	^aFASTFortranVariable localDeclaration activeVersion
		ifNil: [ self createVariableVersion: aFASTFortranVariable ]

]

{ #category : 'private - ssa' }
FASTJavaSSAVisitor >> variableVersionsIn: versions1 notIn: versions2 [

	^versions1 select: [ :v1 |
		versions2 noneSatisfy: [ :v2 |
			v1 sameVariableAs: v2
		]
	]
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaAssignmentExpression: aFASTJavaAssignmentExpression [
	
	aFASTJavaAssignmentExpression expression accept: self.
	
	isBeingAssigned := true.
	aFASTJavaAssignmentExpression variable accept: self.
	isBeingAssigned := false
	
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaForEachStatement: aFASTJavaForEachStatement [
	| preVersions forVersions |
	
	"treating the fieldname (an identifier) as a variable that is being assigned"
	aFASTJavaForEachStatement fieldname ssaVersion:
					(self assignmentVariableVersion: aFASTJavaForEachStatement fieldname).
	
	aFASTJavaForEachStatement list accept: self.
	preVersions := variableVersions collect: #activeVersion.
	
	aFASTJavaForEachStatement body accept: self.

	forVersions := variableVersions collect: #activeVersion.
	self twoWaysPhiVersions: preVersions branch: forVersions.

	FASTJavaSSALoopUpdaterVisitor new revisitLoopBody:
		aFASTJavaForEachStatement body
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaForStatement: aFASTJavaForStatement [

	| preVersions forVersions |
	aFASTJavaForStatement initializer ifNotNil: [
		aFASTJavaForStatement initializer accept: self ].
	preVersions := variableVersions collect: #activeVersion.

	aFASTJavaForStatement body accept: self.
	aFASTJavaForStatement incrementor accept: self.

	forVersions := variableVersions collect: #activeVersion.
	self twoWaysPhiVersions: preVersions branch: forVersions.
	
	aFASTJavaForStatement condition accept: self.

	FASTJavaSSALoopUpdaterVisitor new revisitLoopBody:
		aFASTJavaForStatement body
]

{ #category : 'visiting - statements' }
FASTJavaSSAVisitor >> visitFASTJavaIfStatement: aFASTJavaIfStatement [
	"For conditional statements, we record the variableVersions before the conditional and compare
	 them to versions after the conditional.
	 If there is a difference, we create phiVersions for them after the statement"

	| preVersions afterThen afterElse |

	aFASTJavaIfStatement condition accept: self.

	preVersions := variableVersions collect: #activeVersion.
	aFASTJavaIfStatement thenPart accept: self.
	afterThen := variableVersions collect: #activeVersion.

	aFASTJavaIfStatement elsePart
		ifNotNil: [ :elseBlock |
			elseBlock accept: self.
			afterElse := variableVersions collect: #activeVersion ]
		ifNil: [ afterElse := #(  ) ].

	self
		threeWaysPhiVersions: preVersions
		branch1: afterThen
		branch2: afterElse
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaParameter: aFASTJavaParameter [
	
	isBeingAssigned := true.
	aFASTJavaParameter variable accept: self.
	isBeingAssigned := false
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaUnaryExpression: aFASTJavaUnaryExpression [

	"this is less than ideal, but we can't have a fully precise representation of unary expressions unless we desugarize them (and turn them into non unary expressions...)"
	({ '++'. '--' } includes: aFASTJavaUnaryExpression operator)
		ifTrue: [
				isBeingAssigned := true.
				aFASTJavaUnaryExpression expression accept: self.
				isBeingAssigned := false ]
		ifFalse: [ aFASTJavaUnaryExpression expression accept: self ]
]

{ #category : 'generated' }
FASTJavaSSAVisitor >> visitFASTJavaVariableDeclarator: aFASTJavaVariableDeclarator [

	"if a variable is declared but not instantiated, we do not create a version for it"
	aFASTJavaVariableDeclarator expression ifNil: [ ^ self ].

	isBeingAssigned := true.
	aFASTJavaVariableDeclarator variable accept: self.
	isBeingAssigned := false.

	^ aFASTJavaVariableDeclarator expression accept: self
]

{ #category : 'visiting expression' }
FASTJavaSSAVisitor >> visitFASTJavaVariableExpression: aFASTJavaVariableExpression [

	isBeingAssigned
		ifTrue: [
				aFASTJavaVariableExpression ssaVersion:
					(self assignmentVariableVersion: aFASTJavaVariableExpression) ]
		ifFalse: [
				"If we don't assign and the declaration is not local, then we probably don't need to do SSA on this expression."
				"It might be wrong (and I feel like I can think of an example where it is), I will update it when needed."
				aFASTJavaVariableExpression localDeclaration isNonLocalDeclaration
					ifFalse: [
							aFASTJavaVariableExpression ssaVersion:
								(self useVariableVersion: aFASTJavaVariableExpression) ] ]
]

{ #category : 'visiting - statements' }
FASTJavaSSAVisitor >> visitFASTJavaWhileStatement: aFASTJavaWhileStatement [
	"For conditional statements, we record the variableVersions before the conditional and compare
	 them to versions after the conditional.
	 If there is a difference, we create phiVersions for them after the statement"

	| preVersions bodyVersions |
	preVersions := variableVersions collect: #activeVersion.
	aFASTJavaWhileStatement body accept: self.
	bodyVersions := variableVersions collect: #activeVersion.

	self twoWaysPhiVersions: preVersions branch: bodyVersions.

	"variableVersions do: [ :vv | self updateSSAValuesOfLoopBody: aFASTJavaWhileStatement body forVariable: vv ]."
	FASTJavaSSALoopUpdaterVisitor new revisitLoopBody:
		aFASTJavaWhileStatement body.

	aFASTJavaWhileStatement condition accept: self
]

{ #category : 'visiting - programUnits' }
FASTJavaSSAVisitor >> visitParameter: aFASTFortranScalarVariable [
	"Parameters are considered assigned on call"

	aFASTFortranScalarVariable ssaVersion: (self assignmentVariableVersion: aFASTFortranScalarVariable )
]
