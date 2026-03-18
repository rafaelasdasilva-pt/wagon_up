class SuggestedRole < ApplicationRecord
  belongs_to :analysis
  has_many :interview_sessions, dependent: :destroy

  validates :title, presence: true
  validates :position, presence: true, inclusion: { in: 1..3 }
end
