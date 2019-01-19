using Antlr4.Runtime;

namespace RavenQueryParser.ErrorHandlers.InputMismatchHandlers
{
    public class MissingIndexNameAfterIndex : IInputMismatchHandler
    {
        public bool ShouldHandle(Parser recognizer, InputMismatchException e) => 
            recognizer.CurrentToken.Type != QueryLexer.STRING &&
            recognizer.InputStream.La(-1) == QueryLexer.INDEX;

        public void Handle(Parser recognizer, InputMismatchException e)
        {
            var msg = $"Expected to find an index name after the 'index' keyword, but found unrecognized token '{recognizer.CurrentToken.Text}'";
            recognizer.NotifyErrorListeners(recognizer.CurrentToken,msg, e);
        }
    }
}
