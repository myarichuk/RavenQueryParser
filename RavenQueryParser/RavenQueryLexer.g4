lexer grammar RavenQueryLexer;

channels { COMMENT, ERROR, WHITESPACE }

//query entry points
FROM: F R O M;
MATCH: M A T C H -> mode(Graph);

//keywords
DECLARE_FUNCTION: D E C L A R E ' ' F U N C T I O N -> mode(Function);
WHERE : W H E R E;
BETWEEN: B E T W E E N;
INCLUDE: I N C L U D E;
SELECT: S E L E C T;
DISTINCT: D I S T I N C T;
ORDERBY: O R D E R ' ' B Y;
LOAD: L O A D;
AS: A S;
DESC: D E S C; //for orderby clauses
EDGES: E D G E S;
ALL_DOCS: '@all_docs';
UPDATE: U P D A T E -> mode(FunctionImplementation);
WITH: W I T H;
AND: A N D;
OR: O R;
NOT: N O T;

IN: I N;
ALL_IN: A L L '_' I N;

DOT: '.';

INDEX: I N D E X;

//literals
DOUBLE: DIGIT+ '.' DIGIT+;
LONG: DIGIT+;

TRUE: T R U E;
FALSE: F A L S E;

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

fragment A : [aA]; // match either an 'a' or 'A'
fragment B : [bB];
fragment C : [cC];
fragment D : [dD];
fragment E : [eE];
fragment F : [fF];
fragment G : [gG];
fragment H : [hH];
fragment I : [iI];
fragment J : [jJ];
fragment K : [kK];
fragment L : [lL];
fragment M : [mM];
fragment N : [nN];
fragment O : [oO];
fragment P : [pP];
fragment Q : [qQ];
fragment R : [rR];
fragment S : [sS];
fragment T : [tT];
fragment U : [uU];
fragment V : [vV];
fragment W : [wW];
fragment X : [xX];
fragment Y : [yY];
fragment Z : [zZ];

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

FUNCTION_OPEN_CPAREN: '{' -> type(OPEN_CPAREN), mode(FunctionImplementation);
FUNCTION_COMMA: ',' -> type(COMMA);

FUNCTION_BLOCK_COMMENT: '/*' .+? '*/' -> channel(COMMENT),type(BLOCK_COMMENT);
FUNCTION_LINE_COMMENT: '//' ~[\r\n]* ('\r'? '\n' | EOF) -> channel(COMMENT),type(LINE_COMMENT);

mode FunctionImplementation;

FUNCTION_IMPL_OPEN_CPAREN: '{' -> type(OPEN_CPAREN);
FUNCTION_IMPL_CLOSE_CPAREN: '}' -> mode(DEFAULT_MODE), type(CLOSE_CPAREN);
SOURCE_CODE_CHAR: . -> more;

