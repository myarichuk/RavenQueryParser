parser grammar QueryParser;
 
options { tokenVocab=QueryLexer; }

//note: query and patch are separate to prevent ambiguities
query: projectionFunctionClause* (documentQuery | graphQuery) EOF;
patch: 
	   FROM
	   (querySourceClause | { NotifyErrorListeners(_input.Lt(-1),"Missing index or collection name after 'from' keyword", null); }) 
	   loadClause? whereClause? 
	   ( updateClause | { NotifyErrorListeners(_input.Lt(-1),"Patch queries must contain 'update' clause.",null); })        
	   EOF;

//document query
documentQuery
  @init {
	IToken fromToken;
  }
  : FROM { fromToken = _input.Lt(-1); }
		 (querySourceClause loadClause? whereClause? orderByClause? selectClause? includeClause?
		 |
		 loadClause? whereClause? orderByClause? selectClause? includeClause? { NotifyErrorListeners(fromToken,"Missing index or collection name after 'from' keyword", null); });
 
//graph query
graphQuery: (nodeWithClause | edgeWithClause)* MATCH ((clauseKeywords | EOF) { NotifyErrorListeners(_input.Lt(-1),"Missing pattern match expression after the 'match' keyword",null); } |
												patternMatchClause whereClause? orderByClause? selectClause?);
nodeWithClause: WITH OPEN_CPAREN documentQuery CLOSE_CPAREN aliasClause;
edgeWithClause: WITH EDGES OPEN_PAREN edgeType = IDENTIFIER CLOSE_PAREN OPEN_CPAREN whereClause orderByClause? selectClause? CLOSE_CPAREN aliasClause;
edge: OPEN_BRACKET field = expression aliasClause? whereClause? (SELECT expression)? (CLOSE_BRACKET | EOF? { NotifyErrorListeners("Missing ']'"); });
node: OPEN_PAREN querySourceClause whereClause? (CLOSE_PAREN | EOF? { NotifyErrorListeners("Missing ')'"); });

patternMatchClause:
				node #PatternMatchSingleNodeExpression
			|   src = patternMatchClause DASH edge ARROW_RIGHT dest = patternMatchClause #PatternMatchRightExpression
			|   dest = patternMatchClause ARROW_LEFT edge DASH src = patternMatchClause #PatternMatchLeftExpression
			|   lVal = patternMatchClause op = (AND | OR) rVal = patternMatchClause #PatternMatchBinaryExpression
			|   lVal = patternMatchClause AND NOT rVal = patternMatchClause #PatternMatchAndNotExpression
			|   OPEN_PAREN patternMatchClause CLOSE_PAREN #PatternMatchParenthesisExpression
			;

aliasClause: AS alias = IDENTIFIER 
            | 
			 AS { NotifyErrorListeners(_input.Lt(-1),"Expecting identifier (alias) after 'as' keyword", null); }
			|  alias = IDENTIFIER { NotifyErrorListeners(_input.Lt(-1),"Missing 'as' keyword", null); }
			;

//shared clauses/expressions
querySourceClause: 
	  ALL_DOCS aliasClause? #AllDocsSource
	| (collection = IDENTIFIER | collectionAsString = STRING) aliasClause? #CollectionSource
	| INDEX indexName = STRING aliasClause? #IndexSource
	| INDEX aliasClause? { NotifyErrorListeners(_input.Lt(-1),"Expecting index name as quoted string after the 'index' keyword",null); } #IndexSourceMissingIndexName
	| aliasClause { NotifyErrorListeners(_input.Lt(-1), "Found alias clause but didn't find a query source definition. Before the alias clause, expected to find either a collection name, '@all_docs' keyword or 'index <index name>'",null); } #InvalidQuerySource	
	;
  
