using Antlr4.Runtime;
using RavenQueryParser.Extensions;

namespace RavenQueryParser.ErrorHandlers.UnwantedTokenHandlers
{
    public class InvalidKeywordAfterIndexName : IUnwantedTokenHandler
    {
        public bool ShouldHandle(Parser recognizer)
        {
            return !recognizer.CurrentToken.IsValidTokenAfterDocumentQuerySource() &&
                   recognizer.InputStream.La(-1) == QueryLexer.STRING &&
                   recognizer.InputStream.La(-2) == QueryLexer.INDEX;
        }

        public void Handle(Parser recognizer)
        {
            var msg = $"Unrecognized token '{recognizer.CurrentToken.Text}' after an index name. Either end of query or one of document query clauses is expected";
            recognizer.NotifyErrorListeners(recognizer.CurrentToken,msg,new RecognitionException(msg,recognizer,recognizer.InputStream,recognizer.RuleContext));
        }
    }
}
