package haxpression;

import utest.Assert;
import haxpression.ExpressionType;
using haxpression.AssertExpression;

class TestExpression {
  public function new() {
  }

  public function testToString() {
    (Binary("+", Literal(1), Literal(2)) : Expression).toStringSameAs("(1 + 2)");
    (Binary("+", Binary("+", Literal(1), Literal(2)), Literal(3)) : Expression).toStringSameAs("((1 + 2) + 3)");
  }

  public function testSubstituteValue() {
    var expr : Expression = Binary("+", Literal(1), Identifier("PI"));
    expr.substitute([ "PI" => Math.PI ]).evaluatesToFloat(1 + Math.PI);
  }

  public function testSubstituteExpression() {
    var expr : Expression = Binary("+", Literal(1), Identifier("PI"));
    expr = expr.substitute([ "PI" => '1 + 2 + 0.14' ]);
    expr.toStringSameAs('(1 + ((1 + 2) + 0.14))');
  }
}
