require "spec_helper"

describe ChefSpec::Matchers::ResourceMatcher do
  subject { described_class.new(:template, :create, "/etc/foo") }

  describe "#failure_message" do
    context "when a resource is found but has unmatched parameters" do
      before do
        # Pretend we found a matching resource with a mismatched, multi-line
        # parameter so that #failure_message renders a diff. This is the code
        # path that depends on rspec-expectations' (private) diff helper class.
        allow(subject).to receive(:resource).and_return("template[/etc/foo]")
        allow(subject).to receive(:unmatched_parameters).and_return(
          content: { expected: "line one\nline two\n", actual: "line one\nline three\n" }
        )
      end

      it "renders a diff without raising" do
        expect { subject.failure_message }.not_to raise_error
      end

      it "includes the parameter name and a diff in the message" do
        message = subject.failure_message
        expect(message).to include("expected \"template[/etc/foo]\" to have parameters")
        expect(message).to include("content")
        expect(message).to include("line three")
      end
    end
  end

  describe "#respond_to?" do
    it "reports responding to dynamic with_* matcher methods" do
      expect(subject).to respond_to(:with_owner)
    end

    it "does not report responding to unrelated missing methods" do
      expect(subject).not_to respond_to(:nonexistent_method)
    end
  end
end
