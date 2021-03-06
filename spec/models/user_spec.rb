require "rails_helper"

describe User do
  before do
    @user = create(:user)
  end

  describe "#time_tracking?" do
    context "time tracking with issue" do
      it "returns true" do
        issue = create(:issue, author: @user, assignee: @user)
        workload = create(:workload, user: @user, issue: issue, end_at: nil)
        expect(@user).to be_time_tracking(issue)
      end
    end

    context "not time tracking" do
      it "returns false" do
        issue = create(:issue, author: @user, assignee: @user)
        other_issue = create(:issue)
        workload = create(:workload, user: @user, issue: issue, end_at: nil)
        expect(@user).not_to be_time_tracking(other_issue)
      end
    end
  end

  describe "#current_entry" do
    context "time tracking" do
      it "returns running workload" do
        issue = create(:issue, author: @user, assignee: @user)
        workload = create(:workload, user: @user, issue: issue, end_at: nil)
        expect(@user.current_entry).to eq(workload)
      end
    end

    context "not time tracking" do
      it "returns nil" do
        issue = create(:issue, author: @user, assignee: @user)
        workload = create(:workload, user: @user, issue: issue, end_at: Time.now.utc)
        expect(@user.current_entry).to be_nil
      end
    end
  end

  describe "#crowdworks" do
    it "returns auth of crowdworks" do
      create(:authentication, user: @user, provider: "crowdworks")
      expect(@user.crowdworks.class).to eq(Authentication)
      expect(@user.crowdworks.provider).to eq("crowdworks")
    end
  end
end
