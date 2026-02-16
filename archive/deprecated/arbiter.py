#!/usr/bin/env python3
"""
Arbiter - Propositional Logic Compression Engine
Simplified port for Claude Code context compression.

Grammar:
    fact          := identifier
    negation      := '!' expr
    conjunction   := expr '&' expr
    disjunction   := expr '|' expr
    implication   := expr '->' expr
    equivalence   := expr '<->' expr
    expr          := fact | negation | conjunction | disjunction | '(' expr ')'

Identifiers: snake_case only
One statement per line
Comments: lines starting with #
"""

from dataclasses import dataclass
from typing import List, Set, Optional, Union
import re


# ============================================================================
# AST NODES
# ============================================================================

@dataclass(frozen=True, eq=True)
class Var:
    """Propositional variable (fact)."""
    name: str

    def __hash__(self):
        return hash(self.name)

    def __repr__(self):
        return self.name


@dataclass(frozen=True, eq=True)
class Not:
    """Negation."""
    expr: 'Expr'

    def __hash__(self):
        return hash(('not', self.expr))

    def __repr__(self):
        return f"!{self.expr}"


@dataclass(frozen=True, eq=True)
class And:
    """Conjunction."""
    left: 'Expr'
    right: 'Expr'

    def __hash__(self):
        return hash(('and', self.left, self.right))

    def __repr__(self):
        return f"({self.left} & {self.right})"


@dataclass(frozen=True, eq=True)
class Or:
    """Disjunction."""
    left: 'Expr'
    right: 'Expr'

    def __hash__(self):
        return hash(('or', self.left, self.right))

    def __repr__(self):
        return f"({self.left} | {self.right})"


@dataclass(frozen=True, eq=True)
class Implies:
    """Implication."""
    antecedent: 'Expr'
    consequent: 'Expr'

    def __hash__(self):
        return hash(('implies', self.antecedent, self.consequent))

    def __repr__(self):
        return f"({self.antecedent} -> {self.consequent})"


@dataclass(frozen=True, eq=True)
class Iff:
    """Equivalence (if and only if)."""
    left: 'Expr'
    right: 'Expr'

    def __hash__(self):
        return hash(('iff', self.left, self.right))

    def __repr__(self):
        return f"({self.left} <-> {self.right})"


Expr = Union[Var, Not, And, Or, Implies, Iff]


# ============================================================================
# PARSER
# ============================================================================

class ParseError(Exception):
    """Raised when parsing fails."""
    pass


