require "test_helper"

class AnswerTest < ActiveSupport::TestCase
  setup do
    @interview = interviews(:ongoing)
  end

  test "valid with question, answer and interview" do
    answer = Answer.new(question: "Tell me about yourself.", answer: "I came from marketing.", interview: @interview)
    assert answer.valid?
  end

  test "invalid without question" do
    answer = Answer.new(answer: "Some answer", interview: @interview)
    assert_not answer.valid?
    assert_includes answer.errors[:question], "can't be blank"
  end

  test "invalid without answer" do
    answer = Answer.new(question: "Some question?", interview: @interview)
    assert_not answer.valid?
    assert_includes answer.errors[:answer], "can't be blank"
  end

  test "score can be nil" do
    answer = Answer.new(question: "Q?", answer: "A.", interview: @interview)
    assert answer.valid?
  end

  test "score rejects values above 10" do
    answer = Answer.new(question: "Q?", answer: "A.", interview: @interview, score: 11)
    assert_not answer.valid?
  end

  test "score rejects negative values" do
    answer = Answer.new(question: "Q?", answer: "A.", interview: @interview, score: -1)
    assert_not answer.valid?
  end

  test "score accepts values 0 through 10" do
    answer = Answer.new(question: "Q?", answer: "A.", interview: @interview, score: 7)
    assert answer.valid?
  end

  test "belongs to interview" do
    answer = answers(:q1_answered)
    assert_equal interviews(:ongoing), answer.interview
  end
end
