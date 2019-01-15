using System;
using System.ComponentModel.Design;
using System.IO;
using System.Linq;
using System.Reactive.Linq;
using System.Text;
using System.Windows;
using System.Windows.Media;
using System.Xml;
using Antlr4.Runtime;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using RavenQuery.SyntaxTester.SharpDevelop;
using RavenQueryParser;

namespace RavenQuery.SyntaxTester
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        private readonly QueryLexer _lexer;
        private readonly QueryParser _parser;
        private readonly SyntaxErrorListener _errorListener = new SyntaxErrorListener();
        private ITextMarkerService _textMarkerService;

        public MainWindow()
        {
            InitializeComponent();
            var xshdAsString = ManifestResource.Load("RavenQuery.SyntaxTester.RQLSyntaxHighlighting.xshd");

            using (var reader = new XmlTextReader(new StringReader(xshdAsString)))
            {
                var editorSyntaxHighlighting = HighlightingLoader.Load(reader, HighlightingManager.Instance);
                HighlightingManager.Instance.RegisterHighlighting("RQL", new[] {".rql"}, editorSyntaxHighlighting);
            }

            CodeEditor.SyntaxHighlighting = HighlightingManager.Instance.GetDefinition("RQL");
            _lexer = new QueryLexer(null);
            _parser = new QueryParser(null);
            _parser.ErrorHandler = new UserFriendlyErrorStrategy();
            _parser.AddErrorListener(_errorListener);

            Observable.FromEventPattern(
                    ev => CodeEditor.TextChanged += ev,
                    ev => CodeEditor.TextChanged -= ev)
                .Throttle(TimeSpan.FromMilliseconds(750))                
                .Subscribe(_ => Dispatcher.InvokeAsync(ParseRQL));
            InitializeTextMarkerService();
        }

        void InitializeTextMarkerService()
        {
            var textMarkerService = new TextMarkerService(CodeEditor.Document);
            CodeEditor.TextArea.TextView.BackgroundRenderers.Add(textMarkerService);
            CodeEditor.TextArea.TextView.LineTransformers.Add(textMarkerService);
            var services = (IServiceContainer)CodeEditor.Document.ServiceProvider.GetService(typeof(IServiceContainer));
            services?.AddService(typeof(ITextMarkerService), textMarkerService);

            _textMarkerService = textMarkerService;
            
        }

        private void ParseRQL()
        {           
             _textMarkerService.RemoveAll(m => true);
            _errorListener.Reset();
            _lexer.SetInputStream(new AntlrInputStream(CodeEditor.Text));
            _parser.SetInputStream(new CommonTokenStream(_lexer));
            _parser.query();

            var errors = _errorListener.SyntaxErrors.Aggregate(new StringBuilder(), (sb, err) => 
                sb.AppendLine(err.ToString().Replace("\\n"," ")
                                            .Replace("\\r"," ")
                                            .Replace("\\t"," "))).ToString();
            AddSquigglies();
            Errors.Text = errors;
        }

        private void AddSquigglies()
        {
            foreach (var error in _errorListener.SyntaxErrors)
            {                
                var lineOffset = CodeEditor.Document.Lines[error.Line - 1].Offset;
                var length = error.OffendingSymbol.Text == "<EOF>" ? 0 : error.OffendingSymbol.Text.Length;
                var marker = _textMarkerService.Create(lineOffset + error.CharPositionInLine, length);
                marker.MarkerTypes = TextMarkerTypes.SquigglyUnderline;
                marker.MarkerColor = Colors.Red;

            }
        }
    }
}
