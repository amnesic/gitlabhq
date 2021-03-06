# == Schema Information
#
# Table name: web_hooks
#
#  id         :integer         not null, primary key
#  url        :string(255)
#  project_id :integer
#  created_at :datetime        not null
#  updated_at :datetime        not null
#  type       :string(255)     default("ProjectHook")
#

require "spec_helper"

describe SystemHook do
  describe "execute" do
    before(:each) { ActiveRecord::Base.observers.enable(:all) }

    before(:each) do
      @system_hook = Factory :system_hook
      WebMock.stub_request(:post, @system_hook.url)
    end

    it "project_create hook" do
      with_resque do
        project = Factory :project
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /project_create/).once
    end

    it "project_destroy hook" do
      project = Factory :project
      with_resque do
        project.destroy
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /project_destroy/).once
    end

    it "user_create hook" do
      with_resque do
        Factory :user
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /user_create/).once
    end

    it "user_destroy hook" do
      user = Factory :user
      with_resque do
        user.destroy
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /user_destroy/).once
    end

    it "project_create hook" do
      user = Factory :user
      project = Factory :project
      with_resque do
        project.users << user
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /user_add_to_team/).once
    end

    it "project_destroy hook" do
      user = Factory :user
      project = Factory :project
      project.users << user
      with_resque do
        project.users_projects.clear
      end
      WebMock.should have_requested(:post, @system_hook.url).with(body: /user_remove_from_team/).once
    end
  end

end
