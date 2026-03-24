require "test_helper"

class AnswersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user      = users(:alice)
    @interview = interviews(:ongoing)
    sign_in @user
  end

  # ── POST /interviews/:interview_id/answers ───────────────────────────────────

  test "create saves answer, stores Chloe feedback and next question" do
    stub_new(ChloeInterviewer, FakeChloeInterviewer.new) do
      assert_difference "Answer.count", 1 do
        post interview_answers_path(@interview), params: {
          answer: {
            question: "Tell me about yourself.",
            answer:   "I came from marketing and joined Le Wagon."
          }
        }
      end
    end

    saved = Answer.last
    assert_equal FakeChloeInterviewer::FAKE_FEEDBACK, saved.feedback
    assert_equal 7, saved.score
    assert_redirected_to interview_path(@interview)
    assert_equal FakeChloeInterviewer::FAKE_NEXT_QUESTION, @interview.reload.current_question
  end

  test "create on final answer redirects to results and saves overall score" do
    # Fill the interview with 8 existing answers so this is the 9th (final)
    8.times do |i|
      Answer.create!(
        interview: @interview,
        question:  "Question #{i + 1}",
        answer:    "Answer #{i + 1}",
        score:     7
      )
    end

    stub_new(ChloeInterviewer, FakeChloeInterviewerFinal.new) do
      post interview_answers_path(@interview), params: {
        answer: {
          question: "What does your background give you that a pure coder cannot?",
          answer:   "I understand business problems before writing a line of code."
        }
      }
    end

    assert_redirected_to results_interview_path(@interview)
    @interview.reload
    assert_not_nil @interview.overall_score
    assert_not_nil @interview.feedback_summary
    assert_nil @interview.current_question
  end

  test "create rejects unauthenticated access" do
    sign_out @user
    post interview_answers_path(@interview), params: {
      answer: { question: "Q?", answer: "A." }
    }
    assert_redirected_to new_user_session_path
  end

  test "create does not save answer without question" do
    stub_new(ChloeInterviewer, FakeChloeInterviewer.new) do
      assert_no_difference "Answer.count" do
        post interview_answers_path(@interview), params: {
          answer: { question: "", answer: "My answer." }
        }
      end
    end
  end
end
