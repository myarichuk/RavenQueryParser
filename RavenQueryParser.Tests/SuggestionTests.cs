using System.Linq;
using Antlr4.Runtime;
using RavenQueryParser.Antlr;
using Xunit;

namespace RavenQueryParser.Tests
{
    public class SuggestionTests
    {
        [Fact]
        public void Can_find_suggestions_at_empty_input()
        {
            var input = string.Empty;
            var lexer = new QueryLexer(new CaseInsensitiveInputStream(input));
            var parser = new QueryParser(new CommonTokenStream(lexer));
            var suggester = new TokenSuggester(parser);

            Assert.NotEmpty(suggester.Suggest(0)); //sanity check
            var tokenNames = suggester.Suggestions.Select(type => lexer.Vocabulary.GetSymbolicName(type)).ToArray();
            Assert.Equal(4, suggester.Suggestions.Count);
            Assert.Contains("MATCH", tokenNames);
            Assert.Contains("FROM", tokenNames);
            Assert.Contains("WITH", tokenNames);
            Assert.Contains("DECLARES_FUNCTION", tokenNames);
        }

        [Fact]
        public void Can_find_suggestions_after_from()
        {
            var input = "from";
            var lexer = new QueryLexer(new CaseInsensitiveInputStream(input));
            var parser = new QueryParser(new CommonTokenStream(lexer));
            var suggester = new TokenSuggester(parser);

            Assert.NotEmpty(suggester.Suggest(1)); //sanity check
            var tokenNames = suggester.Suggestions.Select(type => lexer.Vocabulary.GetSymbolicName(type)).ToArray();
            Assert.Equal(3, suggester.Suggestions.Count);
            Assert.Contains("IDENTIFIER", tokenNames);
            Assert.Contains("STRING", tokenNames);
            Assert.Contains("INDEX", tokenNames);
            Assert.Contains("ALL_DOCS", tokenNames);
        }

    }
}
