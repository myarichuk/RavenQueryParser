using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Antlr4.Runtime;
using Antlr4.Runtime.Misc;
using Humanizer;

namespace RavenQueryParser
{
    public class UserFriendlyErrorStrategy : DefaultErrorStrategy
    {
        public override void ReportError(Parser recognizer, RecognitionException e)
        {
            if (this.InErrorRecoveryMode(recognizer))
                return;

            base.ReportError(recognizer, e);
        }

        protected override void ReportInputMismatch(Parser recognizer, InputMismatchException e)
        {
            var expectedTokens = string.Join(",",
                e.GetExpectedTokens().ToIntegerList().Select(tokenType =>
                    $"'{recognizer.Vocabulary.GetSymbolicName(tokenType).Humanize().ToLowerInvariant()}'"));
            var msg = $"Found unrecognized input. Expected the input to be one of the following: {expectedTokens}";

            NotifyErrorListeners(recognizer, msg, e);
        }     
    }
}
