using System.Collections.Generic;
using Antlr4.Runtime;
using Antlr4.Runtime.Tree;

namespace RavenQueryParser.Extensions
{
    public static class ContextExtensions
    {
        public static bool TryGetChild<TContext>(this ParserRuleContext context, out TContext result)
            where TContext : ParserRuleContext
        {
            result = default;

            if (context is TContext typedContext)
            {
                result = typedContext;
                return true;
            }

            foreach (var childContext in context.children)
            {
                switch (childContext)
                {
                    case TerminalNodeImpl _:
                        continue;
                    case TContext typedChildContext:
                        result = typedChildContext;
                        return true;
                }

                if (((ParserRuleContext)childContext).TryGetChild(out result))
                {
                    return true;
                }
            }

            return false;
        }

        public static IEnumerable<TContext> GetAllChildrenOfType<TContext>(this ParserRuleContext context)
            where TContext : ParserRuleContext
        {
            foreach (var childContext in context.children)
            {
                switch (childContext)
                {
                    case TerminalNodeImpl _:
                        continue;
                    case TContext typedChildContext:
                        yield return typedChildContext;
                        continue;
                }

                foreach (var ctx in ((ParserRuleContext) childContext).GetAllChildrenOfType<TContext>())
                    yield return ctx;
            }
        }

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
