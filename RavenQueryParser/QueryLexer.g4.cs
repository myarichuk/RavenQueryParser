﻿using Antlr4.Runtime;

namespace RavenQueryParser
{
    partial class QueryLexer
    {
        public override void Recover(LexerNoViableAltException e)
        {
            NotifyListeners(e);
            base.Recover(e);
        }      
    }
}