class Parser:
    """Recursive descent parser for arbiter syntax."""

    IDENTIFIER = re.compile(r'^[a-z][a-z0-9_]*$')

    def __init__(self, text: str):
        self.text = text.strip()
        self.pos = 0

    def peek(self, length: int = 1) -> str:
        """Look ahead without consuming."""
        return self.text[self.pos:self.pos + length]

    def consume(self, length: int = 1) -> str:
        """Consume and return characters."""
        result = self.text[self.pos:self.pos + length]
        self.pos += length
        return result

    def skip_whitespace(self):
        """Skip whitespace characters."""
        while self.pos < len(self.text) and self.text[self.pos] in ' \t':
            self.pos += 1

    def at_end(self) -> bool:
        """Check if at end of input."""
        return self.pos >= len(self.text)

    def parse_identifier(self) -> str:
        """Parse an identifier."""
        self.skip_whitespace()
        start = self.pos
        while self.pos < len(self.text) and (self.text[self.pos].isalnum() or self.text[self.pos] == '_'):
            self.pos += 1

        if start == self.pos:
            raise ParseError(f"Expected identifier at position {self.pos}")

        identifier = self.text[start:self.pos]
        if not self.IDENTIFIER.match(identifier):
            raise ParseError(f"Invalid identifier '{identifier}' - must be snake_case")

        return identifier

    def parse_primary(self) -> Expr:
        """Parse primary expression (variable, negation, or parenthesized)."""
        self.skip_whitespace()

        if self.at_end():
            raise ParseError("Unexpected end of input")

        # Negation
        if self.peek() == '!':
            self.consume()
            return Not(self.parse_primary())

        # Parenthesized expression
        if self.peek() == '(':
            self.consume()
            expr = self.parse_expr()
            self.skip_whitespace()
            if self.peek() != ')':
                raise ParseError(f"Expected ')' at position {self.pos}")
            self.consume()
            return expr

        # Variable
        identifier = self.parse_identifier()
        return Var(identifier)

    def parse_conjunction(self) -> Expr:
        """Parse conjunction (& operator)."""
        left = self.parse_primary()

        while True:
            self.skip_whitespace()
            if self.peek() == '&':
                self.consume()
                right = self.parse_primary()
                left = And(left, right)
            else:
                break

        return left

    def parse_disjunction(self) -> Expr:
        """Parse disjunction (| operator)."""
        left = self.parse_conjunction()

        while True:
            self.skip_whitespace()
            if self.peek() == '|':
                self.consume()
                right = self.parse_conjunction()
                left = Or(left, right)
            else:
                break

        return left

    def parse_expr(self) -> Expr:
        """Parse full expression (including implications and equivalences)."""
        left = self.parse_disjunction()

        self.skip_whitespace()

        # Check for implication or equivalence
        if self.peek(3) == '<->':
            self.consume(3)
            right = self.parse_disjunction()
            return Iff(left, right)
        elif self.peek(2) == '->':
            self.consume(2)
            right = self.parse_disjunction()
            return Implies(left, right)

        return left

    def parse(self) -> Expr:
        """Parse complete expression."""
        expr = self.parse_expr()
        self.skip_whitespace()
        if not self.at_end():
            raise ParseError(f"Unexpected characters at position {self.pos}: '{self.text[self.pos:]}'")
        return expr


def parse(text: str) -> Expr:
    """Parse a single arbiter statement."""
    if not text or text.strip().startswith('#'):
        raise ParseError("Empty or comment line")
    return Parser(text).parse()


def parse_all(text: str) -> List[Expr]:
    """Parse multiple statements (one per line)."""
    statements = []
    for line_num, line in enumerate(text.split('\n'), 1):
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        try:
            statements.append(parse(line))
        except ParseError as e:
            raise ParseError(f"Line {line_num}: {e}")
    return statements


# ============================================================================
# COMPRESSION ENGINE
# ============================================================================

def get_variables(expr: Expr) -> Set[str]:
    """Extract all variable names from an expression."""
    if isinstance(expr, Var):
        return {expr.name}
    elif isinstance(expr, Not):
        return get_variables(expr.expr)
    elif isinstance(expr, Implies):
        return get_variables(expr.antecedent) | get_variables(expr.consequent)
    elif isinstance(expr, (And, Or, Iff)):
        return get_variables(expr.left) | get_variables(expr.right)
    return set()


def is_tautology(expr: Expr) -> bool:
    """Check if expression is a tautology (always true)."""
    variables = sorted(get_variables(expr))
    if not variables:
        return True

    # Truth table evaluation
    for i in range(2 ** len(variables)):
        assignment = {var: bool((i >> j) & 1) for j, var in enumerate(variables)}
        if not evaluate(expr, assignment):
            return False
    return True


def is_contradiction(expr: Expr) -> bool:
    """Check if expression is a contradiction (always false)."""
    variables = sorted(get_variables(expr))
    if not variables:
        return False

    # Truth table evaluation
    for i in range(2 ** len(variables)):
        assignment = {var: bool((i >> j) & 1) for j, var in enumerate(variables)}
        if evaluate(expr, assignment):
            return False
    return True


