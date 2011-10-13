require './kdbtree.rb'

describe KDBTree do
  include KDBTree

  it "queries for points correctly within a given region" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    tree.insert([5, 5], {})
    tree.insert([6, 6], {})
    tree.insert([4, 4], {})
    tree.insert([0, 0], {})
    tree.insert([2, 2], {})
    tree.query(Region.new([(4..6), (4..6)])).each do |p|
      p[:coords][0].should be_within(2).of(5)
      p[:coords][1].should be_within(2).of(5)
    end
  end

  it "returns no points from an empty domain" do
    tree = Tree.new(Region.new([(-90...90), (-180...180)]))
    tree.query(Region.new([(-90...90), (-180...180)])).should be_empty
  end

  it "doesn't allow points outside its domain" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    tree.insert([5, 5], {})
    tree.insert([9, 0], {})
    expect { tree.insert([11, 11], {}) }.to raise_error(Tree::DomainError)
  end

  it "never has empty RegionNodes" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    (1..100).each do |i|
      tree.insert([rand(10), rand(10)], {})
    end

    traverse_tree = lambda { |node|
      if node.class == Tree::RegionNode
        return false if node.children.empty?
        node.children.each do |n|
          return false unless traverse_tree.call(n)
        end
      end
      return true
    }

    traverse_tree.call(tree.root).should be_true
  end

  it "has the same path length for all leaf pages" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    (1..100).each do |i|
      tree.insert([rand(10), rand(10)], {})
    end

    traverse_tree = lambda { |node, level|
      if node.class == Tree::PointNode
        return [level]
      else
        levels = []
        node.children.each do |n|
          levels.concat(traverse_tree.call(n, level + 1))
        end
        return levels
      end
    }

    traverse_tree.call(tree.root, 0).uniq.size.should == 1
  end

  it "handles multiple points at the same location" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    (1..10).each do |i|
      tree.insert([5, 5], {})
    end
    tree.query(Region.new([(0...10), (0...10)])).size.should == 10
  end

  it "returns only results of the correct category" do
    tree = Tree.new(Region.new([(0...10), (0...10)]), 2, 2)
    coordarr = []
    (1..10).each do |i|
      coords = [rand(10), rand(10)]
      coordarr << coords
      tree.insert(coords, {}, i.to_s)
    end
    puts coordarr.to_s
    tree.query(Region.new([(0...10), (0...10)]), "5").size.should == 1
  end

end

