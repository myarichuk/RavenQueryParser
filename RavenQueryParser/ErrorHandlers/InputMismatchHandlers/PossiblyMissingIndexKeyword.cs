using System;
using Antlr4.Runtime;

namespace RavenQueryParser.ErrorHandlers.InputMismatchHandlers
{
    public class PossiblyMissingIndexKeyword : IInputMismatchHandler
    {
        public bool ShouldHandle(Parser recognizer, InputMismatchException e)
        {
            return recognizer.CurrentToken.Type == QueryLexer.STRING &&
                   recognizer.InputStream.La(-1) == QueryLexer.FROM;
        }

        public void Handle(Parser recognizer, InputMismatchException e)
        {
            var msg = $"Expected to find a collection name after the 'from' keyword, but found a string '{recognizer.CurrentToken.Text}'. Are you trying to query an index? If so, the correct syntax would be: from index 'index name'";
            recognizer.NotifyErrorListeners(recognizer.CurrentToken,msg, e);
        }
    }
}
