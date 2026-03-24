require "test_helper"

class InterviewTest < ActiveSupport::TestCase
  setup do
    @role = roles(:junior_dev)
  end

  test "valid with category and role" do
    interview = Interview.new(category: "Full Practice", role: @role)
    assert interview.valid?
  end

  test "invalid without category" do
    interview = Interview.new(role: @role)
    assert_not interview.valid?
    assert_includes interview.errors[:category], "can't be blank"
  end

  test "overall_score can be nil" do
    interview = Interview.new(category: "Full Practice", role: @role)
    assert interview.valid?
  end

  test "overall_score rejects values above 100" do
    interview = Interview.new(category: "Full Practice", role: @role, overall_score: 101)
    assert_not interview.valid?
  end

  test "overall_score rejects negative values" do
    interview = Interview.new(category: "Full Practice", role: @role, overall_score: -1)
    assert_not interview.valid?
  end

  test "overall_score accepts values 0 through 10" do
    interview = Interview.new(category: "Full Practice", role: @role, overall_score: 8)
    assert interview.valid?
  end

  test "belongs to role" do
    interview = interviews(:ongoing)
    assert_equal roles(:junior_dev), interview.role
  end

  test "has many answers" do
    interview = interviews(:ongoing)
    assert_includes interview.answers, answers(:q1_answered)
  end

  test "current_question stores pending question" do
    interview = interviews(:ongoing)
    assert_equal "Tell me about yourself and what brought you to tech.", interview.current_question
  end
end
