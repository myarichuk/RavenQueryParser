using Antlr4.Runtime;

namespace RavenQueryParser.ErrorHandlers.UnwantedTokenHandlers
{
    public interface IUnwantedTokenHandler
    {
        bool ShouldHandle(Parser recognizer);
        void Handle(Parser recognizer);
    }
}
