﻿using System.Linq;
using Antlr4.Runtime;
using RavenQueryParser.Antlr;
using RavenQueryParser.Extensions;
using Xunit;

namespace RavenQueryParser.Tests
{
  public class ParserSyntaxTests
    {
        private SyntaxErrorListener _errorListener = new SyntaxErrorListener ();

        [Fact]
        public void Error_on_empty_from_patch()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from update {}"))));
            parser.AddErrorListener(_errorListener);
            parser.patch();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("index or collection name", _errorListener.Errors[0].Message);

            _errorListener = new SyntaxErrorListener();
            parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from foobar update {}"))));
            parser.patch();
            Assert.Empty(_errorListener.Errors);
        }
        
        [Fact]
        public void Error_on_empty_from_query()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from"))));
            parser.AddErrorListener(_errorListener);
            parser.query();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("index or collection name", _errorListener.Errors[0].Message);

            _errorListener = new SyntaxErrorListener();
            parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from foobar"))));
            parser.query();
            Assert.Empty(_errorListener.Errors);
        }

        [Fact]
        public void Error_on_missing_index_name()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from index"))));
            parser.AddErrorListener(_errorListener);
            parser.query();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("index name", _errorListener.Errors[0].Message);

            _errorListener = new SyntaxErrorListener();
            parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("from index 'foo/bar'"))));
            parser.AddErrorListener(_errorListener);
            parser.query();
            Assert.Empty(_errorListener.Errors);
        }

        [Fact]
        public void Can_parse_transform_function()
        {
            var parser = new QueryParser(
                new CommonTokenStream(
                    new QueryLexer(
                        new AntlrInputStream("declare function foo(a,b) { return a + b; }"))));

            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Empty(_errorListener.Errors);

            Assert.Equal("foo", ast.functionName.Text);
            
            Assert.True(ast.javascriptBlock().sourceCode.TryGetChild<QueryParser.ReturnStatementContext>(out _));

            Assert.True(ast.javascriptBlock().TryGetChild<QueryParser.JavascriptAdditiveExpressionContext>(out var returnedExpression));
            var identifiers = returnedExpression.GetAllChildrenOfType<QueryParser.JavascriptIdentifierExpressionContext>().ToList();

            Assert.Equal(2, identifiers.Count);
            Assert.Equal("a", identifiers[0].GetText());
            Assert.Equal("b", identifiers[1].GetText());
        }

        [Fact]
        public void Should_throw_if_missing_function_name()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function (a,b) { return a + b; }"))));
            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("function name", _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_if_missing_opening_paren()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function foo a,b) { return a + b; }"))));
            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains('(', _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_if_missing_closing_paren()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function foo (a,b { return a + b; }"))));
            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains(')', _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_if_missing_comma()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function foo (a b) { return a + b; }"))));
            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains(',', _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_twice_if_missing_two_commas()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function foo (a b c) { return a + b; }"))));
            parser.AddErrorListener(_errorListener);
            parser.projectionFunctionClause();
            Assert.Equal(2, _errorListener.Errors.Count);

            Assert.Contains(',', _errorListener.Errors[0].Message);
            Assert.Contains(',', _errorListener.Errors[1].Message);
        }

        [Fact]
        public void Should_throw_if_missing_function_definition()
        {
            var parser = new QueryParser(new CommonTokenStream(new QueryLexer(new AntlrInputStream("declare function"))));
            parser.AddErrorListener(_errorListener);
            var ast = parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("function definition", _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_if_missing_curly_beginning()
        {
            var parser =
                new QueryParser(new CommonTokenStream(
                    new QueryLexer(new AntlrInputStream("declare function foo(a,b) { return a + b; "))));
            parser.AddErrorListener(_errorListener);
            parser.projectionFunctionClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains('}', _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_if_missing_curly_end()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("declare function foo(a,b) return a + b; }"))));

            parser.AddErrorListener(_errorListener);
            parser.projectionFunctionClause();
            Assert.NotEmpty(_errorListener.Errors);
            Assert.Contains('{', _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_parse_load_clause()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load foo as x, bar as y"))));

            parser.AddErrorListener(_errorListener);
            var loadAst = parser.loadClause();
            Assert.Empty(_errorListener.Errors);

            var identifiers = loadAst._params.Select(x => x.identifier.GetText()).ToList();
            Assert.Contains("foo", identifiers);
            Assert.Contains("bar", identifiers);

            var aliases = loadAst._params.Select(x => x.aliasClause().alias.Text).ToList();
            Assert.Contains("x", aliases);
            Assert.Contains("y", aliases);
        }

        [Fact]
        public void Should_throw_on_load_without_identifiers()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load"))));

            parser.AddErrorListener(_errorListener);
            var loadAst = parser.loadClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("one or more document id(s)", _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_on_load_missing_alias()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load foo"))));

            parser.AddErrorListener(_errorListener);
            var loadAst = parser.loadClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("alias", _errorListener.Errors[0].Message);
        }

        [Fact]
        public void Should_throw_on_load_missing_identifier()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load as x"))));

            parser.AddErrorListener(_errorListener);
            parser.loadClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("document id", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Should_throw_on_load_missing_as_keyword()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load foo x"))));

            parser.AddErrorListener(_errorListener);
            parser.loadClause();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'as'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Should_throw_on_load_missing_comma()
        {
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("load as x bar as y"))));

            parser.AddErrorListener(_errorListener);
            parser.loadClause();
            Assert.Equal(2, _errorListener.Errors.Count);
            Assert.Contains("document id", _errorListener.Errors[0].Message);
            Assert.Contains("','", _errorListener.Errors[1].Message);
        }

        [Fact]
        public void Can_parse_between_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x between 0 and 5"))));
            parser.AddErrorListener(_errorListener);

            var ast = parser.conditionExpression();
            Assert.Empty(_errorListener.Errors);

            Assert.True(ast.TryGetChild<QueryParser.QueryIdentifierExpressionContext>(out var identifierContext));
            Assert.Equal("x",identifierContext.GetText());

            var literals = ast.GetAllChildrenOfType<QueryParser.QueryLiteralContext>().Select(x => x.GetText()).ToArray();
            
            Assert.Equal(2, literals.Length);
            Assert.Contains("0", literals);
            Assert.Contains("5", literals);
        }
        
        [Fact]
        public void Throw_error_on_missing_from_in_between_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x between and 5"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'from'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_to_in_between_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x between 1 and"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'to'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_and_in_between_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x between 1 4"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'and'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_to_and_from_in_between_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x between"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'from'", _errorListener.Errors[0].Message);
            Assert.Contains("'to'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Can_parse_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x in (0,2,4)"))));
            parser.AddErrorListener(_errorListener);

            var ast = parser.conditionExpression();
            Assert.Empty(_errorListener.Errors);

            Assert.True(ast.TryGetChild<QueryParser.QueryIdentifierExpressionContext>(out var identifierContext));
            Assert.Equal("x",identifierContext.GetText());

            var literals = ast.GetAllChildrenOfType<QueryParser.QueryLiteralContext>().Select(x => x.GetText()).ToArray();
            
            Assert.Equal(3, literals.Length);
            Assert.Contains("0", literals);
            Assert.Contains("2", literals);
            Assert.Contains("4", literals);
        }
        
        [Fact]
        public void Can_parse_all_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x all in (0,2,4)"))));
            parser.AddErrorListener(_errorListener);

            var ast = parser.conditionExpression();
            Assert.Empty(_errorListener.Errors);

            Assert.True(ast.TryGetChild<QueryParser.QueryIdentifierExpressionContext>(out var identifierContext));
            Assert.Equal("x",identifierContext.GetText());

            var literals = ast.GetAllChildrenOfType<QueryParser.QueryLiteralContext>().Select(x => x.GetText()).ToArray();
            
            Assert.Equal(3, literals.Length);
            Assert.Contains("0", literals);
            Assert.Contains("2", literals);
            Assert.Contains("4", literals);
        }
        
        [Fact]
        public void Throw_error_on_missing_comma_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x in (0 2)"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("','", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_keyword_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x (0,2)"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'in'", _errorListener.Errors[0].Message);
            Assert.Contains("'all in'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_left_bracket_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x in 0,2,4)"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'('", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_left_bracket_all_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x all in 0,2,4)"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("'('", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_right_bracket_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x in (0,2,4"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("')'", _errorListener.Errors[0].Message);
        }
        
        [Fact]
        public void Throw_error_on_missing_right_bracket_all_in_expression()
        {
            //conditionExpression
            var parser =
                new QueryParser(
                    new CommonTokenStream(
                        new QueryLexer(new AntlrInputStream("x all in (0,2,4"))));
            parser.AddErrorListener(_errorListener);

            parser.conditionExpression();
            Assert.Single(_errorListener.Errors);
            Assert.Contains("')'", _errorListener.Errors[0].Message);
        }
    }
}
