using System;
using System.Collections.Generic;
using System.Text;
using Antlr4.Runtime;

namespace RavenQueryParser
{
    public class SyntaxValidationVisitor : QueryParserBaseVisitor<IReadOnlyList<SyntaxError>>
    {
        private readonly List<SyntaxError> _errors = new List<SyntaxError>();
        private readonly QueryParser _parser;

        public SyntaxValidationVisitor(QueryParser parser)
        {
            _parser = parser;
        }

        // ReSharper disable UnusedAutoPropertyAccessor.Global
        public List<string> Collections { get; set; }
        public List<string> Indexes { get; set; }
        // ReSharper restore UnusedAutoPropertyAccessor.Global

        public void Reset() => _errors.Clear();

        public override IReadOnlyList<SyntaxError> VisitDocumentQuery(QueryParser.DocumentQueryContext context)
        {
            //var querySource = context.querySource();
            //if(querySource.indexName != null && 
            //   Indexes != null &&
            //   !Indexes.Contains(querySource.indexName.Text))
            //{
            //    var offendingSymbol = querySource.indexName;
            //    _errors.Add(new SyntaxError(_parser,offendingSymbol,offendingSymbol.Line,offendingSymbol.Column,$"'{offendingSymbol.Text}' is not an index",null));
            //}
            //else if(Collections != null)
            //{
            //    var collectionContext = querySource.collection();
            //    if (collectionContext.IDENTIFIER() != null)
            //    {
            //        var collectionName =
            //            $"{collectionContext.AT_SIGN().GetText() ?? string.Empty}{collectionContext.IDENTIFIER().GetText()}";
            //        if (!Collections.Contains(collectionName))
            //        {
            //            var offendingSymbol = collectionContext.stop;
            //            _errors.Add(new SyntaxError(_parser,offendingSymbol,offendingSymbol.Line,offendingSymbol.Column,$"'{offendingSymbol.Text}' is not an index",null));
            //        }
            //    }
            //}

            return base.VisitDocumentQuery(context);
        }
    }
}
