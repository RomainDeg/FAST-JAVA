"
A FASTFortranSSAVisitorTest is a test class for testing the behavior of FASTFortranSSAVisitor
"
Class {
	#name : 'FASTJavaSSAVisitorTest',
	#superclass : 'FASTJavaAbstractVisitorTest',
	#instVars : [
		'visitor',
		'ssa',
		'ast'
	],
	#category : 'FAST-Java-Tools-Tests',
	#package : 'FAST-Java-Tools-Tests'
}

{ #category : 'running' }
FASTJavaSSAVisitorTest >> newVisitor [

	^ FASTJavaSSAVisitor new
]

{ #category : 'running' }
FASTJavaSSAVisitorTest >> runVisitor [

	^ ssa := visitor on: ast
]

{ #category : 'running' }
FASTJavaSSAVisitorTest >> setUp [
	super setUp.

	visitor := self newVisitor
]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testFieldAccessAssignement [
	"
	SUBROUTINE something()
	p.x = 6
	END
	"

	| source varAccess |
	source := 'public void something() { 
		p.x = 5;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.
	
	
	"can we do better? the 'x' field isn't a node of its own"
	varAccess := ssa statementBlock statements first expression variable.
	self assert: varAccess type ssaName equals: 'p_1'

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testFor [

	| source loopStmt varAccess |
	
	source := 'public void forMethod() {
		for (int i = 0; i < 5; i++) {
  			System.out.println(i);
		}
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	loopStmt := ssa statementBlock statements first.	
	varAccess := loopStmt initializer declarators first variable.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'i_1'.
	
	varAccess := loopStmt incrementor expression expression.	
	self assert: varAccess ssaName equals: 'i_2'.
	"We need to remove the syntactic sugar, as this expression should both be i_2 and phi(i_1,i_2)."
	
	varAccess := loopStmt condition leftOperand.
	self assert: varAccess ssaName equals: 'phi(i_1,i_2)'.

	varAccess := loopStmt body statements first expression arguments first.
	self assert: varAccess ssaName equals: 'phi(i_1,i_2)'.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testForEach [

	| source loopStmt varAccess |
	
	source := 'public void forEachMethod(ArrayList<Integer> list) {
	for (Integer i : list) {
  		System.out.println(i);
	}
}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	loopStmt := ssa statementBlock statements first.	
	varAccess := loopStmt fieldname.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'i_1'.
	"Another example of syntactic sugar making things dumb for analysis, the whole iterating logic is lost here"

	varAccess := loopStmt list.
	self assert: varAccess ssaName equals: 'list_1'.

	varAccess := loopStmt body statements first expression arguments first.
	self assert: varAccess ssaName equals: 'i_1'.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfBlockAssignedBeforeInElse [
	"
	SUBROUTINE something()
	INTEGER x
	x = 5
	IF (x) THEN
	ELSE
	  x = 6
	END IF
	END
	"

	| source ifStmt varAccess |
	source := 'public void something() { 
		int x = 5;
		if (x == 0) { 
			// nothing
		} else { 
			x = 6;
		}
	}'.
	
	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.
	self assert: varAccess ssaName equals: 'x_1'.

	ifStmt := ssa statementBlock statements second.
	varAccess := ifStmt elsePart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_2'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_1,x_2)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 3

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfBlockAssignedBeforeInThen [
	
	| source ifStmt varAccess |
	source := 'public void something() { 
		int x = 5;
		if (x == 0) { 
			x = 6;
		}
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.
	self assert: varAccess ssaName equals: 'x_1'.

	ifStmt := ssa statementBlock statements second.
	varAccess := ifStmt thenPart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_2'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_1,x_2)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 3

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfBlockAssignedBeforeInThenInElse [
	
	| source ifStmt varAccess |
	
	source := 'public void something() { 
		int x = 5;
		if (x==0) { 
			x = 6;
		} else { 
			x = 7;
		}
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.

	ifStmt := ssa statementBlock statements second.
	varAccess := ifStmt thenPart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_2'.

	varAccess := ifStmt elsePart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_3'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_2,x_3)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 4

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfBlockAssignedInElseOnly [
	"Java won't let you compile if you use a variable that might be in an uninitialized state... so should we bother with that kind of test?"
	| source ifStmt varAccess |
	
	source := 'public void something() { 
		int x;
		if (x == 0) { 
			// nothing
		} else { 
			x = 5;
		}
	}'.
	
	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	ifStmt := ssa statementBlock statements second.
	varAccess := ifStmt elsePart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_1'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_0,x_1)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 2

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfBlockFourBranches [

	| source ifStmt varAccess |

	source := 'public void something() { 
		int x, y, z = 1;
		if (z == 0) { 
			if (y == 0) { 
				x = 5;
			}
			else { 
				x = 6;
			}
		} else { 
			if (y == 0) { 
				x = 7;
			}
			else { 
				x = 8;
			}
		}
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	ifStmt := ssa statementBlock statements second thenPart statements first.
	varAccess := ifStmt thenPart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_1'.
	varAccess := ifStmt elsePart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_2'.

	ifStmt := ssa statementBlock statements second elsePart statements first.
	varAccess := ifStmt thenPart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_3'.
	varAccess := ifStmt elsePart statements first expression variable.
	self assert: varAccess ssaName equals: 'x_4'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_1,x_2,x_3,x_4)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 5

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testIfLogicalAssignedBeforeAndInsideAndUsedAfter [
	"
	SUBROUTINE something()
	INTEGER x, y
	x = 5
	IF (bool) x = 6
	y = x
	END
	"

	| source varAccess |
	
	source := 'public void something() { 
		int x = 5;
		int y;
		if (x == 0) { 
			x = 6;
		}
		y = x;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements fourth expression expression.
	self assert: varAccess ssaName equals: 'phi(x_1,x_2)'.

	self assert: varAccess localDeclaration activeVersion name equals: 'phi(x_1,x_2)'.
	self assert: varAccess localDeclaration newVersionNumber equals: 3

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testParameterAssigned [

	| source varAccess |

	source := 'public void something(int x) { 
		x = 5;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first expression variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 2.
	self assert: varAccess ssaName equals: 'x_2'.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testParameterUsed [
	| source varAccess |
	source := 'public void something(int x) { 
		System.out.println(x);
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa parameters first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.

	varAccess := ssa statementBlock statements first expression arguments first.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.

	self assert: varAccess localDeclaration newVersionNumber equals: 2

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testPostfixUnary [
	
	| source varAccess |
	source := 'public void something() { 
		int x = 5;
		int y = x++;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.
	
	varAccess := ssa statementBlock statements second declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'y_1'.

	self assert: varAccess localDeclaration newVersionNumber equals: 2.
	
	varAccess := ssa statementBlock statements second declarators first expression expression.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 2.
	self assert: varAccess ssaName equals: 'x_2'.

	self assert: varAccess localDeclaration newVersionNumber equals: 3.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testPrefixUnary [
	
	| source varAccess |
	source := 'public void something() { 
		int x = 5;
		int y = ++x;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.
	
	varAccess := ssa statementBlock statements second declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'y_1'.

	self assert: varAccess localDeclaration newVersionNumber equals: 2.
	
	varAccess := ssa statementBlock statements second declarators first expression expression.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 2.
	self assert: varAccess ssaName equals: 'x_2'.

	self assert: varAccess localDeclaration newVersionNumber equals: 3.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testSingleAssignement [
	
	| source varAccess |
	source := 'public void something() { 
		int x = 5;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.

	self assert: varAccess localDeclaration newVersionNumber equals: 2

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testUnAssigned [

	| source varAccess |
	source := 'public void something() { 
		int x;
		if (x) { 
			System.out.println(5);
		}
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements second condition.

	self assert: varAccess ssaVersion class equals: FASTVariableVersionSSA.
	self assert: varAccess ssaVersion version equals: 0.
	self assert: varAccess ssaName equals: 'x_0'.

	self assert: varAccess localDeclaration newVersionNumber equals: 1

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testVariableAssignedTwice [
	| varAccess source |
	
	source := 'public void something() { 
		int x = 5;
		x = 6;
	}'.
	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.	
	self assert: varAccess ssaName equals: 'x_1'.

	varAccess := ssa statementBlock statements second expression variable.	
	self assert: varAccess ssaName equals: 'x_2'.
	
	self assert: varAccess localDeclaration newVersionNumber equals: 3.
	self
		assert: ssa statementBlock statements first declarators first variable ssaVersion localDeclaration
		equals: ssa statementBlock statements second expression variable ssaVersion localDeclaration
]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testVariableAssignedTwiceAndReferenced [
	| varAccess source |
	
	source := 'public void something() { 
		int x = 5;
		x = x + 1;
	}'.
	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.	
	self assert: varAccess ssaName equals: 'x_1'.

	varAccess := ssa statementBlock statements second expression variable.	
	self assert: varAccess ssaName equals: 'x_2'.

	varAccess := ssa statementBlock statements second expression expression leftOperand.
	self assert: varAccess ssaName equals: 'x_1'.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testVariableReassigned [
	| varAccess source |
	
	source := 'public void something() { 
		int x = 5;
		int y = x;
	}'.
	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.	
	self assert: varAccess ssaName equals: 'x_1'.

	varAccess := ssa statementBlock statements second declarators first variable.	
	self assert: varAccess ssaName equals: 'y_1'.

	varAccess := ssa statementBlock statements second declarators first expression.
	self assert: varAccess ssaName equals: 'x_1'.

	self
		deny:   ssa statementBlock statements first declarators first variable ssaVersion localDeclaration
		equals: ssa statementBlock statements second declarators first variable ssaVersion localDeclaration
]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testWhile [

	| source loopStmt varAccess |
	
	source := 'public void something() { 
		int x = 0;
		int y = 0;
		while (y < N) { 
			x = x + y;
			y = y + 1;
		}
		return x;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.	
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.
	
	varAccess := ssa statementBlock statements second declarators first variable.	
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'y_1'.

	loopStmt := ssa statementBlock statements third.
	varAccess := loopStmt condition leftOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.

	varAccess := loopStmt condition rightOperand.
	"self assert: varAccess ssaName equals: 'N_0'."

	varAccess := loopStmt body statements first expression variable.
	self assert: varAccess ssaVersion version equals: 2.
	self assert: varAccess ssaName equals: 'x_2'.
	
	varAccess := loopStmt body statements first expression expression leftOperand.
	self assert: varAccess ssaName equals: 'phi(x_1,x_2)'.
	
	varAccess := loopStmt body statements first expression expression rightOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.
	
	varAccess := loopStmt body statements second expression variable.
	self assert: varAccess ssaName equals: 'y_2'.
	
	varAccess := loopStmt body statements second expression expression leftOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.

]

{ #category : 'tests' }
FASTJavaSSAVisitorTest >> testWhileMultipleAssignments [

	| source loopStmt varAccess |
	
	source := 'public void something() { 
		int x = 0;
		int y = 0;
		while (y < N) { 
			x = x + y;
			y = y + 1;
			x = x + 1;
		}
		return x;
	}'.

	ast := self getFASTMethodEntityForSource: source.
	self runVisitor.

	varAccess := ssa statementBlock statements first declarators first variable.	
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'x_1'.
	
	varAccess := ssa statementBlock statements second declarators first variable.	
	self assert: varAccess ssaVersion version equals: 1.
	self assert: varAccess ssaName equals: 'y_1'.

	loopStmt := ssa statementBlock statements third.
	varAccess := loopStmt condition leftOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.

	varAccess := loopStmt condition rightOperand.
	"self assert: varAccess ssaName equals: 'N_0'."

	varAccess := loopStmt body statements first expression variable.
	self assert: varAccess ssaVersion version equals: 2.
	self assert: varAccess ssaName equals: 'x_2'.
	
	varAccess := loopStmt body statements first expression expression leftOperand.
	self assert: varAccess ssaName equals: 'phi(x_1,x_3)'.
	
	varAccess := loopStmt body statements first expression expression rightOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.
	
	varAccess := loopStmt body statements second expression variable.
	self assert: varAccess ssaName equals: 'y_2'.
	
	varAccess := loopStmt body statements second expression expression leftOperand.
	self assert: varAccess ssaName equals: 'phi(y_1,y_2)'.
	
	varAccess := loopStmt body statements third expression variable.
	self assert: varAccess ssaName equals: 'x_3'.
	
	varAccess := loopStmt body statements third expression expression leftOperand.
	self assert: varAccess ssaName equals: 'x_2'.

]