projectionFunctionClause: 
		DECLARE_FUNCTION { NotifyErrorListeners(_input.Lt(-1),"Found 'declare function' token but no actual function definition. Expected to see a JavaScript function definition.", null); }
	|	DECLARE_FUNCTION 
			(functionName = IDENTIFIER |  { NotifyErrorListeners(_input.Lt(-1),"Expected to find a function name but found none", null); }) 
			(OPEN_PAREN | { NotifyErrorListeners(_input.Lt(-1),"Missing '('", null); })
				(params += IDENTIFIER ((COMMA | { NotifyErrorListeners(_input.Lt(-1),"Missing ','", null); }) params+= IDENTIFIER)*)? 
			(CLOSE_PAREN | { NotifyErrorListeners(_input.Lt(-1),"Missing ')'", null); })
					javascriptBlock
					;

javascriptBlock:
					(
					OPEN_CPAREN
						(sourceCode = statementList)?
					CloseBrace
					|
					{ NotifyErrorListeners(_input.Lt(-1),"Missing '{'", null); }
						(sourceCode = statementList)?
					CLOSE_CPAREN
					|
					{ NotifyErrorListeners(_input.Lt(-1),"Missing '{'", null); }
						(sourceCode = statementList)?
					{ NotifyErrorListeners(_input.Lt(-1),"Missing '}'", null); }
					|
					OPEN_CPAREN
						(sourceCode = statementList)?
					{ NotifyErrorListeners(_input.Lt(-1),"Missing '}'", null); }
					)
					;

identifierToLoad: 
	identifier = expression aliasClause
	|
	identifier = expression { NotifyErrorListeners(_input.Lt(-1),"Missing alias in the form of 'AS <alias>'. In 'load' clause, identifiers to load should always have aliases defined.",null); }
	|
	aliasClause { NotifyErrorListeners(_input.Lt(-2),"Expected to see a document id before the 'as' keyword. ",null); }
	;	 
 
loadClause:			
			LOAD params += identifierToLoad ((COMMA | { NotifyErrorListeners(_input.Lt(-1),"Missing ','", null); }) params+= identifierToLoad)*
		  | LOAD { NotifyErrorListeners(_input.Lt(-1),"Expected to find document id but found ',' instead",null); } ((COMMA | { NotifyErrorListeners(_input.Lt(-1),"Missing ','", null); }) params+= identifierToLoad)+
		  | LOAD { NotifyErrorListeners(_input.Lt(-1),"Missing one or more document id(s) to load after the 'load' keyword",null); };
   
includeClause: INCLUDE expressionList | INCLUDE { NotifyErrorListeners(_input.Lt(-1),"Missing include statement after 'include' keyword",null); };
whereClause: WHERE conditionExpression | WHERE { NotifyErrorListeners(_input.Lt(-1),"Missing filter statement after 'where' keyword",null); };

orderByParam: (expression aliasClause? DESC?);
orderByClause: ORDERBY  orderParams += orderByParam ((COMMA | { NotifyErrorListeners(_input.Lt(-1),"Missing ','", null); }) orderParams+= orderByParam)* 
			   | ORDERBY { NotifyErrorListeners(_input.Lt(-1), "Missing ordering statement after the 'order by' keyword",null); };

selectField: expression aliasClause?;
selectClause: SELECT DISTINCT? fields += selectField ((COMMA | { NotifyErrorListeners(_input.Lt(-1),"Missing ','", null); }) fields+= selectField)*
			  | SELECT DISTINCT? { NotifyErrorListeners(_input.Lt(-1), "Missing fields in 'select' clause",null); };

updateClause: UPDATE javascriptBlock;
 
//expressions
queryLiteral:
		(TRUE | FALSE) #BooleanLiteral
	|   LONG #LongLiteral
	|   DOUBLE  #DoubleLiteral
	|   STRING  #StringLiteral
	;

expressionList: params += expression (COMMA params+= expression)*;

