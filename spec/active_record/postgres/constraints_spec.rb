# frozen_string_literal: true

require 'spec_helper'
require 'active_record/postgres/constraints'

RSpec.describe ActiveRecord::Postgres::Constraints do
  it 'has a version number' do
    expect(described_class::VERSION).not_to be nil
  end
end
