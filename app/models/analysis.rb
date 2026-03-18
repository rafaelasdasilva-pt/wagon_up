class Analysis < ApplicationRecord
  belongs_to :user
  has_many :suggested_roles, dependent: :destroy

  validates :cv_text, presence: true
end
