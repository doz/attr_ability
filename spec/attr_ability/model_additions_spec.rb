require 'spec_helper'

describe AttrAbility::ModelAdditions do
  with_model :Article do
    table do |t|
      t.string :title
      t.integer :system_flags
    end

    model do
      has_many :tags
      has_many :comments
      accepts_nested_attributes_for :tags, :comments

      ability :create, [:title]
      ability :create, [:tags_attributes, :comments_attributes]
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

    def initialize
      can :create, Article
      can :create, Tag
    end
  end

  context "without ability" do
    let(:base) { Article }
    let(:model) { Article.new }

    [:title, :system_flags].each do |attr|
      it "protects #{attr} for new record" do
        base.new(attr => "123").send(attr).should be_nil
      end

      it "protects #{attr} on create" do
        base.create(attr => "123").send(attr).should be_nil
      end

      it "protects #{attr} on create!" do
        base.create!(attr => "123").send(attr).should be_nil
      end

      it "protects #{attr} on update" do
        model.update_attributes(attr => "123")
        model.send(attr).should be_nil
      end
    end

    it "protects tags for new record" do
      base.new(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "protects tags on create" do
      base.create(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "protects tags on create!" do
      base.create!(tags_attributes: [{title: "Tag 1"}]).tags.should be_empty
    end

    it "protects tags on update" do
      model.update_attributes(tags_attributes: [{title: "Tag 1"}])
      model.tags.should be_empty
    end

    it "uses attr_accessible if no abilities defined" do
      comment = Comment.new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == nil
    end
  end

  context "with ability" do
    let(:ability) { TestAbility.new }
    let(:base) { Article.as(ability) }
    let(:model) { Article.new.as(ability) }

    it "allows title for new record" do
      base.new(title: "new title").title.should == "new title"
    end

    it "allows title on create" do
      base.create(title: "new title").title.should == "new title"
    end

    it "allows title on create!" do
      base.create!(title: "new title").title.should == "new title"
    end

    it "allows title on update" do
      model.update_attributes(title: "new title")
      model.title.should == "new title"
    end

    it "allows tags for new record" do
      base.new(tags_attributes: [{title: "Tag 1"}]).tags.map(&:title).should == ["Tag 1"]
    end

    it "allows tags on create" do
      base.create(tags_attributes: [{title: "Tag 1"}]).tags.map(&:title).should == ["Tag 1"]
    end

    it "allows tags on create!" do
      base.create!(tags_attributes: [{title: "Tag 1"}]).tags.map(&:title).should == ["Tag 1"]
    end

    it "allows tags on update" do
      model.update_attributes(tags_attributes: [{title: "Tag 1"}])
      model.tags.map(&:title).should == ["Tag 1"]
    end

    it "allows existing tag title update" do
      tag = Tag.as_system.create!(title: "Tag 1")
      base.create(tags_attributes: [{id: tag.id, title: "Tag 2"}])
      tag.reload.title.should == "Tag 2"
    end

    it "protects tag system flags" do
      base.new(tags_attributes: [{title: "Tag 1", system_flags: 33}]).tags.map(&:system_flags).should == [nil]
    end

    it "protects system_flags for new record" do
      base.new(system_flags: 1).system_flags.should be_nil
    end

    it "protects system_flags on create" do
      base.create(system_flags: 1).system_flags.should be_nil
    end

    it "protects system_flags on create!" do
      base.create!(system_flags: 1).system_flags.should be_nil
    end

    it "protects system_flags on update" do
      model.update_attributes(system_flags: 1)
      model.system_flags.should be_nil
    end

    it "uses attr_accessible if no abilities defined" do
      comment = Comment.as(ability).new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == nil
    end

    it "users attr_accessible for nested model if no abilities defined" do
      article = base.new(comments_attributes: [{title: "Comment 1", system_flags: 44}])
      article.comments.map { |t| [t.title, t.system_flags] }.should == [["Comment 1", nil]]
    end
  end

  context "as system" do
    let(:base) { Article.as_system }
    let(:model) { Article.new.as_system }

    [:title, :system_flags].each do |attr|
      it "allows #{attr} for new record" do
        base.new(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows to set #{attr} on create" do
        base.create(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows to set #{attr} on create!" do
        base.create!(attr => "123").send(attr).to_s.should == "123"
      end

      it "allows #{attr} on update" do
        model.update_attributes(attr => "123")
        model.send(attr).to_s.should == "123"
      end
    end

    it "allows tag with system flags on create" do
      article = base.new(tags_attributes: [{title: "Tag 1", system_flags: 44}])
      article.tags.map { |t| [t.title, t.system_flags] }.should == [["Tag 1", 44]]
    end

    it "allows existing tag title and system_flags update" do
      tag = Tag.as_system.create!(title: "Tag 1")
      base.create(tags_attributes: [{id: tag.id, title: "Tag 2", system_flags: 44}])
      tag.reload.title.should == "Tag 2"
      tag.reload.system_flags.should == 44
    end

    it "overrides attr_accessible" do
      comment = Comment.as_system.new(title: "Title", system_flags: 777)
      comment.title.should == "Title"
      comment.system_flags.should == 777
    end

    it "overrides attr_accessible for nested model" do
      article = base.new(comments_attributes: [{title: "Comment 1", system_flags: 44}])
      article.comments.map { |t| [t.title, t.system_flags] }.should == [["Comment 1", 44]]
    end
  end
end
