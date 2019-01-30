parser grammar QueryParser;
 
options { tokenVocab=QueryLexer; }

//note: query and patch are separate to prevent ambiguities
query: projectionFunctionClause* (documentQuery | graphQuery) EOF;
patch: FROM querySourceClause loadClause? whereClause? 
		{_input.La(1) == QueryLexer.UPDATE }? <fail={"Patch RQL statements must end with an 'update' clause"}>
		updateClause;

//document query
documentQuery
  @init {
	IToken fromToken;
  }
  : FROM { fromToken = _input.Lt(-1); }
		 (loadClause? whereClause? orderByClause? selectClause? includeClause? { NotifyErrorListeners(fromToken,"Missing index or collection name after 'from' keyword", null); } |
		  querySourceClause loadClause? whereClause? orderByClause? selectClause? includeClause?);
 
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

aliasClause: AS alias = IDENTIFIER | 
			 AS { NotifyErrorListeners(_input.Lt(-1),"Expecting identifier after 'as' keyword", null); }
			;

//shared clauses/expressions
querySourceClause: 
	  ALL_DOCS aliasClause? #AllDocsSource
	| (collection = IDENTIFIER | collectionAsString = STRING) aliasClause? #CollectionSource
	| INDEX indexName = STRING aliasClause? #IndexSource
	| INDEX aliasClause? { NotifyErrorListeners(_input.Lt(-1),"Expecting index name as quoted string after the 'index' keyword",null); } #IndexSourceMissingIndexName
	| aliasClause { NotifyErrorListeners(_input.Lt(-1), "Found alias clause but didn't find a query source definition. Before the alias clause, expected to find either a collection name, '@all_docs' keyword or 'index <index name>'",null); } #InvalidQuerySource
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
loadClause: LOAD params += loadParam (COMMA params+= loadParam)*
		  | LOAD { NotifyErrorListeners(_input.Lt(-1),"Missing document ids to load after the 'load' keyword",null); };

includeClause: INCLUDE expressionList | INCLUDE { NotifyErrorListeners(_input.Lt(-1),"Missing include statement after 'include' keyword",null); };
whereClause: WHERE conditionExpression | WHERE { NotifyErrorListeners(_input.Lt(-1),"Missing filter statement after 'where' keyword",null); };

orderByParam: (expression aliasClause? DESC?);
orderByClause: ORDERBY  orderParams += orderByParam (COMMA orderParams+= orderByParam)* 
			   | ORDERBY { NotifyErrorListeners(_input.Lt(-1), "Missing ordering statement after the 'order by' keyword",null); };

selectField: expression aliasClause?;
selectClause: SELECT DISTINCT? fields += selectField (COMMA fields+= selectField)*
			  | SELECT DISTINCT? { NotifyErrorListeners(_input.Lt(-1), "Missing fields in 'select' clause",null); };

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
