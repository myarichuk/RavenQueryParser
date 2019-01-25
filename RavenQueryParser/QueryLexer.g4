lexer grammar QueryLexer;

@members{
	
[System.Flags]
public enum LexerState
{
	DefaultMode = 0,
	FunctionMode = 1,
	GraphMode = 2,
	FunctionImplementationMode = 4
}

public LexerState CurrentState;

public IToken CurrentToken;

internal void SetStateFlag(LexerState flag) => CurrentState |= flag;
internal void UnsetStateFlag(LexerState flag) => CurrentState &= ~flag;

}

channels { COMMENT, ERROR, WHITESPACE }

//query entry points
FROM: 'from';
MATCH: 'match' { UnsetStateFlag(LexerState.DefaultMode); SetStateFlag(LexerState.GraphMode); } -> mode(Graph);
 
//keywords
DECLARE_FUNCTION: 'declare function' { UnsetStateFlag(LexerState.DefaultMode); SetStateFlag(LexerState.FunctionMode); } -> mode(Function);
WHERE : 'where';
BETWEEN: 'between';
INCLUDE: 'include';
SELECT: 'select';
DISTINCT: 'distinct';
ORDERBY: 'order by';
LOAD: 'load';
AS: 'as';
DESC: 'desc'; //for orderby clauses
EDGES: 'edges';
ALL_DOCS: '@all_docs';
UPDATE: 'update' { UnsetStateFlag(LexerState.DefaultMode); SetStateFlag(LexerState.FunctionImplementationMode); } -> mode(FunctionImplementation);
WITH: 'with';
AND: 'and';
OR: 'or';
NOT: 'not';

IN: 'in';
ALL_IN: 'all in';

DOT: '.';

INDEX: 'index';

//literals
DOUBLE: DIGIT+ '.' DIGIT+;
LONG: DIGIT+;

TRUE: 'true';
FALSE: 'false';

GREATER: '>';
LESSER: '<';
GREATER_EQUALS: '>=';
LESSER_EQUALS: '<=';
EQUALS: ('=' | '==');

STRING: D_STRING | S_STRING;
fragment D_STRING: '"' ( '\\'. | '""' | ~('"'| '\\') )*? '"';
fragment S_STRING: '\'' ('\\'. | '\'\'' | ~('\'' | '\\'))*? '\'';

fragment LETTER: [A-Za-z];
fragment DIGIT: [0-9];

//punctuation
SPACE: (' '| '\t' | '\r'? '\n') -> channel(WHITESPACE);
COMMA: ',';
BLOCK_COMMENT: '/*' .+? '*/' -> channel(COMMENT);
LINE_COMMENT: '//' ~[\r\n]* ('\r'? '\n' | EOF) -> channel(COMMENT);
DASH: '-';
ARROW_LEFT: '<-';
ARROW_RIGHT: '->';

OPEN_PAREN: '(';
CLOSE_PAREN: ')';
OPEN_CPAREN: '{';
CLOSE_CPAREN: '}';
OPEN_BRACKET: '[';
CLOSE_BRACKET: ']';

AT_SIGN: '@';
IDENTIFIER: (LETTER | '_' ) (LETTER | DIGIT | '_')*;
PARAMETER: '$' IDENTIFIER;

ANY_CHARS: ~[ ]+;

mode Graph;

GRAPH_AT_SIGN: '@' -> type(AT_SIGN);
GRAPH_DOUBLE: DIGIT+ '.' DIGIT+ -> type(DOUBLE);
GRAPH_LONG: DIGIT+ -> type(LONG);
GRAPH_LOAD: LOAD -> type(LOAD);
GRAPH_TRUE: TRUE -> type(TRUE);
GRAPH_FALSE: FALSE -> type(FALSE);
GRAPH_INCLUDE: INCLUDE -> type(INCLUDE);
GRAPH_SELECT: SELECT -> type(SELECT);
GRAPH_DISTINCT: DISTINCT -> type(DISTINCT);
GRAPH_WITH: WITH -> type(WITH);
GRAPH_AS: AS -> type(AS);
GRAPH_ORDERBY: ORDERBY -> type(ORDERBY);
GRAPH_ALL_DOCS: '@all_docs' -> type(ALL_DOCS);
GRAPH_EDGES: EDGES -> type(EDGES);
GRAPH_IN: IN -> type(IN);
GRAPH_ALL_IN: ALL_IN -> type(ALL_IN);
GRAPH_DESC: DESC -> type(DESC);
GRAPH_DASH: '-' -> type(DASH);
GRAPH_ARROW_LEFT: '<-' -> type(ARROW_LEFT);
GRAPH_ARROW_RIGHT: '->' -> type(ARROW_RIGHT);

