package haxpression;

class ExpressionTypes {
  public static function clone(expressionTypes : Array<ExpressionType>) : Array<ExpressionType> {
    return expressionTypes.map(function(expressionType) {
      return (expressionType : Expression).clone().toExpressionType();
    });
  }

  public static function evaluate(expressionTypes : Array<ExpressionType>, ?variables : Map<String, Value>) : Array<Value> {
    return expressionTypes.map(function(expressionType) {
      return (expressionType : Expression).evaluate(variables);
    });
  }

  public static function substitute(expressionTypes : Array<ExpressionType>, variables : Map<String, ExpressionOrValue>) : Array<ExpressionType> {
    return expressionTypes.map(function(expressionType) {
      return (expressionType : Expression).substitute(variables).toExpressionType();
    });
  }

  public static function toObject(expressionTypes : Array<ExpressionType>) : Array<{}> {
    return expressionTypes.map(function(expressionType) {
      return (expressionType : Expression).toObject();
    });
  }
}