expression:
			queryLiteral #QueryLiteralExpression
		|   PARAMETER #ParemeterExpression
		|   IDENTIFIER #QueryIdentifierExpression
		|   instance = IDENTIFIER OPEN_BRACKET CLOSE_BRACKET #CollectionReferenceExpression
		|   instance = IDENTIFIER OPEN_BRACKET indexer = expression CLOSE_BRACKET #CollectionIndexExpression
		|   instance = expression DOT field = expression #MemberExpression
		|   functionName = IDENTIFIER OPEN_PAREN expressionList? CLOSE_PAREN #MethodExpression
		;

clauseKeywords:
	SELECT |
	WHERE |
	FROM |
	ORDERBY |
	BETWEEN |
	LOAD |
	INCLUDE |
	MATCH |
	WITH |
	DECLARE |
	FUNCTION |
	UPDATE;

conditionExpression:
				value = expression BETWEEN from = expression AND to = expression #BetweenConditionExpression
			|	value = expression BETWEEN AND to = expression {false}? <fail={"Missing 'from' expression in 'between' clause"}> #BetweenConditionExpressionMissingFrom
			|	value = expression BETWEEN from = expression AND {false}? <fail={"Missing 'to' expression in 'between' clause"}> #BetweenConditionExpressionMissingTo
			|	value = expression BETWEEN {false}? <fail={"Invalid 'between' expression, missing the 'from' and 'to'. The correct syntax would be - 'user.Age between 20 and 30'"}> #BetweenConditionExpressionMissingBothFromAndTo
			|   value = expression IN 
					{_input.La(1) == QueryLexer.OPEN_PAREN }? <fail={"Expecting to find '(' after the 'in' keyword"}> 
					OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #InConditionExpression
			 |   value = expression IN {false}? <fail={"Invalid 'in' expression, missing the comparison. The correct syntax would be - 'user.Age in (20,21,22,23)'"}> #InConditionExpressionMissingComparisonSet
			 |   value = expression ALL_IN 
					{_input.La(1) == QueryLexer.OPEN_PAREN }? <fail={"Expecting to find '(' after the 'all in' keyword"}> 
					OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #AllInConditionExpression
			|   value = expression ALL_IN {false}? <fail={"Invalid 'all in' expression, missing the comparison. The correct syntax would be - 'user.Age in (20,21,22,23)'"}> #AllInConditionExpressionMissingComparisonSet            |   lval = expression 
					(GREATER | LESSER | GREATER_EQUALS | LESSER_EQUALS | EQUALS 
					| ANY_CHARS {false}? <fail={"Invalid operator '" + _input.Lt(-1).Text + "'. Expected it to be one of: '>', '<', '>=', '<=' or '='"}>) 
				rVal = expression #ComparisonConditionExpression
			|   OPEN_PAREN conditionExpression (CLOSE_PAREN | {false}? <fail={"Missing ')'"}>) #ParenthesisConditionExpression
			|   functionName = IDENTIFIER OPEN_PAREN expressionList? CLOSE_PAREN #MethodConditionExpression
			|   NOT conditionExpression #NegatedConditionExpression
			|   lval = conditionExpression (AND | OR | ANY_CHARS {false}? <fail={"Invalid operator '" + _input.Lt(-1).Text + "'. Expected the operator to be 'and' or 'or'"}>) rVal = conditionExpression #IntersectionConditionExpression
			|	expression expression {false}? <fail={"Missing an operator between '" + _input.Lt(-1).Text + "' and '" + _input.Lt(-2).Text + "'. The following operators are valid: '>', '<', '>=', '<=' or '='"}> #MissingOperatorInConditionExpression
			|	expression (clauseKeywords | EOF) {false}? <fail={"Condition expression is incomplete. Expected to find here an expression in the form of 'x > 5'"}>#UncompleteConditionExpression
			;




