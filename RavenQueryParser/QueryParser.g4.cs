using System.Collections.Generic;

namespace RavenQueryParser
{
    partial class QueryParser
    {
        private static readonly HashSet<int> TokensExpectedAfterFromKeyword = new HashSet<int>
            { QueryLexer.ALL_DOCS, QueryLexer.INDEX, QueryLexer.IDENTIFIER, QueryLexer.STRING };

        private static readonly HashSet<int> BinaryOperatorTokens = new HashSet<int>
            { QueryLexer.GREATER, QueryLexer.LESSER, QueryLexer.GREATER_EQUALS, QueryLexer.LESSER_EQUALS, QueryLexer.EQUALS };
    }
}
