class InterviewSession < ApplicationRecord
  belongs_to :user
  belongs_to :suggested_role
  has_many :interview_answers, dependent: :destroy

  validates :overall_score, numericality: { in: 0..100 }, allow_nil: true
end
