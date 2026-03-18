class InterviewAnswer < ApplicationRecord
  belongs_to :interview_session

  validates :question, presence: true
  validates :score, numericality: { in: 0..10 }, allow_nil: true
  validates :position, presence: true
end
