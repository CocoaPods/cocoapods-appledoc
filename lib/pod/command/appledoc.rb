require 'shellwords'
require 'cocoapods'

module Pod
  class Command
    class Spec
      class Appledoc < Spec
        self.summary = 'Generate documentation for a pod using appledoc'
        self.arguments = [
          CLAide::Argument.new('NAME', false)
        ]

        def initialize(argv)
          @name = argv.shift_argument
          super
        end

        def validate!
          super
          help! "A spec name is required" unless @name
          help! 'Please install appledoc first' if `which appledoc`.empty?
        end

        def download_location
          File.join(APPLEDOC_DOWNLOAD_DIRECTORY, "#{@spec.name}-#{@spec.version}")
        end

        def download
          downloader = Pod::Downloader.for_target(download_location, @spec.source)
          downloader.download
        end

        def public_headers_files
          headers = []

          pathlist = Pod::Sandbox::PathList.new(Pathname.new(download_location))
          [@spec, *@spec.recursive_subspecs].each do |internal_spec|
            internal_spec.available_platforms.each do |platform|
              consumer = Pod::Specification::Consumer.new(internal_spec, platform)
              accessor = Pod::Sandbox::FileAccessor.new(pathlist, consumer)

              if accessor.public_headers
                headers += accessor.public_headers.map{ |filepath| filepath.to_s }
              end
            end
          end

          headers.uniq
        end

        def spec_authors
          if @spec.authors.is_a?(Hash)
            @spec.authors.keys.join(', ')
          else
            @spec.authors.to_s
          end
        end

        def generate_docset
          escaped_headers = public_headers_files.map do |header_file|
            Shellwords.escape(header_file)
          end

          command = [
            'appledoc',
            "--company-id 'org.cocoadocs.#{@spec.name.downcase}'",
            "--project-name '#{@spec.name}'",
            "--project-company '#{spec_authors}'",
            "--project-version '#{@spec.version}'",
            '--no-install-docset', # Don't install the docset into Xcode
            '--create-html',
            '--publish-docset',
            "--output #{Shellwords.escape(output_location)}",
            *escaped_headers
          ]

          system command.join(' ')
        end

        def output_location
          File.join(Dir.pwd, "#{@spec.name}-#{@spec.version}")
        end

        def run
          @spec = spec_with_name(@name)

          raise Informative, "Docset in #{output_location} already exists" if File.exist?(output_location)

          download unless File.exist?(download_location)
          generate_docset
        end

        def spec_with_name(name)
          set = SourcesManager.search(Dependency.new(name))

          if set
            set.specification.root
          else
            raise Informative, "Unable to find a specification for `#{name}`"
          end
        end

        APPLEDOC_TMP_DIR = Pathname.new('/tmp/CocoaPods/AppleDoc')
        APPLEDOC_DOWNLOAD_DIRECTORY = File.join(APPLEDOC_TMP_DIR, 'Sources')
      end
    end
  end
end

