using Antlr4.Runtime;

namespace RavenQueryParser
{
    public class SyntaxError
    {
        public SyntaxError(IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, string message, RecognitionException recognitionException)
        {
            Recognizer = recognizer;
            OffendingSymbol = offendingSymbol;
            Line = line;
            CharPositionInLine = charPositionInLine;
            Message = message;
            RecognitionException = recognitionException;
        }

        public IRecognizer Recognizer { get; }
        public IToken OffendingSymbol { get; }
        public int Line { get; }
        public int CharPositionInLine { get; }
        public string Message { get; }
        public RecognitionException RecognitionException { get; }

        public override string ToString() => $"{Message}, {nameof(Line)}: {Line}, Character Position: {CharPositionInLine}, Offending Symbol: {OffendingSymbol.Text}";
    }    
}
