Extension { #name : 'FASTJavaParameter' }

{ #category : '*FAST-Java-Tools' }
FASTJavaParameter >> activeVersion [

	^self attributeAt: #activeVersion ifAbsent: [ nil ]
]

{ #category : '*FAST-Java-Tools' }
FASTJavaParameter >> activeVersion: aSSAVersion [

	^self attributeAt: #activeVersion put: aSSAVersion
]

{ #category : '*FAST-Java-Tools' }
FASTJavaParameter >> localDeclarationName [
	^ variable localDeclarationName
]
