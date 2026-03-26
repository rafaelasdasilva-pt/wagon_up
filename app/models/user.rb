class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_one_attached :avatar
  has_many :analyses, dependent: :destroy
  has_many :roles, through: :analyses
  has_many :interviews, through: :roles

  validates :name, presence: true
end
