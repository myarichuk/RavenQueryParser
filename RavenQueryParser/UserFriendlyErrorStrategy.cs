using Antlr4.Runtime;

namespace RavenQueryParser
{
    public class UserFriendlyErrorStrategy : DefaultErrorStrategy
    {
        protected override void ReportMissingToken(Parser recognizer)
        {
            var currentToken = recognizer.CurrentToken;
            var msg = "missing " + GetExpectedTokens(recognizer).ToString(recognizer.Vocabulary) + " at " + GetTokenErrorDisplay(currentToken);
            
            recognizer.NotifyErrorListeners(currentToken, msg, null);
        }

        protected override void ReportUnwantedToken(Parser recognizer)
        {                   
            //bit more user-friendly "catch all" error
            if (recognizer.InputStream.La(2) == QueryLexer.Eof) //next token type
            {
                var msg = $"Unrecognized token '{recognizer.CurrentToken.Text}'";
                recognizer.NotifyErrorListeners(recognizer.CurrentToken, msg, null);
            }
            else
            {
                base.ReportUnwantedToken(recognizer);
            }
        }

        protected override void ReportNoViableAlternative(Parser recognizer, NoViableAltException e)
        {
            var expectedTokens = GetExpectedTokens(recognizer).ToString(recognizer.Vocabulary);
            NotifyErrorListeners(recognizer,$"Found unexpected token '{e.OffendingToken.Text}' and doesn't know how to continue.", e);
        }

        protected override void ReportFailedPredicate(Parser recognizer, FailedPredicateException e)
        {
            NotifyErrorListeners(recognizer, e.Message, (RecognitionException) e);
        }

        public override void Recover(Parser recognizer, RecognitionException e)
        {
            //do not "skip" existing errors, report and continue, perhaps we have more than one error?
            base.ReportError(recognizer, e); 
            base.Recover(recognizer, e);
        }
    }
}
