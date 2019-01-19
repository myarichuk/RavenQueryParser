using Antlr4.Runtime;
using RavenQueryParser.Antlr;

namespace RavenQueryParser.ErrorHandlers.InputMismatchHandlers
{
    public class MissingCollectionName : IInputMismatchHandler
    {
        public bool ShouldHandle(Parser recognizer, InputMismatchException e)
        {
            return recognizer.InputStream.La(-1) == QueryLexer.FROM && 
                   recognizer.CurrentToken.Type != QueryLexer.IDENTIFIER &&
                   recognizer.CurrentToken.Type != QueryLexer.ALL_DOCS && 
                   recognizer.CurrentToken.Type != QueryLexer.STRING;
        }

        public void Handle(Parser recognizer, InputMismatchException e)
        {
            var msg = "Missing collection or index name after 'from' clause.";
            var ex = new CustomRecognitionException(msg, recognizer, recognizer.InputStream,
                recognizer.RuleContext);
            ex.SetOffendingToken(recognizer.TokenFactory.Create(QueryLexer.FROM, "from"));
            recognizer.NotifyErrorListeners(recognizer.CurrentToken,msg,ex);
        }
    }
}
