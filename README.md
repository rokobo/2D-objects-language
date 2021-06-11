# Language for manipulating two-dimensional geometry objects

Two implementations of an interpreter for a small
language for two-dimensional geometry objects will be made. One implementation in SML and one in Ruby. The SML implementation is structured with functions
and pattern-matching. The Ruby implemented is structured with subclasses and methods, including double dispatch and other dynamic dispatch to stay within a very OOP style. Even though the functional style could be easier to understand, the goal of this implementation is to learn about dispatching.


## Language Semantics:

The language has five kinds of values and four other kinds of expressions. The representation of expressions depends on the metalanguage (SML or Ruby), with this same semantics:

* A `NoPoints` represents the empty set of two-dimensional points.


* A `Point` represents a two-dimensional point with an `x`-coordinate and a `y`-coordinate.

* A `Line` is a non-vertical infinite line in the plane, represented by a slope and an intercept (as in `y = mx + b` where `m` is the slope and `b` is the intercept).

* A `VerticalLine` is an infinite vertical line in the plane, represented by its x-coordinate.

* A `LineSegment` is a (finite) line segment, represented by the `x`-coordinate and `y`-coordinate of its endpoints.

* An `Intersect` expression is not a value. It has two subexpressions. The semantics is to evaluate the subexpressions (in the same environment) and then return the value that is the intersection (in the geometric sense) of the two subresults. For example, the intersection of two lines could be one of:

    * `NoPoints`, if the lines are parallel.
    * `Point`, if the lines intersect.
    * `Line`, if the lines have the same slope and intercept.

* A `Let` expression is not a value. The first subexpression is evaluated and the result bound to a variable that is added to the environment for evaluating the second subexpression.

* A `Var` expression is not a value. It is for using variables in the environment: We look up a string in the environment to get a geometric value.

* A `Shift` expression is not a value. It has a `ΔX`, a `ΔY`, and a subexpression. The semantics is to evaluate the subexpression and then shift the result by `ΔX` and `ΔY`:
    * `NoPoints` remains `NoPoints`.
    * `Point` representing (`x`, `y`) becomes a `Point` representing (`x+ΔX`, `y+ΔY`).
    * A `Line` with slope `m` and intercept `b` becomes a `Line` with slope `m` and an intercept of `b + ΔY − mΔX`.
    * A `VerticalLine` becomes a `VerticalLine` shifted by `ΔX`.
    * A `LineSegment` has its endpoints shift by `ΔX` and `ΔY`.


### Note on Floating-Point Numbers:

Because arithmetic with floating-point numbers can introduce small rounding errors, a
helper function/method is used to decide if two floating-point numbers are to be considered equal (for this case, within `0.00001`) and all your code should follow this approach as needed. 

## Expression Preprocessing:

To simplify the interpreter, we first preprocess expressions. Preprocessing takes an expression and produces a new, equivalent expression with the following invariants:

* No `LineSegment` anywhere in the expression has endpoints that are the same as  each other. Such a line-segment should be replaced with the appropriate `Point`. 

* Every `LineSegment` has its first endpoint to the left (lower `x`-value) of the second endpoint. If the `x`-coordinates of the two endpoints are the same, then the
    `LineSegment` has its first endpoint below (lower `y`-value) the second endpoint. For any `LineSegment` not meeting this requirement, it is replaced with a `LineSegment` with the same endpoints reordered.

## SML problem

The SML implementation focuses on preprocessing and shifting. The SML code is organized around a datatype-definition for expressions, functions for the different operations, and pattern-matching to identify different cases. The interpreter `eval_prog` uses a helper function `intersect` with cases for every combination of geometric value. 

## Ruby problem

The Ruby code is organized around classes where each class has methods for various operations. All kinds of expressions need methods for preprocessing and evaluation. They are subclasses of `GeometryExpression` just like all ML constructors are part of the `geom_exp` datatype. The value subclasses also need methods for shifting and intersection and they sub-
class `GeometryValue` so that some shared methods can be inherited. The Ruby code should follow these guidelines:


* All your geometry-expression objects should be immutable: assign to instance variables only when constructing an object. To mutate a field, create a new object.

* The geometry-expression objects have public getter methods.

* Unlike in SML, you do not need to define exceptions since it is assumed the right objects are used in the right places.

* Follow OOP-style. Operations should be instance methods and you should not use methods like `is_a?`, `instance_of?`, `class`, etc. 

## The Problems

1. Implement an SML function `preprocess_prog` of type `geom_exp` `->` `geom_exp` to implement expression preprocessing as defined above. The idea is that evaluating program `e` would be done with `eval_prog` (`preprocess_prog e, []`) where the `[]` is the empty list for the empty environment.

2. Add shift expressions as defined above to the SML implementation by adding the constructor
    `Shift` of type `real * real * geom_exp` to the definition of `geom_exp` and adding appropriate branches to `eval_prog` and `preprocess_prog`. (The first real is `Δx` and the second is `ΔY`.) 

3. Complete the Ruby implementation except for intersection, as follows:

    * Every subclass of `GeometryExpression` should have a `preprocess_prog` method that takes no arguments and returns the geometry object that is the result of preprocessing `self`. To avoid
        mutation, return a new instance of the same class unless it is trivial to determine that `self` is
        already an appropriate result.

    * Every subclass of `GeometryExpression` should have an `eval_prog` method that takes one argument, the environment, which you should represent as an array whose elements are two-element arrays: a Ruby string (the variable name) in index 0 and an object that is a value in our language in index 1. As in any interpreter, pass the appropriate environment when evaluating subexpressions. To handle both scope and shadowing correctly:
        
        * Do not ever mutate an environment. Create a new environment as needed instead.
        
        * The `eval_prog` method in `Var` is given to you. Make sure the environments you create work
        correctly with this definition.

    The result of `eval_prog` is the result of evaluating the expression represented by `self`, so, as to conform with OOP style, the cases of ML’s `eval_prog` are spread among the classes, just like with `preprocess_prog`.

    * Every subclass of `GeometryValue` should have a `shift` method that takes two arguments `dx` and `dy` and returns the result of shifting `self` by `dx` and `dy`.

    * Analogous to SML, an overall program `e` would be evaluated via `e.preprocess_prog.eval_prog []`.

4. Implement intersection in your Ruby solution following the directions here, in which both
double dispatch and a separate use of dynamic dispatch for the line-segment case are required:

* Implement `preprocess_prog` and `eval_prog` in the `Intersect` class.

* Every subclass of `GeometryValue` needs an `intersect` method. The
argument is another geometry-value, to determine which value we use double dispatch
and call the appropriate method on the argument passing `self` to the method.

* So methods `intersectNoPoints`, `intersectPoint`, `intersectLine`, `intersectVerticalLine`,
and `intersectLineSegment` defined in each of the 5 subclasses of `GeometryValue` handle the 25 possible intersection combinations. Implement the following:

    * 9 cases involving combinations that do not involve `LineSegment` require understanding double-dispatch to avoid `is_a?` and `instance_of?`. 

    * 7 cases where one value is a `LineSegment` and the other is not
    `NoPoints`. These cases call `intersectWithSegmentAsLineResult`, which you need to implement for each subclass of `GeometryValue`. Here is how this method should work:

        * It takes one argument, which is a line segment. (it will be an instance of `LineSegment` and getter methods `x1`,`y1`,`x2`, and `y2` should be used as needed.)

        * It assumes that `self` is the intersection of: some not-provided geometry-value and the line containing the segment given as an argument.

        * It returns the intersection of the not-provided geometry-value and the segment given as an argument. 