# frozen_string_literal: true

module Clarke
  module Language
    PRECEDENCES = {
      '^' => 3,
      '*' => 2,
      '/' => 2,
      '+' => 1,
      '-' => 1,
      '&&' => 0,
      '||' => 0,
      '==' => 0,
      '>'  => 0,
      '<'  => 0,
      '>=' => 0,
      '<=' => 0,
    }.freeze

    ASSOCIATIVITIES = {
      '^' => :right,
      '*' => :left,
      '/' => :left,
      '+' => :left,
      '-' => :left,
      '==' => :left,
      '>'  => :left,
      '<'  => :left,
      '>=' => :left,
      '<=' => :left,
      '&&' => :left,
      '||' => :left,
    }.freeze

    class Env
      def initialize(parent: nil, contents: {})
        @parent = parent
        @contents = contents
      end

      def key?(key)
        @contents.key?(key) || (@parent&.key?(key))
      end

      def fetch(key, expr: nil)
        if @parent
          @contents.fetch(key) { @parent.fetch(key, expr: expr) }
        else
          @contents.fetch(key) { raise NameError.new(key, expr) }
        end
      end

      def []=(key, value)
        @contents[key] = value
      end

      def merge(hash)
        pushed = push
        hash.each { |k, v| pushed[k] = v }
        pushed
      end

      def push
        self.class.new(parent: self)
      end
    end

    class Error < StandardError
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def fancy_message
        ctx = @expr.context

        lines = []
        lines << "line #{ctx.from.line + 1}: #{message}"
        lines << ''
        lines << (ctx.input.lines[ctx.from.line] || '').rstrip
        lines << "\e[31m" + ' ' * ctx.from.column + ('~' * (ctx.to.column - ctx.from.column)) + "\e[0m"
        lines.join("\n")
      end
    end

    class NameError < Error
      attr_reader :name

      def initialize(name, expr)
        super(expr)

        @name = name
      end

      def message
        "#{@name}: no such name"
      end
    end

    class TypeError < Error
      attr_reader :val, :klass

      def initialize(val, klass, expr)
        super(expr)

        @val = val
        @klass = klass
      end

      def message
        "expected #{@klass.describe}, but got #{@val.describe}"
      end
    end

    class ArgumentCountError < Error
      attr_reader :actual
      attr_reader :expected

      def initialize(actual:, expected:, expr:)
        super(expr)

        @actual = actual
        @expected = expected
      end

      def message
        "wrong number of arguments: expected #{@expected}, but got #{@actual}"
      end
    end
  end
end
