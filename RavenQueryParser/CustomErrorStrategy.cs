using Antlr4.Runtime;

namespace RavenQuery
{
    public class CustomErrorStrategy : DefaultErrorStrategy
    {
        protected override void ReportNoViableAlternative(Parser recognizer, NoViableAltException e)
        {
        }

        protected override void ReportInputMismatch(Parser recognizer, InputMismatchException e)
        {
        }

        protected override void ReportFailedPredicate(Parser recognizer, FailedPredicateException e)
        {
        }

        protected override void ReportUnwantedToken(Parser recognizer)
        {
        }

        protected override void ReportMissingToken(Parser recognizer)
        {
        }
    }
}
