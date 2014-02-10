require File.expand_path('../../spec_helper', __FILE__)

module Pod
  describe Command::Spec::Appledoc do
    describe "CLAide" do
      it "registers it self" do
        Command.parse(%w{ spec appledoc }).should.be.instance_of Command::Spec::Appledoc
      end

      it "presents the help if no spec is provided" do
        command = Command.parse(%w{ spec appledoc })
        should.raise CLAide::Help do
          command.validate!
        end.message.should.match /required/
      end

      it "errors if it cannot find a spec" do
        SourcesManager.stubs(:search).returns(nil)
        command = Command.parse(%w{ spec appledoc KFData })
        should.raise Informative do
          command.run
        end.message.should.match /Unable to find a specification/
      end

      it "runs" do
        command = Command.parse(%w{ spec appledoc KFData })
        command.run
      end
    end
  end
end

