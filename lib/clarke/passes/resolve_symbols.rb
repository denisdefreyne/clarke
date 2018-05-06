# frozen_string_literal: true

module Clarke
  module Passes
    class ResolveSymbols < Clarke::Visitor
      def initialize(global_scope)
        @global_scope = global_scope
      end

      def visit_assignment(expr)
        super

        expr.type = expr.expr.type

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.type
      end

      def visit_block(expr)
        super

        exprs = expr.exprs
        expr.type = exprs.any? ? exprs.last.type : @global_scope.resolve('void')
      end

      def visit_class_def(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
      end

      def visit_fun_call(expr)
        super

        # Set type
        expr.type =
          case expr.base.type
          when Clarke::Sym::Class
            Clarke::Sym::InstanceType.new(expr.base.type)
          when Clarke::Sym::Fun
            expr.base.type.ret_type
          else
            raise Clarke::Errors::NotCallable.new(expr: expr.base)
          end

        # Get param syms
        param_syms =
          case expr.base.type
          when Clarke::Sym::Class
            fun = expr.base.type.scope.resolve('init', nil)
            fun ? fun.params : []
          when Clarke::Sym::Fun
            expr.base.type.params
          else
            raise Clarke::Errors::NotCallable.new(expr: expr.base)
          end

        # Verify argument count
        # TOD: verify argument types
        if param_syms.size != expr.arguments.size
          raise Clarke::Errors::ArgumentCountError.new(
            actual: expr.arguments.size,
            expected: param_syms.size,
          )
        end
      end

      def visit_fun_def(expr)
        expr.name_sym = expr.scope.resolve(expr.name)
        expr.name_sym.ret_type = expr.scope.resolve(expr.ret_type_name)

        super

        # Tighten `auto` type
        ret_type = expr.name_sym.ret_type
        if ret_type.auto?
          expr.name_sym.ret_type = expr.body.type
        end
      end

      def visit_get_prop(expr)
        super

        unless expr.base.type.is_a?(Clarke::Sym::InstanceType)
          raise Clarke::Errors::NotGettable.new(expr: expr.base)
        end

        thing = expr.base.type.klass.scope.resolve(expr.name)
        case thing
        when Clarke::Sym::Fun
          expr.type = thing
        when Clarke::Sym::Prop
          expr.type = thing.type
        else
          raise Clarke::Errors::NameError.new(expr.name)
        end
      end

      def visit_lambda_def(expr)
        param_syms =
          expr.params.each { |param| expr.scope.resolve(param.name) }

        ret_type = expr.scope.resolve(expr.ret_type_name)
        expr.type = Clarke::Sym::Fun.new('(anon)', param_syms, ret_type)

        super

        # Tighten `auto` type
        if ret_type.auto?
          expr.type = Clarke::Sym::Fun.new('(anon)', param_syms, expr.body.type)
        end
      end

      def generic_visit_binop(expr)
        types = [expr.lhs, expr.rhs].map(&:type).uniq
        if [expr.lhs, expr.rhs].map(&:type).uniq.size != 1
          raise Clarke::Errors::BinOpTypeMismatch.new(expr)
        end

        # TODO: verify that op exists for this type

        expr.type = types.first
      end

      def visit_op_add(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_subtract(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_multiply(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_divide(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_exponentiate(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_eq(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_gt(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_lt(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_gte(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_lte(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_and(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_op_or(expr)
        super
        generic_visit_binop(expr)
      end

      def visit_ref(expr)
        super

        expr.name_sym = expr.scope.resolve(expr.name)
        expr.type = expr.name_sym.type
      end

      def visit_var_def(expr)
        super

        expr.var_name_sym = expr.scope.resolve(expr.var_name)
        expr.var_name_sym.type = expr.expr.type

        expr.type = expr.expr.type
      end
    end
  end
end
