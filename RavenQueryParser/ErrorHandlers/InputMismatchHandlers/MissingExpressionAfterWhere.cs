using Antlr4.Runtime;
using RavenQueryParser.Antlr;

namespace RavenQueryParser.ErrorHandlers.InputMismatchHandlers
{
    public class MissingExpressionAfterWhere : IInputMismatchHandler
    {
        public bool ShouldHandle(Parser recognizer, InputMismatchException e)
        {
            if (recognizer.InputStream.La(-1) != QueryLexer.WHERE)
                return false;

            var currentTokenType = recognizer.CurrentToken.Type;

            return currentTokenType == QueryLexer.ORDERBY ||
                   currentTokenType == QueryLexer.INCLUDE ||
                   currentTokenType == QueryLexer.SELECT ||
                   currentTokenType == Lexer.Eof;          
        }

        public void Handle(Parser recognizer, InputMismatchException e)
        {
            var msg = "Missing condition expression after 'where' clause";
            var ex = new CustomRecognitionException(msg, recognizer, recognizer.InputStream,
                recognizer.RuleContext);
            ex.SetOffendingToken(recognizer.CurrentToken);

            recognizer.NotifyErrorListeners(recognizer.CurrentToken,msg, ex);
        }
    }
}
