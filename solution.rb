# frozen_string_literal: true

# Superclass for all geometry expressions and constants
class GeometryExpression
  EPSILON = 0.00001
end

# Superclass for all geometry objects; contains useful methods
class GeometryValue
  private

  def real_close(num1, num2)
    (num1 - num2).abs < GeometryExpression::EPSILON
  end

  def real_close_point(num1, num2, num3, num4)
    real_close(num1, num3) && real_close(num2, num4)
  end

  def two_points_to_line(x1, y1, x2, y2)
    if real_close(x1, x2)
      VerticalLine.new x1
    else
      m = (y2 - y1).to_f / (x2 - x1)
      b = y1 - m * x1
      Line.new(m, b)
    end
  end

  def inbetween(value, end1, end2)
    (end1 - GeometryExpression::EPSILON <= value && value <= end2 + GeometryExpression::EPSILON) ||
      (end2 - GeometryExpression::EPSILON <= value && value <= end1 + GeometryExpression::EPSILON)
  end

  public

  def intersectNoPoints(np)
    np
  end

  # Used as step in double dispatch. Converts line segment to line in order to
  # make calculations easier (this forces additional verification methods)
  def intersectLineSegment(seg)
    line_result = intersect(two_points_to_line(seg.x1, seg.y1, seg.x2, seg.y2))
    line_result.intersectWithSegmentAsLineResult seg
  end
end

# Class that represents the lack of a geometric object
# Used when an operation's result is nothing (like in intersections)
class NoPoints < GeometryValue
  def eval_prog(_env)
    self
  end

  def preprocess_prog
    self
  end

  def shift(_dx, _dy)
    self
  end

  def intersect(other)
    other.intersectNoPoints self
  end

  def intersectPoint(_p)
    self
  end

  def intersectLine(_line)
    self
  end

  def intersectVerticalLine(_vline)
    self
  end

  def intersectWithSegmentAsLineResult(_seg)
    self
  end
end

# Subclass of GeometryValue for representing a point
class Point < GeometryValue
  attr_reader :x, :y

  def initialize(x, y)
    super()
    @x = x
    @y = y
  end

  def preprocess_prog
    self
  end

  def eval_prog(_env)
    self
  end

  def shift(dx, dy)
    Point.new(x + dx, y + dy)
  end

  def intersect(other)
    other.intersectPoint self
  end

  def intersectPoint(p)
    if real_close_point(x, y, p.x, p.y)
      self
    else
      NoPoints.new
    end
  end

  def intersectLine(line)
    if real_close(y, line.m * x + line.b)
      self
    else
      NoPoints.new
    end
  end

  def intersectVerticalLine(vline)
    if real_close(x, vline.x)
      self
    else
      NoPoints.new
    end
  end

  def intersectWithSegmentAsLineResult(seg)
    if inbetween(@x,seg.x1,seg.x2) && inbetween(@y,seg.y1,seg.y2)
      self
    else
      NoPoints.new
    end
  end
end

# Subclass of GeometryValue for representing an infinite non-vertical line
class Line < GeometryValue
  attr_reader :m, :b

  def initialize(m, b)
    super()
    @m = m
    @b = b
  end

  def preprocess_prog
    self
  end

  def eval_prog(_env)
    self
  end

  def shift(dx, dy)
    Line.new(m, b + dy - (m * dx))
  end

  def intersect(other)
    other.intersectLine self
  end

  def intersectPoint(p)
    p.intersectLine self
  end

  def intersectLine(line)
    if real_close(m, line.m)
      if real_close(b, line.b)
        self
      else
        NoPoints.new
      end
    else
      x = (line.b - b) / (m - line.m)
      y = m * x + b
      Point.new(x, y)
    end
  end

  def intersectVerticalLine(vline)
    Point.new(vline.x, m * vline.x + b)
  end

  def intersectWithSegmentAsLineResult(seg)
    seg
  end
end

# Subclass of GeometryValue for representing an infinite vertical line
class VerticalLine < GeometryValue
  attr_reader :x

  def initialize(x)
    super()
    @x = x
  end

  def preprocess_prog
    self
  end

  def eval_prog(_env)
    self
  end

  def shift(dx, _dy)
    VerticalLine.new(x + dx)
  end

  def intersect(other)
    other.intersectVerticalLine self
  end

  def intersectPoint(p)
    p.intersectVerticalLine self
  end

  def intersectLine(line)
    line.intersectVerticalLine self
  end

  def intersectVerticalLine(vline)
    if real_close(x, vline.x)
      self
    else
      NoPoints.new
    end
  end

  def intersectWithSegmentAsLineResult(seg)
    seg
  end
