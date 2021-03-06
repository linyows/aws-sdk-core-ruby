module Aws
  module Resource
    class Documenter
      class ReferenceOperationDocumenter < BaseOperationDocumenter

        def parameters
          if argument?
            [[argument_name, nil]]
          else
            []
          end
        end

        def return_type
          if plural?
            "Array<#{target_resource_class_name}>"
          else
            target_resource_class_name
          end
        end

        def return_message
          ''
        end

        def group_name
          "Resource References"
        end

        def plural?
          @operation.builder.plural?
        end

        def argument?
          @operation.requires_argument?
        end

        def argument_name
          argument = @operation.builder.sources.find do |source|
            BuilderSources::Argument === source
          end
          argument.target.to_s
        end

      end
    end
  end
end