// JavaScript parser rules for parsing projection function
/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2014 by Bart Kiers (original author) and Alexandre Vitorelli (contributor -> ported to CSharp)
 * Copyright (c) 2017 by Ivan Kochurkin (Positive Technologies):
	added ECMAScript 6 support, cleared and transformed to the universal grammar.
 * Copyright (c) 2018 by Juan Alvarez (contributor -> ported to Go)
 *
 * Permission is hereby granted, free of charge, to any person
 * obtaining a copy of this software and associated documentation
 * files (the "Software"), to deal in the Software without
 * restriction, including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following
 * conditions:
 * 
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 * HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 * WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 * OTHER DEALINGS IN THE SOFTWARE.
 */

sourceElement
	: Export? statement
	;

statement
	: codeBlock
	| variableStatement
	| emptyStatement
	| classDeclaration
	| expressionStatement
	| ifStatement
	| iterationStatement
	| continueStatement
	| breakStatement
	| returnStatement
	| withStatement
	| labelledStatement
	| switchStatement
	| throwStatement
	| tryStatement
	| debuggerStatement
	| functionDeclaration
	;

codeBlock
	: 
		OpenBrace
			statementList?
		CloseBrace
	;

statementList
	: statement+
	;

variableStatement
	: varModifier variableDeclarationList eos
	;

variableDeclarationList
	: variableDeclaration (COMMA variableDeclaration)*
	;

variableDeclaration
	: (Identifier | arrayLiteral | objectLiteral) (EQUALS singleExpression)? // ECMAScript 6: Array & Object Matching
	;

emptyStatement
	: SemiColon
	;

expressionStatement
	: {this.notOpenBraceAndNotFunction()}? expressionSequence eos
	;

ifStatement
	: If OpenParen expressionSequence CloseParen statement (Else statement)?
	;


iterationStatement
	: Do statement While OpenParen expressionSequence CloseParen eos                                                         # DoStatement
	| While OpenParen expressionSequence CloseParen statement                                                                # WhileStatement
	| For OpenParen expressionSequence? SemiColon expressionSequence? SemiColon expressionSequence? CloseParen statement                 # ForStatement
	| For OpenParen varModifier variableDeclarationList SemiColon expressionSequence? SemiColon expressionSequence? CloseParen
		  statement                                                                                             # ForVarStatement
	| For OpenParen singleExpression (In | Identifier{this.p("of")}?) expressionSequence CloseParen statement                # ForInStatement
	| For OpenParen varModifier variableDeclaration (In | Identifier{this.p("of")}?) expressionSequence CloseParen statement # ForVarInStatement
	;

varModifier  // let, const - ECMAScript 6
	: Var
	| Let
	| Const
	;

continueStatement
	: Continue ({this.notLineTerminator()}? Identifier)? eos
	;

breakStatement
	: Break ({this.notLineTerminator()}? Identifier)? eos
	;

returnStatement
	: Return ({this.notLineTerminator()}? expressionSequence)? eos
	;

withStatement
	: With OpenParen expressionSequence CloseParen statement
	;

switchStatement
	: Switch OpenParen expressionSequence CloseParen casecodeBlock
	;

casecodeBlock
	: OpenBrace caseClauses? (defaultClause caseClauses?)? CloseBrace
	;

caseClauses
	: caseClause+
	;

caseClause
	: Case expressionSequence Colon statementList?
	;

defaultClause
	: Default Colon statementList?
	;

labelledStatement
	: Identifier Colon statement
	;

throwStatement
	: Throw {this.notLineTerminator()}? expressionSequence eos
	;

tryStatement
	: Try codeBlock (catchProduction finallyProduction? | finallyProduction)
	;

catchProduction
	: Catch OpenParen Identifier CloseParen codeBlock
	;

finallyProduction
	: Finally codeBlock
	;

debuggerStatement
	: Debugger eos
	;

functionDeclaration
	: Function Identifier OpenParen formalParameterList? CloseParen OpenBrace functionBody CloseBrace
	;

classDeclaration
	: Class Identifier classTail
	;

