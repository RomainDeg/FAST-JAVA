Extension { #name : 'FASTNonLocalDeclaration' }

{ #category : '*FAST-Java-Tools' }
FASTNonLocalDeclaration >> activeVersion [ 

	^ self firstUse activeVersion 
]

{ #category : '*FAST-Java-Tools' }
FASTNonLocalDeclaration >> activeVersion: aSSAVersion [

	^self firstUse activeVersion: aSSAVersion
]

{ #category : '*FAST-Java-Tools' }
FASTNonLocalDeclaration >> firstUse [ 

	^ self localUses first
]
