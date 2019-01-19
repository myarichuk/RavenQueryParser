using Antlr4.Runtime;

namespace RavenQueryParser.ErrorHandlers.InputMismatchHandlers
{
    public interface IInputMismatchHandler
    {
        bool ShouldHandle(Parser recognizer, InputMismatchException e);
        void Handle(Parser recognizer, InputMismatchException e);
    }
}
