require 'spec_helper'

describe AttrAbility::Model::InstanceProxy do
  with_model :ProxyPost do
    table do |t|
      t.string :title
      t.integer :author_id
      t.string :status
    end
  end

  with_model :ProxyAuthor do
    table do |t|
      t.string :name
    end
  end

  subject { AttrAbility::Model::InstanceProxy }
  let(:sanitizer) { AttrAbility::Model::Sanitizer.new(SanitizerTestAbility.new(:system)) }
  let(:post) { ProxyPost.new(title: "some") }
  let(:author) { ProxyAuthor.new(name: "some") }
  let(:proxied_post) { subject[ProxyPost].new(post, sanitizer) }
  let(:proxied_author) { subject[ProxyAuthor].new(author, sanitizer) }

  it "caches class" do
    subject[ProxyPost] == subject[ProxyPost]
  end

  it "proxies methods" do
    proxied_post.title.should == post.title
  end

  it "does not leak methods to another model" do
    # ensure post cached
    proxied_post.title
    proxied_author.methods.should_not include(:title)
  end
end
