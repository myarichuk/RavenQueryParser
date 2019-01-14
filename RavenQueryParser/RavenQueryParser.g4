parser grammar RavenQueryParser;

options { tokenVocab=RavenQueryLexer; }

query: projectionFunction* (patch | documentQuery | graphQuery) EOF;

//document query
documentQuery:  FROM querySource loadClause? whereClause? orderByClause? selectClause? includeClause?;
patch: FROM querySource loadClause? whereClause? orderByClause? updateClause;

//graph query
graphQuery: (nodeWithClause | edgeWithClause)* MATCH patternMatchExpression whereClause? orderByClause? selectClause?;
nodeWithClause: WITH OPEN_CPAREN documentQuery CLOSE_CPAREN AS alias = IDENTIFIER;
edgeWithClause: WITH EDGES OPEN_PAREN edgeType = IDENTIFIER CLOSE_PAREN OPEN_CPAREN whereClause orderByClause? selectClause? CLOSE_CPAREN AS alias = IDENTIFIER;
edge: OPEN_BRACKET field = expression (AS alias = IDENTIFIER)? whereClause? (SELECT expression)? CLOSE_BRACKET;
node: OPEN_PAREN querySource whereClause? CLOSE_PAREN;

patternMatchExpression:
                node #PatternMatchSingleNodeExpression
            |   src = patternMatchExpression DASH edge ARROW_RIGHT dest = patternMatchExpression #PatternMatchRightExpression
            |   dest = patternMatchExpression ARROW_LEFT edge DASH src = patternMatchExpression #PatternMatchLeftExpression
            |   lVal = patternMatchExpression op = (AND | OR) rVal = patternMatchExpression #PatternMatchBinaryExpression
            |   lVal = patternMatchExpression AND NOT rVal = patternMatchExpression #PatternMatchAndNotExpression
            |   OPEN_PAREN patternMatchExpression CLOSE_PAREN #PatternMatchParenthesisExpression
            ;


//shared clauses/expressions
querySource: (ALL_DOCS | collection | INDEX indexName = STRING) (AS alias = IDENTIFIER)?;

collection: (AT_SIGN? IDENTIFIER);
projectionFunction: DECLARE_FUNCTION functionName = IDENTIFIER OPEN_PAREN (params += IDENTIFIER (COMMA params+= IDENTIFIER)*)? CLOSE_PAREN
                    OPEN_CPAREN
                        sourceCode = SOURCE_CODE_CHAR*
                    CLOSE_CPAREN;

expressionWithAlias: expression AS alias = IDENTIFIER;
loadClause: LOAD params += expressionWithAlias (COMMA params+= expressionWithAlias)*;

includeClause: INCLUDE expressionList;
whereClause: WHERE conditionExpression;
orderByParam: (expression (AS asType = IDENTIFIER)? DESC?);
orderByClause: ORDERBY  orderParams += orderByParam (COMMA orderParams+= orderByParam)*;

selectField: expression (AS alias = IDENTIFIER)?;
selectClause: SELECT DISTINCT? fields += selectField (COMMA fields+= selectField)*;

updateClause: UPDATE
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
            |   value = expression IN OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #InConditionExpression
            |   value = expression ALL_IN OPEN_PAREN params += literal (COMMA params+= literal)* CLOSE_PAREN #AllInConditionExpression
            |   lval = expression op = (GREATER | LESSER | GREATER_EQUALS | LESSER_EQUALS | EQUALS) rVal = expression #ComparisonConditionExpression
            |   OPEN_PAREN conditionExpression CLOSE_PAREN #ParenthesisConditionExpression
            |   functionName = IDENTIFIER OPEN_PAREN expressionList? CLOSE_PAREN #MethodConditionExpression
            |   NOT conditionExpression #NegatedConditionExpression
            |   lval = conditionExpression op = (AND | OR) rVal = conditionExpression #IntersectionConditionExpression
            ;