end

# Subclass of GeometryValue for representing a finite line segment
class LineSegment < GeometryValue
  attr_reader :x1, :y1, :x2, :y2

  def initialize(x1, y1, x2, y2)
    super()
    @x1 = x1
    @y1 = y1
    @x2 = x2
    @y2 = y2
  end

  def preprocess_prog
    if real_close_point(x1, y1, x2, y2)
      Point.new(x1, y1)
    elsif real_close(x1, x2)
      if y1 < y2
        self
      else
        LineSegment.new(x1, y2, x1, y1)
      end
    elsif x2 < x1
      LineSegment.new(x2, y2, x1, y1)
    else
      self
    end
  end

  def eval_prog(_env)
    self
  end

  def shift(dx, dy)
    LineSegment.new(x1 + dx, y1 + dy, x2 + dx, y2 + dy)
  end

  def intersect(other)
    other.preprocess_prog.intersectLineSegment self
  end

  def intersectPoint(p)
    p.intersectLineSegment self
  end

  def intersectLine(line)
    line.intersectLineSegment self
  end

  def intersectVerticalLine(vline)
    vline.intersectLineSegment self
  end

  def intersectWithSegmentAsLineResult(seg)
    if real_close(x1, x2)
      if y1 < seg.y1
        aXend = x2
        aYend = y2
        bXstart = seg.x1
        bYstart = seg.y1
        bXend = seg.x2
        bYend = seg.y2
      else
        aXend = seg.x2
        aYend = seg.y2
        bXstart = x1
        bYstart = y1
        bXend = x2
        bYend = y2
      end

      if real_close(aYend, bYstart)
        Point.new(aXend, aYend)
      elsif aYend < bYstart
        NoPoints.new
      elsif aYend > bYend
        LineSegment.new(bXstart, bYstart, bXend, bYend)
      else
        LineSegment.new(bXstart, bYstart, aXend, aYend)
      end
    else
      if x1 < seg.x1
        aXend = x2
        aYend = y2
        bXstart = seg.x1
        bYstart = seg.y1
        bXend = seg.x2
        bYend = seg.y2
      else
        aXend = seg.x2
        aYend = seg.y2
        bXstart = x1
        bYstart = y1
        bXend = x2
        bYend = y2
      end
      if real_close(aXend, bXstart)
        Point.new(aXend, aYend)
      elsif aXend < bXstart
        NoPoints.new
      elsif aXend > bXend
        LineSegment.new(bXstart, bYstart, bXend, bYend)
      else
        LineSegment.new(bXstart, bYstart, aXend, aYend)
      end
    end
  end
end

# Subclass of GeometryExpression for calculating the intersection of 
# two GeometryValue objects
class Intersect < GeometryExpression
  attr_reader :e1, :e2

  def initialize(e1, e2)
    super()
    @e1 = e1
    @e2 = e2
  end

  def preprocess_prog
    Intersect.new(@e1.preprocess_prog, @e2.preprocess_prog)
  end

  def eval_prog(env)
    @e1.eval_prog(env).intersect @e2.eval_prog(env)
  end
end

# Subclass of GeometryExpression for using variables defined in the Var class
class Let < GeometryExpression
  def initialize(s, e1, e2)
    super()
    @s = s
    @e1 = e1
    @e2 = e2
  end

  def preprocess_prog
    Let.new(@s, @e1.preprocess_prog, @e2.preprocess_prog)
  end

  def eval_prog(env)
    @e2.eval_prog([[@s, @e1.eval_prog(env)]] + env)
  end
end

# Subclass of GeometryExpression for defining variables
class Var < GeometryExpression
  def initialize(s)
    super()
    @s = s
  end

  def preprocess_prog
    self
  end

  def eval_prog(env)
    pr = env.assoc @s
    raise 'undefined variable' if pr.nil?

    pr[1]
  end
end

# Subclass of GeometryExpression for calculating the
# GeometryValue object after it is shifted by dx and dy
class Shift < GeometryExpression
  attr_reader :dx, :dy, :e

  def initialize(dx, dy, e)
    super()
    @dx = dx
    @dy = dy
    @e = e
  end

  def preprocess_prog
    Shift.new(@dx, @dy, @e.preprocess_prog)
  end

  def eval_prog(env)
    @e.eval_prog(env).shift(@dx, @dy)
  end
end