classTail
	: (Extends singleExpression)? OpenBrace classElement* CloseBrace
	;

classElement
	: (Static | {n("static")}? Identifier)? methodDefinition
	| emptyStatement
	;

methodDefinition
	: propertyName OpenParen formalParameterList? CloseParen OpenBrace functionBody CloseBrace
	| getter OpenParen CloseParen OpenBrace functionBody CloseBrace
	| setter OpenParen formalParameterList? CloseParen OpenBrace functionBody CloseBrace
	| generatorMethod
	;

generatorMethod
	: Multiply? Identifier OpenParen formalParameterList? CloseParen OpenBrace functionBody CloseBrace
	;

formalParameterList
	: formalParameterArg (Comma formalParameterArg)* (Comma lastFormalParameterArg)?
	| lastFormalParameterArg
	| arrayLiteral                            // ECMAScript 6: Parameter Context Matching
	| objectLiteral                           // ECMAScript 6: Parameter Context Matching
	;

formalParameterArg
	: Identifier (Assign singleExpression)?      // ECMAScript 6: Initialization
	;

lastFormalParameterArg                        // ECMAScript 6: Rest Parameter
	: Ellipsis Identifier
	;

functionBody
	: sourceElements?
	;

sourceElements
	: sourceElement+
	;

arrayLiteral
	: OpenBracket Comma* elementList? Comma* CloseBracket
	;

elementList
	: singleExpression (Comma+ singleExpression)* (Comma+ lastElement)?
	| lastElement
	;

lastElement                      // ECMAScript 6: Spread Operator
	: Ellipsis Identifier
	;

objectLiteral
	: OpenBrace (propertyAssignment (Comma propertyAssignment)*)? Comma? CloseBrace
	;

propertyAssignment
	: propertyName (Colon |Assign) singleExpression       # PropertyExpressionAssignment
	| OpenBracket singleExpression CloseBracket Colon singleExpression  # ComputedPropertyExpressionAssignment
	| getter OpenParen CloseParen OpenBrace functionBody CloseBrace            # PropertyGetter
	| setter OpenParen Identifier CloseParen OpenBrace functionBody CloseBrace # PropertySetter
	| generatorMethod                                # MethodProperty
	| Identifier                                     # PropertyShorthand
	;

propertyName
	: identifierName
	| StringLiteral
	| numericLiteral
	;

arguments
	: OpenParen(
		  singleExpression (Comma singleExpression)* (Comma lastArgument)? |
		  lastArgument
	   )?CloseParen
	;

lastArgument                                  // ECMAScript 6: Spread Operator
	: Ellipsis Identifier
	;

expressionSequence
	: singleExpression (Comma singleExpression)*
	;

