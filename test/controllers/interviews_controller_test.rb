require "test_helper"

class InterviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user  = users(:alice)
    @role  = roles(:junior_dev)
    sign_in @user
  end

  # ── GET /roles/:role_id/interviews/new ──────────────────────────────────────

  test "new renders the interview start page" do
    get new_role_interview_path(@role)
    assert_response :success
  end

  test "new redirects unauthenticated user" do
    sign_out @user
    get new_role_interview_path(@role)
    assert_redirected_to new_user_session_path
  end

  # ── POST /roles/:role_id/interviews ─────────────────────────────────────────

  test "create saves the interview and stores Chloe's first question" do
    stub_new(ChloeInterviewer, FakeChloeInterviewer.new) do
      assert_difference "Interview.count", 1 do
        post role_interviews_path(@role), params: { interview: { category: "Full Practice" } }
      end
    end

    interview = Interview.last
    assert_redirected_to interview_path(interview)
    assert_equal FakeChloeInterviewer::FAKE_QUESTION, interview.current_question
  end

  test "create does not save with missing category" do
    stub_new(ChloeInterviewer, FakeChloeInterviewer.new) do
      assert_no_difference "Interview.count" do
        post role_interviews_path(@role), params: { interview: { category: "" } }
      end
    end
    assert_response :unprocessable_entity
  end

  # ── GET /interviews/:id ──────────────────────────────────────────────────────

  test "show renders the chat page with current question" do
    interview = interviews(:ongoing)
    get interview_path(interview)
    assert_response :success
    assert_select ".wu-chat-messages"
  end

  test "show is not accessible by another user" do
    other_user = User.create!(email: "other@test.com", password: "password123", name: "Other")
    sign_in other_user
    begin
      get interview_path(interviews(:ongoing))
      # Rails may convert RecordNotFound to 404 in some configurations
      assert_response :not_found
    rescue ActiveRecord::RecordNotFound
      pass # exception propagated — access correctly denied
    end
  end

  # ── GET /interviews/:id/results ──────────────────────────────────────────────

  test "results renders the results page" do
    get results_interview_path(interviews(:completed))
    assert_response :success
  end
end
