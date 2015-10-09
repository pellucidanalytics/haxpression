package haxpression;

import haxpression.ExpressionType;
import haxpression.ValueType;
using Lambda;
using StringTools;
using haxpression.Arrays;
using haxpression.ExpressionTypes;
using haxpression.Expressions;

abstract Expression<T>(ExpressionType<T>) {
  public function new(expressionType : ExpressionType<T>) {
    this = expressionType;
  }

  @:from
  public static function fromExpressionType(expressionType : ExpressionType<T>) {
    return new Expression(expressionType);
  }

  @:to
  public function toExpressionType() : ExpressionType<T> {
    return this;
  }

  @:from
  public static function fromString(input : String) : Expression<T> {
    return Parser.parse(input);
  }

  @:to
  public function toString() : String {
    return switch this {
      case Literal(value) : value.toString();
      case Identifier(name) : name;
      case Unary(operator, operand): '${operator}${getString(operand)}';
      case Binary(operator, left, right) : '(${getString(left)} $operator ${getString(right)})';
      case Call(callee, arguments): '${callee}(${getStringDelimited(arguments, ",")})';
      case Conditional(test, consequent, alternate) : '(${getString(test)} ? ${getString(consequent)} : ${getString(alternate)})';
      case Array(items): '[${getStringDelimited(items, ",")}]';
      case Compound(items): getStringDelimited(items, ";");
    };
  }

  public function toObject() : {} {
    return switch this {
      case Literal(value) : {
        type: "Literal",
        value: value.toDynamic() // allow the value to be passed-through with no conversion
      };
      case Identifier(name) : {
        type: "Identifier",
        name: name
      };
      case Unary(operator, operand) : {
        type: "Unary",
        operator: operator,
        operand: (operand : Expression).toObject()
      };
      case Binary(operator, left, right) : {
        type: "Binary",
        operator: operator,
        left: (left : Expression).toObject(),
        right: (right : Expression).toObject()
      };
      case Call(callee, arguments): {
        type: "Call",
        callee: callee,
        arguments: arguments.toObject()
      };
      case Conditional(test, consequent, alternate): {
        type: "Conditional",
        test: (test : Expression).toObject(),
        consequent: (consequent : Expression).toObject(),
        alternate: (alternate : Expression).toObject()
      };
      case Array(items) : {
        type: "Array",
        items: items.toObject()
      };
      case Compound(items) : {
        type: "Compound",
        items: items.toObject()
      };
    };
  }

  public function hasVariables() : Bool {
    return getVariables().length > 0;
  }

  public function hasVariablesStartingWith(text : String) {
    return getVariables().any(function(variable) {
      return variable.startsWith(text);
    });
  }

  public function hasVariablesContaining(text : String) {
    return getVariables().any(function(variable) {
      return variable.indexOf(text) != -1;
    });
  }

  public function hasVariablesEndingWith(text : String) {
    return getVariables().any(function(variable) {
      return variable.endsWith(text);
    });
  }

  public function getVariables() : Array<String> {
    var variables = [];
    accumulateVariables(variables);
    variables.sort(function(a, b) {
      a = a.toLowerCase();
      b = b.toLowerCase();
      return if (a > b) 1;
        else if (a < b) -1;
        else 0;
    });
    return variables;
  }

  public function clone() : Expression {
    return switch this {
      case Literal(value) :
        Literal(value);
      case Identifier(name) :
        Identifier(name);
      case Unary(operator, operand) :
        Unary(operator, (operand : Expression).clone());
      case Binary(operator, left, right) :
        Binary(operator, (left : Expression).clone(), (right : Expression).clone());
      case Call(callee, arguments) :
        Call(callee, arguments.clone());
      case Conditional(test, consequent, alternate) :
        Conditional((test : Expression).clone(), (consequent : Expression).clone(), (alternate : Expression).clone());
      case Array(items) :
        Array(items.clone());
      case Compound(items) :
        Compound(items.clone());
    };
  }

  public function substitute(variables : Map<String, ExpressionOrValue<T>>) : Expression {
    return switch this {
      case Literal(value):
        Literal(value);
      case Identifier(name):
        variables.exists(name) ? variables.get(name).toExpression() : Identifier(name);
      case Unary(operator, expression):
        Unary(operator, (expression : Expression).substitute(variables));
      case Binary(operator, left, right):
        Binary(operator, (left : Expression).substitute(variables), (right : Expression).substitute(variables));
      case Call(callee, arguments):
        Call(callee, arguments.substitute(variables));
      case Conditional(test, consequent, alternate):
        Conditional((test : Expression).substitute(variables), (consequent : Expression).substitute(variables), (alternate : Expression).substitute(variables));
      case Array(items):
        Array(items.substitute(variables));
      case Compound(items):
        Array(items.substitute(variables));
    };
  }

  public function evaluate(?variables : Map<String, Value>) : Value {
    if (variables == null) variables = new Map();

    return switch this {
      case Literal(value) :
        value;
      case Identifier(name):
        if (!variables.exists(name)) {
          throw new Error('cannot evaluate with unset variable: $name');
        }
        variables.get(name);
      case Unary(operator, argument):
        var argumentValue = (argument : Expression).evaluate(variables);
        UnaryOperations.evaluate(operator, argumentValue);
      case Binary(operator, left, right):
        var leftValue = (left : Expression).evaluate(variables);
        var rightValue = (right : Expression).evaluate(variables);
        BinaryOperations.evaluate(operator, leftValue, rightValue);
      case Call(callee, arguments):
        CallOperations.evaluate(callee, arguments.evaluate(variables));
      case Conditional(test, consequent, alternate):
        (test : Expression).evaluate(variables).toBool() ?
          (consequent : Expression).evaluate(variables) :
          (alternate : Expression).evaluate(variables);
      case Array(items):
        // We'll just assume the value of an array expression is the last value
        // or none if there are no items in the array
        if (items.length == 0) VNone;
        var values = items.evaluate(variables);
        values[values.length - 1];
      case Compound(items):
        // We'll just assume the value of an compound expression is the last value
        // or none if there are no items in the array
        if (items.length == 0) VNone;
        var values = items.evaluate(variables);
        values[values.length - 1];
    };
  }

  public function isCompound() : Bool {
    return switch toExpressionType() {
      case Compound(_) : true;
      case _: false;
    };
  }

  function accumulateVariables(variables : Array<String>) : Void {
    switch this {
      case Literal(value) :
        // no-op - no variables to accumulate here
      case Identifier(name) :
        // Push a variable if we haven't seen it already
        if (variables.indexOf(name) == -1) variables.push(name);
      case Unary(operator, operand):
        (operand : Expression).accumulateVariables(variables);
      case Binary(operator, left, right):
        (left : Expression).accumulateVariables(variables);
        (right : Expression).accumulateVariables(variables);
      case Call(callee, arguments):
        arguments.iter(function(expression) (expression : Expression).accumulateVariables(variables));
      case Conditional(test, consequent, alternate):
        (test : Expression).accumulateVariables(variables);
        (consequent : Expression).accumulateVariables(variables);
        (alternate : Expression).accumulateVariables(variables);
      case Array(items):
        items.iter(function(expression) (expression : Expression).accumulateVariables(variables));
      case Compound(items):
        items.iter(function(expression) (expression : Expression).accumulateVariables(variables));
    };
  }

  function getString(expressionType : ExpressionType) : String {
    return (expressionType : Expression).toString();
  }

  function getStringDelimited(expressionTypes : Array<ExpressionType>, delimiter : String) : String {
    delimiter = '${delimiter.trim()} ';
    return expressionTypes.map(function(expressionType) getString(expressionType)).join(delimiter);
  }
}
