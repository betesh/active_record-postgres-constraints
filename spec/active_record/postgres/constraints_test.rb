require 'test_helper'

class ActiveRecord::Postgres::Constraints::Test < ActiveSupport::TestCase
  test "truth" do
    assert_kind_of Module, ActiveRecord::Postgres::Constraints
  end
end