def evaluate(expr: Expr, assignment: dict) -> bool:
    """Evaluate expression under given variable assignment."""
    if isinstance(expr, Var):
        return assignment.get(expr.name, False)
    elif isinstance(expr, Not):
        return not evaluate(expr.expr, assignment)
    elif isinstance(expr, And):
        return evaluate(expr.left, assignment) and evaluate(expr.right, assignment)
    elif isinstance(expr, Or):
        return evaluate(expr.left, assignment) or evaluate(expr.right, assignment)
    elif isinstance(expr, Implies):
        return (not evaluate(expr.antecedent, assignment)) or evaluate(expr.consequent, assignment)
    elif isinstance(expr, Iff):
        return evaluate(expr.left, assignment) == evaluate(expr.right, assignment)
    return False


def implies_semantically(facts: List[Expr], expr: Expr) -> bool:
    """Check if facts semantically imply expr."""
    all_vars = set()
    for fact in facts:
        all_vars |= get_variables(fact)
    all_vars |= get_variables(expr)

    if not all_vars:
        return True

    variables = sorted(all_vars)

    # Check: for all assignments where facts are true, expr must be true
    for i in range(2 ** len(variables)):
        assignment = {var: bool((i >> j) & 1) for j, var in enumerate(variables)}

        # Check if all facts are satisfied
        all_facts_true = all(evaluate(fact, assignment) for fact in facts)

        if all_facts_true:
            # If facts are true but expr is false, facts don't imply expr
            if not evaluate(expr, assignment):
                return False

    return True


def compress(statements: List[Expr]) -> List[Expr]:
    """
    Compress statements by removing redundancies.

    v0: Simple deduplication only.
    Future: Add tautology removal and semantic redundancy checking
    with more efficient algorithms (SAT solvers).
    """
    # Remove exact duplicates while preserving order
    seen = set()
    compressed = []

    for stmt in statements:
        if stmt not in seen:
            seen.add(stmt)
            compressed.append(stmt)

    return compressed


# ============================================================================
# FORMATTER
# ============================================================================

def format_expr(expr: Expr, parent_precedence: int = 0) -> str:
    """Format expression as arbiter syntax."""
    if isinstance(expr, Var):
        return expr.name
    elif isinstance(expr, Not):
        inner = format_expr(expr.expr, 3)
        return f"!{inner}"
    elif isinstance(expr, And):
        left = format_expr(expr.left, 2)
        right = format_expr(expr.right, 2)
        result = f"{left} & {right}"
        return f"({result})" if parent_precedence > 2 else result
    elif isinstance(expr, Or):
        left = format_expr(expr.left, 1)
        right = format_expr(expr.right, 1)
        result = f"{left} | {right}"
        return f"({result})" if parent_precedence > 1 else result
    elif isinstance(expr, Implies):
        left = format_expr(expr.antecedent, 0)
        right = format_expr(expr.consequent, 0)
        return f"{left} -> {right}"
    elif isinstance(expr, Iff):
        left = format_expr(expr.left, 0)
        right = format_expr(expr.right, 0)
        return f"{left} <-> {right}"
    return str(expr)


def format_facts(statements: List[Expr]) -> str:
    """Format list of statements as arbiter syntax."""
    return '\n'.join(format_expr(stmt) for stmt in statements)


# ============================================================================
# CLI
# ============================================================================

def main():
    """CLI entry point."""
    import sys

    if len(sys.argv) < 2:
        print("Usage: arbiter.py <input_file>")
        print("Reads arbiter syntax, validates, and compresses.")
        sys.exit(1)

    input_file = sys.argv[1]

    try:
        with open(input_file) as f:
            text = f.read()

        # Parse
        statements = parse_all(text)
        print(f"Parsed {len(statements)} statements", file=sys.stderr)

        # Check for contradictions
        for stmt in statements:
            if is_contradiction(stmt):
                print(f"WARNING: Contradiction detected: {format_expr(stmt)}", file=sys.stderr)

        # Compress
        compressed = compress(statements)
        print(f"Compressed to {len(compressed)} statements", file=sys.stderr)

        # Output
        print(format_facts(compressed))

    except ParseError as e:
        print(f"Parse error: {e}", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
