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
            var expectedTokens = string.Join(",",
                e.GetExpectedTokens().ToIntegerList().Select(tokenType =>
                    $"'{recognizer.Vocabulary.GetSymbolicName(tokenType).Humanize().ToLowerInvariant()}'"));
            var msg = $"Found unrecognized input. Expected the input to be one of the following: {expectedTokens}";

            NotifyErrorListeners(recognizer, msg, e);
        }

        private IEnumerable<string> GetTokenNames(Parser recognizer, IntervalSet intervalSet)
        {
            foreach (var tokenType in intervalSet.ToIntegerList())
                yield return recognizer.Vocabulary.GetSymbolicName(tokenType);
        }
    }
}
