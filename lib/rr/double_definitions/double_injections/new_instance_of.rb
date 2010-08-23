module RR
  module DoubleDefinitions
    module DoubleInjections
      class NewInstanceOf
        extend(Module.new do
          include RR::Adapters::RRMethods
          def call(subject, stubbed_methods={})
            double_definition_create = DoubleDefinitionCreate.new.stub
            stub(subject).new do |*args| # TODO: Need to stub allocate instead of new
              subject = subject.allocate
              add_stubbed_methods(subject, stubbed_methods)
              add_method_chain_definition(subject, double_definition_create)
              yield(subject) if block_given?
              initialize_subject_instance(subject, args)
            end
            DoubleDefinitionCreateBlankSlate.new(double_definition_create)
          end

          protected
          def add_stubbed_methods(subject_instance, stubbed_methods)
            stubbed_methods.each do |name, value|
              value_proc = value.is_a?(Proc) ? value : lambda {value}
              stub(subject_instance, name).returns(&value_proc)
            end
          end

          def add_method_chain_definition(subject_instance, double_definition_create)
            implementation_strategy = double_definition_create.implementation_strategy
            if implementation_strategy.method_name
              stub(subject_instance).method_missing(
                implementation_strategy.method_name,
                *implementation_strategy.args,
                &implementation_strategy.handler
              )
            end
          end

          def initialize_subject_instance(subject_instance, args)
            if args.last.is_a?(ProcFromBlock)
              subject_instance.__send__(:initialize, *args[0..(args.length-2)], &args.last)
            else
              subject_instance.__send__(:initialize, *args)
            end
            subject_instance
          end
        end)
      end
    end
  end
end
