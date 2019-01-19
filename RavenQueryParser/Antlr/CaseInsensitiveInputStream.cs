using Antlr4.Runtime;

namespace RavenQueryParser.Antlr
{
    //credit: https://gist.github.com/sharwell/9424666
    public class CaseInsensitiveInputStream : AntlrInputStream
    {
        // ReSharper disable once IdentifierTypo
        private readonly char[] _lookaheadData;

        public CaseInsensitiveInputStream(string input) : base(input) {            
            _lookaheadData = input.ToLower().ToCharArray();
        }

        public override int La(int i) {
            if (i == 0)
                return 0;

            if (i < 0) 
            {
                i++; 
                if ((p + i - 1) < 0) {
                    return Lexer.Eof; // invalid; no char before first char
                }
            }

            return (p + i - 1) >= n ? Lexer.Eof : _lookaheadData[p + i - 1];
        }

    }
}