GRAPH_GREATER: '>' -> type(GREATER);
GRAPH_LESSER: '<' -> type(LESSER);
GRAPH_GREATER_EQUALS: '>=' -> type(GREATER_EQUALS);
GRAPH_LESSER_EQUALS: '<=' -> type(LESSER_EQUALS);
GRAPH_EQUALS: EQUALS -> type(EQUALS);

GRAPH_STRING: (D_STRING | S_STRING) -> type(STRING);
GRAPH_PARAMETER: PARAMETER -> type(PARAMETER);
GRAPH_OPEN_PAREN: '(' -> type(OPEN_PAREN);
GRAPH_CLOSE_PAREN: ')' -> type(CLOSE_PAREN);
GRAPH_OPEN_BRACKET: '[' -> type(OPEN_BRACKET);
GRAPH_CLOSE_BRACKET: ']' -> type(CLOSE_BRACKET);
GRAPH_COMMA: ',' -> type(COMMA);
GRAPH_DOT: '.' -> type(DOT);

GRAPH_SPACE: (' '| '\t' | '\r'? '\n') -> skip;
GRAPH_BLOCK_COMMENT: '/*' .+? '*/' -> channel(COMMENT),type(BLOCK_COMMENT);
GRAPH_LINE_COMMENT: '//' ~[\r\n]* ('\r'? '\n' | EOF) -> channel(COMMENT),type(LINE_COMMENT);

GRAPH_WHERE : WHERE -> type(WHERE);
GRAPH_BETWEEN: BETWEEN -> type(BETWEEN);
GRAPH_AND: AND -> type(AND);
GRAPH_OR: OR -> type(OR);
GRAPH_NOT: NOT -> type(NOT);

GRAPH_IDENTIFIER: (LETTER | '_') (LETTER | DIGIT | '_')* -> type(IDENTIFIER);

mode Function;

FUNCTION_SPACE: (' '| '\t' | '\r'? '\n') -> skip;
FUNCTION_NAME: (LETTER | '_') (LETTER | DIGIT | '_')* -> type(IDENTIFIER);

FUNCTION_OPEN_PAREN: '(' -> type(OPEN_PAREN);
FUNCTION_CLOSE_PAREN: ')' -> type(CLOSE_PAREN);

FUNCTION_OPEN_CPAREN: '{' 
{
SetStateFlag(LexerState.FunctionImplementationMode); 
UnsetStateFlag(LexerState.FunctionMode); 
}
-> type(OPEN_CPAREN), mode(FunctionImplementation) ;

FUNCTION_COMMA: ',' -> type(COMMA);

FUNCTION_BLOCK_COMMENT: '/*' .+? '*/' -> channel(COMMENT),type(BLOCK_COMMENT);
FUNCTION_LINE_COMMENT: '//' ~[\r\n]* ('\r'? '\n' | EOF) -> channel(COMMENT),type(LINE_COMMENT);

mode FunctionImplementation;

FUNCTION_IMPL_OPEN_CPAREN: '{' -> type(OPEN_CPAREN);
FUNCTION_IMPL_CLOSE_CPAREN: '}' 
{
SetStateFlag(LexerState.DefaultMode); 
UnsetStateFlag(LexerState.FunctionImplementationMode); 
}
-> mode(DEFAULT_MODE), type(CLOSE_CPAREN);

SOURCE_CODE_CHAR: . -> more;

