ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: :number_of_processors)
    fixtures :all
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # Temporarily replaces ClassName.new with a fake instance for the duration of the block.
  def stub_new(klass, fake_instance, &block)
    original = klass.singleton_class.instance_method(:new)
    klass.define_singleton_method(:new) { |*| fake_instance }
    block.call
  ensure
    klass.define_singleton_method(:new) { |*args, **kwargs, &blk| original.bind(klass).call(*args, **kwargs, &blk) }
  end
end

# Fake ChloeInterviewer — no real API calls in tests
class FakeChloeInterviewer
  FAKE_QUESTION = "Tell me about yourself and what brought you to tech."
  FAKE_NEXT_QUESTION = "Can you explain how MVC works in a Rails app?"
  FAKE_FEEDBACK = "What worked: Good personal story.\nTo strengthen: Add a specific project outcome.\nScore: 7/10"

  def first_question
    FAKE_QUESTION
  end

  def evaluate(_answer)
    {
      feedback:         FAKE_FEEDBACK,
      score:            7,
      next_question:    FAKE_NEXT_QUESTION,
      session_complete: false,
      summary:          nil
    }
  end
end

class FakeChloeInterviewerFinal < FakeChloeInterviewer
  def evaluate(_answer)
    {
      feedback:         FAKE_FEEDBACK,
      score:            8,
      next_question:    nil,
      session_complete: true,
      summary:          "SESSION COMPLETE\nOverall score: 8/10\nStrongest moment: Great Q1.\n#1 gap: SQL.\nBefore your next interview, practice this: Write 3 JOIN queries."
    }
  end
end
