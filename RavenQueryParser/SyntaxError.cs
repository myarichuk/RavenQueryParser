using Antlr4.Runtime;
using Humanizer;

namespace RavenQueryParser
{
    public class SyntaxError
    {
        public SyntaxError(IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, string message, RecognitionException thrownRecognitionException)
        {
            Recognizer = recognizer;
            OffendingSymbol = offendingSymbol;
            Line = line;
            CharPositionInLine = charPositionInLine;
            Message = message;
            ThrownRecognitionException1 = thrownRecognitionException;
        }

        public IRecognizer Recognizer { get; }
        public IToken OffendingSymbol { get; }
        public int Line { get; }
        public int CharPositionInLine { get; }
        public string Message { get; }
        public RecognitionException ThrownRecognitionException1 { get; }

        public override string ToString()
        {
            return $"{Message}, {nameof(Line)}: {Line}, {nameof(CharPositionInLine).Humanize()}: {CharPositionInLine}, {nameof(OffendingSymbol).Humanize()}: {OffendingSymbol.Text}";
        }
    }    
}
