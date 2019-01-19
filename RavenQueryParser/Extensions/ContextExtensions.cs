using Antlr4.Runtime;

namespace RavenQueryParser.Extensions
{
    public static class ContextExtensions
    {
        public static bool HasParentOfType<TParent>(this RuleContext ctx) where TParent : class
        {
            if (ctx is TParent)
                return true;

            var current = ctx.parent;
            while (current != null)
            {
                if (current is TParent)
                    return true;
                current = ctx.parent;
            }

            return false;
        }
    }
}
