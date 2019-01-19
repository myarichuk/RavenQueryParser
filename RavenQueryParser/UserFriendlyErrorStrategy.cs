using Antlr4.Runtime;
using Castle.MicroKernel.Registration;
using Castle.Windsor;
using RavenQueryParser.ErrorHandlers.InputMismatchHandlers;
using RavenQueryParser.ErrorHandlers.UnwantedTokenHandlers;

namespace RavenQueryParser
{
    public class UserFriendlyErrorStrategy : DefaultErrorStrategy
    {
        private static readonly WindsorContainer _container = new WindsorContainer();

        private readonly IInputMismatchHandler[] _inputMismatchErrorHandlers;
        private readonly IUnwantedTokenHandler[] _unwantedTokenHandlers;

        static UserFriendlyErrorStrategy()
        {
            _container.Register(
                Classes.FromAssemblyContaining<UserFriendlyErrorStrategy>()
                    .BasedOn<IInputMismatchHandler>()
                    .LifestyleSingleton()
                    .WithServiceAllInterfaces(),
                Classes.FromAssemblyContaining<UserFriendlyErrorStrategy>()
                    .BasedOn<IUnwantedTokenHandler>()
                    .LifestyleSingleton()
                    .WithServiceAllInterfaces()
                );
        }

        public UserFriendlyErrorStrategy()
        {
            _inputMismatchErrorHandlers = _container.ResolveAll<IInputMismatchHandler>();
            _unwantedTokenHandlers = _container.ResolveAll<IUnwantedTokenHandler>();
        }

        protected override void ReportMissingToken(Parser recognizer)
        {
            var currentToken = recognizer.CurrentToken;
            var msg = "missing " + GetExpectedTokens(recognizer).ToString(recognizer.Vocabulary) + " at " + GetTokenErrorDisplay(currentToken);
            
            var previousTokenType = recognizer.InputStream.La(-1);
            if (previousTokenType == QueryLexer.INDEX)
            {
                msg = "Missing index name after 'from index'. Note that index name is a string";
            }

            recognizer.NotifyErrorListeners(currentToken, msg, null);
        }

        protected override void ReportUnwantedToken(Parser recognizer)
        {
            foreach (var errorHandler in _unwantedTokenHandlers)
            {
                if (errorHandler.ShouldHandle(recognizer))
                {
                    errorHandler.Handle(recognizer);
                    return;
                }
            }

            //bit more user-friendly "catch all" error
            if (recognizer.InputStream.La(2) == QueryLexer.Eof) //next token type
            {
                var msg = $"Unrecognized token '{recognizer.CurrentToken.Text}'";
                recognizer.NotifyErrorListeners(recognizer.CurrentToken, msg, null);
            }
            else
            {
                base.ReportUnwantedToken(recognizer);
            }
        }

        protected override void ReportNoViableAlternative(Parser recognizer, NoViableAltException e)
        {
            base.ReportNoViableAlternative(recognizer, e);
        }

        protected override void ReportInputMismatch(Parser recognizer, InputMismatchException e)
        {
            foreach (var errorHandler in _inputMismatchErrorHandlers)
            {
                if (errorHandler.ShouldHandle(recognizer, e))
                {
                    errorHandler.Handle(recognizer,e);
                    return;
                }
            }

            base.ReportInputMismatch(recognizer,e);
        }
    }
}
