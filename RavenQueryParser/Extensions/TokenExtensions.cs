using Antlr4.Runtime;

namespace RavenQueryParser.Extensions
{
    public static class TokenExtensions
    {
        public static bool IsValidTokenAfterDocumentQuerySource(this IToken token)
        {
            return token.Type == QueryLexer.LOAD || 
                   token.Type == QueryLexer.WHERE ||
                   token.Type == QueryLexer.ORDERBY ||
                   token.Type == QueryLexer.SELECT ||
                   token.Type == QueryLexer.INCLUDE;
        }
    }
}
