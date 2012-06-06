require 'spec_helper'

describe AttrAbility::ModelAdditions do
  with_model :Article do
    table do |t|
      t.string :title
      t.integer :author_id
      t.string :review
      t.integer :system_flags
    end

    model do
      has_many :tags
      has_many :comments
      accepts_nested_attributes_for :tags, :comments

      ability :create, [:title, :author_id]
      ability :review, [:review, :tags_attributes, :comments_attributes]
    end
  end

  with_model :Tag do
    table do |t|
      t.integer :article_id
      t.string :title
      t.integer :system_flags
    end

    model do
      belongs_to :article

      ability :create, [:title]
    end
  end

  with_model :Comment do
    table do |t|
      t.integer :article_id
      t.string :title
      t.integer :system_flags
    end

    model do
      belongs_to :article

      attr_accessible :title
    end
  end

  class TestAbility
    include CanCan::Ability

    def initialize(role)
      case role
      when :author
        can :create, Article, author_id: 42
      when :admin
        can :manage, :all
      end
    end
  end

  context "without ability specified" do
    subject { Article.new }

    [:title, :author_id, :review, :system_flags].each do |attr|
      it "rejects #{attr} for new record" do
        Article.new(attr => "123").send(attr).should be_nil
      end

      it "rejects #{attr} on create" do
        Article.create(attr => "123").send(attr).should be_nil
      end

      it "rejects #{attr} on update" do
        subject.update_attributes(attr => "123")
        subject.send(attr).should be_nil
      end
    end

    it "rejects tags for new record" do
      Article.new(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "rejects tags on create" do
      Article.create(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "rejects tags on update" do
      subject.update_attributes(tags_attributes: [{title: "Tag 1"}])
      subject.tags.should be_empty
    end

    it "uses attr_accessible if no abilities defined" do
      comment = Comment.new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == nil
    end
  end

  context "as system" do
    subject { Article.new.as_system }

    [:title, :author_id, :review, :system_flags].each do |attr|
      it "allows to set #{attr} to new record" do
        Article.as_system.new(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows to set #{attr} on create" do
        Article.as_system.create(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows update of #{attr}" do
        subject.update_attributes(attr => "123")
        subject.send(attr).to_s.should == "123"
      end
    end

    it "allows to create nested tags with system flags" do
      article = Article.as_system.new(tags_attributes: [{title: "Tag 1", system_flags: 44}])
      article.tags.map { |t| [t.title, t.system_flags] }.should == [["Tag 1", 44]]
    end

    it "allows to update existing tag system flags" do
      tag = Tag.as_system.create(title: "Tag 1")
      Article.as_system.create(tags_attributes: [{id: tag.id, title: "Tag 2", system_flags: 44}])
      tag.reload.title.should == "Tag 2"
      tag.reload.system_flags.should == 44
    end

    it "ignores attr_accessible" do
      comment = Comment.as_system.new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == 777
    end

    it "ignores attr_accessible for nested model" do
      article = Article.as_system.new(comments_attributes: [{title: "Comment 1", system_flags: 44}])
      article.comments.map { |t| [t.title, t.system_flags] }.should == [["Comment 1", 44]]
    end
  end

  context "as admin" do
    let(:ability) { TestAbility.new(:admin) }
    subject { Article.new.as(ability) }

    [:title, :author_id, :review].each do |attr|
      it "allows to set #{attr} to new record" do
        Article.as(ability).new(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows to set #{attr} on create" do
        Article.as(ability).create(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows update of #{attr}" do
        subject.update_attributes(attr => "123")
        subject.send(attr).to_s.should == "123"
      end
    end

    it "allows to set tags for new record" do
      Article.as(ability).new(tags_attributes: [{title: "Tag 1"}]).tags.map(&:title).should == ["Tag 1"]
    end

    it "allows to set tags on create" do
      Article.as(ability).create(tags_attributes: [{title: "Tag 1"}]).tags.map(&:title).should == ["Tag 1"]
    end

    it "allows update of tags" do
      subject.update_attributes(tags_attributes: [{title: "Tag 1"}])
      subject.tags.map(&:title).should == ["Tag 1"]
    end

    it "allows to update existing tag title" do
      tag = Tag.as_system.create(title: "Tag 1")
      Article.as(ability).create(tags_attributes: [{id: tag.id, title: "Tag 2"}])
      tag.reload.title.should == "Tag 2"
    end

    it "rejects tag system flags" do
      Article.as(ability).new(tags_attributes: [{title: "Tag 1", system_flags: 33}]).tags.map(&:system_flags).should == [nil]
    end

    it "rejects system_flags for new record" do
      Article.as(ability).new(system_flags: 1).system_flags.should be_nil
    end

    it "rejects system_flags on create" do
      Article.as(ability).create(system_flags: 1).system_flags.should be_nil
    end

    it "rejects system_flags on update" do
      subject.update_attributes(system_flags: 1)
      subject.system_flags.should be_nil
    end

    it "doesn't modify original object" do
      article = Article.new
      article.as(ability).update_attributes(title: "Admin Title")
      article.update_attributes(title: "Unauthorized Title")
      article.title.should == "Admin Title"
    end

    it "uses attr_accessible if no abilities defined" do
      comment = Comment.as(ability).new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == nil
    end

    it "users attr_accessible for nested model if no abilities defined" do
      article = Article.as(ability).new(comments_attributes: [{title: "Comment 1", system_flags: 44}])
      article.comments.map { |t| [t.title, t.system_flags] }.should == [["Comment 1", nil]]
    end
  end

  context "as author" do
    let(:ability) { TestAbility.new(:author) }

    it "allows to set authorized author to new record" do
      Article.as(ability).new(author_id: 42).author_id.should == 42
    end

    it "allows to set title to new record with authorized author" do
      Article.as(ability).new(author_id: 42, title: "The Title").title.should == "The Title"
    end

    it "rejects system_flags for new record with authorized author" do
      Article.as(ability).new(author_id: 42, system_flags: 1).system_flags.should be_nil
    end

    it "rejects invalid author for new record" do
      Article.as(ability).new(author_id: 43).author_id.should be_nil
    end

    it "rejects invalid author on create" do
      Article.as(ability).create(author_id: 43).author_id.should be_nil
    end

    it "rejects tags for new record" do
      Article.as(ability).new(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "rejects tags on create" do
      Article.as(ability).create(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    context "with authorized article" do
      subject { Article.as_system.new(author_id: 42).as(ability) }

      it "allows update of title" do
        subject.update_attributes(title: "New Title")
        subject.title.should == "New Title"
      end

      it "rejects author change" do
        subject.update_attributes(author_id: 43)
        subject.author_id.should == 42
      end

      it "rejects system_flags on update" do
        subject.update_attributes(system_flags: 1)
        subject.system_flags.should be_nil
      end

      it "rejects tags on update" do
        subject.update_attributes(tags_attributes: [{title: "Tag 1"}])
        subject.tags.should be_empty
      end
    end
  end
end