singleExpression
	: Function Identifier? OpenParen formalParameterList? CloseParen OpenBrace functionBody CloseBrace # FunctionExpression
	| Class Identifier? classTail                                            # ClassExpression
	| singleExpression OpenBracket expressionSequence CloseBracket                            # MemberIndexExpression
	| singleExpression Dot identifierName                                    # MemberDotExpression
	| singleExpression arguments                                             # ArgumentsExpression
	| New singleExpression arguments?                                        # NewExpression
	| singleExpression {this.notLineTerminator()}? PlusPlus                      # PostIncrementExpression
	| singleExpression {this.notLineTerminator()}? MinusMinus                      # PostDecreaseExpression
	| Delete singleExpression                                                # DeleteExpression
	| Void singleExpression                                                  # VoidExpression
	| Typeof singleExpression                                                # TypeofExpression
	| PlusPlus singleExpression                                                  # PreIncrementExpression
	| MinusMinus singleExpression                                                  # PreDecreaseExpression
	| Plus singleExpression                                                   # UnaryPlusExpression
	| Minus singleExpression                                                   # UnaryMinusExpression
	| BitNot singleExpression                                                   # BitNotExpression
	| Not singleExpression                                                   # NotExpression
	| singleExpression (Multiply | Divide | Modulus) singleExpression                    # MultiplicativeExpression
	| singleExpression (Plus | Minus) singleExpression                          # AdditiveExpression
	| singleExpression (LeftShiftArithmetic | RightShiftArithmetic | RightShiftLogical) singleExpression                # BitShiftExpression
	| singleExpression (LessThan | MoreThan | LessThanEquals | GreaterThanEquals) singleExpression            # RelationalExpression
	| singleExpression Instanceof singleExpression                           # InstanceofExpression
	| singleExpression In singleExpression                                   # InExpression
	| singleExpression (Equals_ | NotEquals | IdentityEquals | IdentityNotEquals) singleExpression        # EqualityExpression
	| singleExpression BitAnd singleExpression                                  # BitAndExpression
	| singleExpression BitXOr singleExpression                                  # BitXOrExpression
	| singleExpression BitOr singleExpression                                  # BitOrExpression
	| singleExpression And singleExpression                                 # LogicalAndExpression
	| singleExpression Or singleExpression                                 # LogicalOrExpression
	| singleExpression QuestionMark singleExpression Colon singleExpression             # TernaryExpression
	| singleExpression Assign singleExpression                                  # AssignmentExpression
	| singleExpression assignmentOperator singleExpression                   # AssignmentOperatorExpression
	| singleExpression TemplateStringLiteral                                 # TemplateStringExpression  // ECMAScript 6
	| This                                                                   # ThisExpression
	| Identifier                                                             # IdentifierExpression
	| Super                                                                  # SuperExpression
	| literal                                                                # LiteralExpression
	| arrayLiteral                                                           # ArrayLiteralExpression
	| objectLiteral                                                          # ObjectLiteralExpression
	| OpenParen expressionSequence CloseParen                                             # ParenthesizedExpression
	| arrowFunctionParameters Arrow arrowFunctionBody                         # ArrowFunctionExpression   // ECMAScript 6
	;

arrowFunctionParameters
	: Identifier
	| OpenParen formalParameterList? CloseParen
	;

arrowFunctionBody
	: singleExpression
	| OpenBrace functionBody CloseBrace
	;

assignmentOperator
	: MultiplyAssign
	| DivideAssign
	| ModulusAssign
	| PlusAssign
	| MinusAssign
	| LeftShiftArithmeticAssign
	| RightShiftArithmeticAssign
	| RightShiftLogicalAssign
	| BitAndAssign
	| BitXorAssign
	| BitOrAssign
	;

literal
	: NullLiteral
	| BooleanLiteral
	| StringLiteral
	| TemplateStringLiteral
	| RegularExpressionLiteral
	| numericLiteral
	;

numericLiteral
	: DecimalLiteral
	| HexIntegerLiteral
	| OctalIntegerLiteral
	| OctalIntegerLiteral2
	| BinaryIntegerLiteral
	;

identifierName
	: Identifier
	| reservedWord
	;

reservedWord
	: keyword
	| NullLiteral
	| BooleanLiteral
	;

keyword
	: Break
	| Do
	| Instanceof
	| Typeof
	| Case
	| Else
	| New
	| Var
	| Catch
	| Finally
	| Return
	| Void
	| Continue
	| For
	| Switch
	| While
	| Debugger
	| Function
	| This
	| With
	| Default
	| If
	| Throw
	| Delete
	| In
	| Try

	| Class
	| Enum
	| Extends
	| Super
	| Const
	| Export
	| Import
	| Implements
	| Let
	| Private
	| Public
	| Interface
	| Package
	| Protected
	| Static
	| Yield
	;

getter
	: Identifier{this.p("get")}? propertyName
	;

setter
	: Identifier{this.p("set")}? propertyName
	;

eos
	: SemiColon
	| EOF
	| {this.lineTerminatorAhead()}?
	| {this.closeBrace()}?
	;