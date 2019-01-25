parser grammar QueryParser;
 
options { tokenVocab=QueryLexer; }

//note: query and patch are separate to prevent ambiguities
query: projectionFunctionClause* (documentQuery | graphQuery) EOF;
patch: FROM querySourceClause loadClause? whereClause? updateClause;

//document query
documentQuery: FROM { TokensExpectedAfterFromKeyword.Contains(_input.La(1)) }? <fail={"Missing index or collection name after 'from' keyword"}>
				 querySourceClause loadClause? whereClause? orderByClause? selectClause? includeClause?;
 
//graph query
graphQuery: (nodeWithClause | edgeWithClause)* MATCH patternMatchClause whereClause? orderByClause? selectClause?;
nodeWithClause: WITH OPEN_CPAREN documentQuery CLOSE_CPAREN aliasClause;
edgeWithClause: WITH EDGES OPEN_PAREN edgeType = IDENTIFIER CLOSE_PAREN OPEN_CPAREN whereClause orderByClause? selectClause? CLOSE_CPAREN aliasClause;
edge: OPEN_BRACKET field = expression aliasClause? whereClause? (SELECT expression)? CLOSE_BRACKET;
node: OPEN_PAREN querySourceClause whereClause? CLOSE_PAREN;

patternMatchClause:
                node #PatternMatchSingleNodeExpression
            |   src = patternMatchClause DASH edge ARROW_RIGHT dest = patternMatchClause #PatternMatchRightExpression
            |   dest = patternMatchClause ARROW_LEFT edge DASH src = patternMatchClause #PatternMatchLeftExpression
            |   lVal = patternMatchClause op = (AND | OR) rVal = patternMatchClause #PatternMatchBinaryExpression
            |   lVal = patternMatchClause AND NOT rVal = patternMatchClause #PatternMatchAndNotExpression
            |   OPEN_PAREN patternMatchClause CLOSE_PAREN #PatternMatchParenthesisExpression
            ;

aliasClause: AS {_input.La(1) == QueryLexer.IDENTIFIER }? <fail={"Expecting identifier after 'as' keyword"}> alias = IDENTIFIER; 

//shared clauses/expressions
querySourceClause: 
	  ALL_DOCS aliasClause? #AllDocsSource
	| (collection = IDENTIFIER | collectionAsString = STRING) aliasClause? #CollectionSource
	| INDEX {_input.La(1) == QueryLexer.STRING }? <fail={"Expecting index name as quoted string after the 'index' keyword"}>
	  indexName = STRING aliasClause? #IndexSource
	;

projectionFunctionClause: DECLARE_FUNCTION functionName = IDENTIFIER OPEN_PAREN (params += IDENTIFIER (COMMA params+= IDENTIFIER)*)? CLOSE_PAREN
                    OPEN_CPAREN
                        sourceCode = SOURCE_CODE_CHAR*
                    CLOSE_CPAREN;

loadParamExpression: 
		     identifier = IDENTIFIER #LoadParamIdentifierExpression
		   | instance = loadParamExpression DOT field = IDENTIFIER #LoadParamFieldExpression
		   ;

loadParam: identifier = loadParamExpression aliasClause;
loadClause: LOAD params += loadParam (COMMA params+= loadParam)*;

includeClause: INCLUDE expressionList;
whereClause: WHERE conditionExpression;
orderByParam: (expression aliasClause? DESC?);
orderByClause: ORDERBY  orderParams += orderByParam (COMMA orderParams+= orderByParam)*;

selectField: expression aliasClause?;
selectClause: SELECT DISTINCT? fields += selectField (COMMA fields+= selectField)*;

updateClause: UPDATE {_input.La(1) == QueryLexer.OPEN_CPAREN }? <fail={"Expecting to find '{' after the 'update' keyword"}>
                OPEN_CPAREN
                    patchSourceCode = SOURCE_CODE_CHAR*
                CLOSE_CPAREN;
 
//expressions
literal:
        (TRUE | FALSE) #BooleanLiteral
    |   LONG #LongLiteral
    |   DOUBLE  #DoubleLiteral
    |   STRING  #StringLiteral
    ;

expressionList: params += expression (COMMA params+= expression)*;

expression:
            literal #LiteralExpression
        |   PARAMETER #ParemeterExpression
        |   IDENTIFIER #IdentifierExpression
        |   instance = IDENTIFIER OPEN_BRACKET CLOSE_BRACKET #CollectionReferenceExpression
        |   instance = IDENTIFIER OPEN_BRACKET indexer = expression CLOSE_BRACKET #CollectionIndexExpression
        |   instance = expression DOT field = expression #MemberExpression
        |   functionName = IDENTIFIER OPEN_PAREN expressionList? CLOSE_PAREN #MethodExpression
        ;

conditionExpression:
                value = expression BETWEEN from = expression AND to = expression #BetweenConditionExpression
			|	value = expression BETWEEN AND to = expression {false}? <fail={"Missing 'from' expression in 'between' clause"}> #BetweenConditionExpressionMissingFrom
			|	value = expression BETWEEN from = expression AND {false}? <fail={"Missing 'to' expression in 'between' clause"}> #BetweenConditionExpressionMissingTo
            |   value = expression IN 
					{_input.La(1) == QueryLexer.OPEN_PAREN }? <fail={"Expecting to find '(' after the 'in' keyword"}> 
					OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #InConditionExpression
            |   value = expression ALL_IN 
					{_input.La(1) == QueryLexer.OPEN_PAREN }? <fail={"Expecting to find '(' after the 'all in' keyword"}> 
					OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #AllInConditionExpression
            |   lval = expression op = (GREATER | LESSER | GREATER_EQUALS | LESSER_EQUALS | EQUALS) rVal = expression #ComparisonConditionExpression
            |   OPEN_PAREN conditionExpression CLOSE_PAREN #ParenthesisConditionExpression
            |   functionName = IDENTIFIER OPEN_PAREN expressionList? CLOSE_PAREN #MethodConditionExpression
            |   NOT conditionExpression #NegatedConditionExpression
            |   lval = conditionExpression op = (AND | OR) rVal = conditionExpression #IntersectionConditionExpression
            ;
