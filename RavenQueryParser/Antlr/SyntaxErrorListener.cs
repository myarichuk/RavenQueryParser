using System.Collections.Generic;
using Antlr4.Runtime;
using Antlr4.Runtime.Atn;
using Antlr4.Runtime.Dfa;
using Antlr4.Runtime.Misc;
using Antlr4.Runtime.Sharpen;

namespace RavenQueryParser.Antlr
{
	public class SyntaxErrorListener : BaseErrorListener
	{
		private readonly List<SyntaxError> _errors = new List<SyntaxError>();
		public IReadOnlyList<SyntaxError> Errors => _errors;

		public override void SyntaxError(IRecognizer recognizer, IToken offendingSymbol, int line, int charPositionInLine, string msg,
			RecognitionException e)
		{
			_errors.Add(new SyntaxError(recognizer,offendingSymbol,line,charPositionInLine,msg, e));
		}

		public void Reset() => _errors.Clear();

		public override void ReportAmbiguity(Parser recognizer, DFA dfa, int startIndex, int stopIndex, bool exact, BitSet ambiguousAlts,
			ATNConfigSet configs)
		{
			if(!exact)
				return;

			var msg = string.Format("Parsing error, ambiguous syntax detected: {0}, found at input='{1}'", new object[]
			{
				GetConflictingAlts(ambiguousAlts, configs),
				((ITokenStream) recognizer.InputStream).GetText(Interval.Of(startIndex, stopIndex))
			});

			recognizer.NotifyErrorListeners(msg);
		}     

		protected BitSet GetConflictingAlts(BitSet reportedAlts, ATNConfigSet configSet) => reportedAlts ?? configSet.ConflictingAlts;
	}
}
