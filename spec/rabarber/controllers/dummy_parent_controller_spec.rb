# frozen_string_literal: true

require_relative "shared_examples"

RSpec.describe DummyParentController, type: :controller do
  let(:user) { User.create! }

  before { allow(controller).to receive(:current_user).and_return(user) }

  describe "when a controller rule is applied" do
    context "when the user's role allows access" do
      before { user.assign_roles(:manager) }

      it_behaves_like "it allows access", put: :foo
      it_behaves_like "it allows access", delete: :bar
    end

    context "when the user's role does not allow access" do
      before { user.assign_roles(:admin) }

      it_behaves_like "it does not allow access", put: :foo
      it_behaves_like "it does not allow access", delete: :bar
    end

    context "when the user does not have any roles" do
      it_behaves_like "it does not allow access", put: :foo
      it_behaves_like "it does not allow access", delete: :bar
    end
  end
end
