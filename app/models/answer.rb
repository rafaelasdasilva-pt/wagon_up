class Answer < ApplicationRecord
  belongs_to :interview

  validates :question, presence: true
  validates :answer, presence: true
  validates :score, numericality: { in: 0..10 }, allow_nil: true
end
