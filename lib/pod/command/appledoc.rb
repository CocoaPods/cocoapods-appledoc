require 'cocoapods'

module Pod
  class Command
    class Spec
      class Appledoc < Spec
        self.summary = 'Generate documentation for a pod using appledoc'
        self.arguments = '[ NAME ]'

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! "A spec name is required" unless @name
        end

        def run
          @spec = spec_with_name(@name)
          # TODO
        end

        def spec_with_name(name)
          set = SourcesManager.search(Dependency.new(name))

          if set
            set.specification.root
          else
            raise Informative, "Unable to find a specification for `#{name}`"
          end
        end
      end
    end
  end
end

