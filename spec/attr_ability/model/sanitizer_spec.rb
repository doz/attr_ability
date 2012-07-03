require 'spec_helper'

describe AttrAbility::Model::Sanitizer do
  with_model :Post do
    table do |t|
      t.string :title
      t.integer :author_id
      t.string :status
      t.boolean :important
      t.string :review
      t.integer :system_flags
    end

    model do
      ability :create, [:title, :author_id]
      ability :review, [:review, :status => [:approved, :rejected], :important => true]

      def self.statuses
        [:pending, :approved, :rejected, :deleted]
      end

      def status
        self[:status] && self.class.statuses[self[:status]]
      end

      def status=(val)
        if val.nil?
          self[:status] = nil
        else
          raise "invalid status" unless index = self.class.statuses.index(val.to_sym)
          self[:status] = index
        end
      end
    end
  end

  class SanitizerTestAbility
    include CanCan::Ability

    def initialize(role)
      case role
      when :author
        can :create, Post, author_id: 42
      when :admin
        can :manage, :all
      end
    end
  end

  subject { AttrAbility::Model::Sanitizer.new(SanitizerTestAbility.new(role)) }

  context "with admin ability" do
    let(:role) { :admin }
    let(:article) { Post.new }

    %w(title author_id review).each do |attr|
      it "allows #{attr}" do
        attrs = {attr => "777"}
        subject.sanitize(article, attrs).should == attrs
      end
    end

    it "allows status = approved" do
      attrs = {"status" => "approved"}
      subject.sanitize(article, attrs).should == attrs
    end

    it "allows status = rejected" do
      attrs = {"status" => "rejected"}
      subject.sanitize(article, attrs).should == attrs
    end

    it "protects status = deleted" do
      attrs = {"status" => "deleted"}
      subject.sanitize(article, attrs).should == {}
    end

    it "allows important = true" do
      attrs = {"important" => true}
      subject.sanitize(article, attrs).should == attrs
    end

    it "protects system_flags" do
      subject.sanitize(article, "system_flags" => "777").should == {}
    end

    it "protects system_flags when status is set" do
      article.status = :rejected
      subject.sanitize(article, "system_flags" => "777").should == {}
    end
  end

  context "with author ability" do
    let(:role) { :author }

    context "for authorized article" do
      let(:article) { Post.new { |article| article.author_id = 42 } }

      it "allows title" do
        attrs = {"title" => "author title"}
        subject.sanitize(article, attrs).should == attrs
      end

      {"review" => "review", "system_flags" => 777, "status" => "deleted"}.each do |attr, value|
        it "protects #{attr}" do
          subject.sanitize(article, attr => value).should == {}
        end
      end

      it "protects all atributes on author_id change" do
        subject.sanitize(article, "author_id" => 43, "title" => "new title").should == {}
      end
    end

    context "for empty article" do
      let(:article) { Post.new }

      it "protects all attributes if author_id is not set" do
        subject.sanitize(article, "title" => "new title").should == {}
      end

      it "protects all attributes if author_id is invalid" do
        subject.sanitize(article, "author_id" => 43, "title" => "new title").should == {}
      end

      it "allows valid author_id" do
        attrs = {"author_id" => 42}
        subject.sanitize(article, attrs).should == attrs
      end

      it "allows title with valid author_id" do
        attrs = {"author_id" => 42, "title" => "author title"}
        subject.sanitize(article, attrs).should == attrs
      end

      {"review" => "review", "system_flags" => 777, "status" => "deleted"}.each do |attr, value|
        it "protects #{attr} even with valid author_id" do
          subject.sanitize(article, "author_id" => 42, attr => value).should == {"author_id" => 42}
        end
      end
    end
  end
end
