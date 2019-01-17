using System.Collections.Generic;
using System.Linq;
using Antlr4.Runtime;
using Antlr4.Runtime.Misc;
using Humanizer;

namespace RavenQueryParser
{
    public class UserFriendlyErrorStrategy : DefaultErrorStrategy
    {                     
        protected override void ReportInputMismatch(Parser recognizer, InputMismatchException e)
        {
            var msg = string.Empty;
            RecognitionException exceptionToThrow = null;
            var previousTokenType = recognizer.InputStream.La(-1);
            switch (recognizer.CurrentToken.Type)
            {
                case QueryLexer.WHERE when previousTokenType == QueryLexer.FROM:
                    break;
                default:
                    var expectedTokens = string.Join(",",
                        e.GetExpectedTokens().ToIntegerList().Select(tokenType =>
                            $"'{recognizer.Vocabulary.GetSymbolicName(tokenType).Humanize().ToLowerInvariant()}'"));

                    msg = $"Found unrecognized input. Expected the input to be one of the following: {expectedTokens}";
                    exceptionToThrow = e;
                    break;
            }

            NotifyErrorListeners(recognizer, msg, exceptionToThrow);
        }

        private IEnumerable<string> GetTokenNames(Parser recognizer, IntervalSet intervalSet)
        {
            foreach (var tokenType in intervalSet.ToIntegerList())
                yield return recognizer.Vocabulary.GetSymbolicName(tokenType);
        }
    }
}
