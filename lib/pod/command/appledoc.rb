require 'shellwords'
require 'cocoapods'

module Pod
  class Command
    class Appledoc < Command
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
          '--keep-undocumented-objects',
          '--keep-undocumented-members',
          '--keep-intermediate-files',
          '--no-install-docset', # Don't install the docset into Xcode
          "--docset-feed-name #{@spec.name}",
          "--docset-feed-url #{base_url}docsets/#{@spec.name}/xcode-docset.atom",
          '--docset-package-filename docset',
          "--docset-package-url #{base_url}docsets/#{@spec.name}/docset.xar",
          '--create-html',
          '--create-docset',
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
        @spec = spec_with_path(@name) || spec_with_name(@name)

        raise Informative, "Docset in #{output_location} already exists" if File.exist?(output_location)

        download unless File.exist?(download_location)
        generate_docset

        UI.puts("Docset has been generated for #{@spec.name} (#{@spec.version}) and can be found in #{output_location}.".green)
      end

      def spec_with_path(path)
        Spec.from_file(path)
      rescue
        nil
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

    def base_url
      "http://cocoadocs.org/"
    end
  end
end

