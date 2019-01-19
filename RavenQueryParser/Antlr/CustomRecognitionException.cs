using Antlr4.Runtime;

namespace RavenQueryParser.Antlr
{
    public class CustomRecognitionException : RecognitionException
    {
        public void SetOffendingToken(IToken token)
        {
            OffendingToken = token;
        }

        public CustomRecognitionException(string message, IRecognizer recognizer, IIntStream input, ParserRuleContext ctx) : base(message, recognizer, input, ctx)
        {
        }
    }
}
