class Standard < ApplicationRecord
  belongs_to :standard_group
  belongs_to :course
end
