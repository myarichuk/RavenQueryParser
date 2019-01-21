using System;
using System.Collections.Generic;
using System.Linq;
using Antlr4.Runtime;
using Antlr4.Runtime.Atn;

namespace RavenQueryParser
{
    //adapted code from https://tomassetti.me/autocompletion-editor-antlr/
    public class TokenSuggester
    {        
        private readonly HashSet<int> _alreadyPassed = new HashSet<int>();
        private readonly HashSet<int> _suggestions = new HashSet<int>();
        private readonly Parser _recognizer;
        private readonly IReadOnlyList<IToken> _allTokens;
        private int _currentIndex;

        public TokenSuggester(Parser recognizer)
        {
            _recognizer = recognizer;

            var queryLexer = ((QueryLexer) ((ITokenStream)recognizer.InputStream).TokenSource);
            queryLexer.Reset();
            _allTokens = queryLexer.GetAllTokens().Where(x => x.Channel == 0).ToList();
            _currentIndex = 0;
        }

        public IReadOnlyCollection<int> Suggestions => _suggestions;

        public IReadOnlyCollection<int> Suggest(int suggestionIndex)
        {
            _suggestions.Clear();
            _alreadyPassed.Clear();
            Suggest(new ParserStack(), _recognizer.Atn.states[0], suggestionIndex);

            return _suggestions;
        }

        private void Suggest(ParserStack stack,ATNState state, int suggestionIndex)
        {
            var stackRes = stack.Process(state);
            if (!stackRes.isValid)
                return;

            foreach (var transition in state.Transitions)
            {
                if (transition.IsEpsilon && !_alreadyPassed.Contains(transition.target.stateNumber))
                {
                    _alreadyPassed.Add(transition.target.stateNumber);
                    Suggest(stackRes.parserStack, transition.target, suggestionIndex);
                }
                else switch (transition)
                {
                    case AtomTransition atomTransition when (_allTokens.Count == 0 || _currentIndex >= _allTokens.Count) && _currentIndex == suggestionIndex:
                    {
                        if(ParserStack.IsCompatible(transition.target, stack))
                            _suggestions.Add(atomTransition.label);
                        break;
                    }
                    case AtomTransition atomTransition:
                    {
                        var nextToken = _allTokens[_currentIndex];
                        if (_currentIndex == suggestionIndex && ParserStack.IsCompatible(transition.target, stack))
                        {
                            _suggestions.Add(atomTransition.label);
                        }
                        else if (nextToken.Type == atomTransition.label)
                        {
                            if (_currentIndex + 1 > _allTokens.Count)
                                return;
                            _currentIndex++;
                            Suggest(stackRes.parserStack, transition.target, suggestionIndex);
                        }

                        break;
                    }
                    case SetTransition setTransition when (_allTokens.Count == 0 || _currentIndex >= _allTokens.Count) && _currentIndex == suggestionIndex:
                    {
                        foreach (var tokenType in setTransition.Label.ToIntegerList())
                        {
                            if(ParserStack.IsCompatible(transition.target, stack))
                                _suggestions.Add(tokenType);                           
                        }

                        break;
                    }
                    case SetTransition setTransition:
                    {
                        var nextToken = _allTokens[_currentIndex];
                        foreach (var tokenType in setTransition.Label.ToIntegerList())
                        {
                            if (_currentIndex == suggestionIndex &&
                                ParserStack.IsCompatible(transition.target, stack))
                            {
                                _suggestions.Add(tokenType);
                            }
                            else if (nextToken.Type == tokenType)
                            {
                                if (_currentIndex + 1 > _allTokens.Count)
                                    return;

                                _currentIndex++;
                                Suggest(stackRes.parserStack, transition.target, suggestionIndex);
                            }
                        }

                        break;
                    }
                    default:
                        throw new NotSupportedException();
                }
            }
        }

        private class ParserStack
        {
            private IEnumerable<ATNState> States { get; }

            public ParserStack()
                : this(Enumerable.Empty<ATNState>())
            {
            }

            private ParserStack(IEnumerable<ATNState> states)
            {
                States = states;
            }

            public (bool isValid, ParserStack parserStack) Process(ATNState state)
            {
                switch (state)
                {
                    case RuleStartState _:
                    case StarBlockStartState _:
                    case BasicBlockStartState _:
                    case PlusBlockStartState _:
                    case StarLoopEntryState _:
                        return (true, new ParserStack(States.Append(state)));
                    case BlockEndState endState when ReferenceEquals(States.LastOrDefault(), endState.startState):
                        return (true, new ParserStack(States.Except(new[] {States.LastOrDefault()})));
                    case BlockEndState _:
                        return (false, this);
                    case LoopEndState  loopEndState when
                        States.LastOrDefault() is StarLoopEntryState &&
                        ReferenceEquals(((StarLoopEntryState)States.LastOrDefault())?.loopBackState,loopEndState.loopBackState):
                        return (true, new ParserStack(States.Except(new[] {States.LastOrDefault()})));
                    case LoopEndState _:
                        return (false, this);
                    case RuleStopState ruleStopState when 
                        States.LastOrDefault() is RuleStartState &&
                        ReferenceEquals(((RuleStartState)States.LastOrDefault())?.stopState,ruleStopState):
                        return (true, new ParserStack(States.Except(new[] {States.LastOrDefault()})));
                    case RuleStopState _:
                        return (false, this);
                    case BasicState _:
                    case StarLoopbackState _:
                    case PlusLoopbackState _:
                        return (true, this);
                    default:
                        throw new NotSupportedException();
                }
            }

            public static bool IsCompatible(ATNState state, ParserStack stack)
            {
                var processResult = stack.Process(state);
                if (!processResult.isValid)
                    return false;

                return !state.epsilonOnlyTransitions || 
                       state.Transitions.Any(transition => IsCompatible(transition.target, processResult.parserStack));
            }
        }
    }
}
