require 'set'
require './region.rb'

module KDBTree

  MAX_CHILDREN = 5
  MAX_POINTS = 8

  class Tree

    class NodeOverflow < Exception; end

    class Node
      def initialize(region, split_dimension = 0)
        @region = region
        @split_dimension = split_dimension
        @children = []
        @points = []
        @categories = Set.new
      end
      attr_reader :children, :region, :points, :categories

      def is_point_node?
        return @children.empty? || !@points.empty?
      end

      def query(region, cat = nil)
        # If this is a point node, return points within the region
        if is_point_node?
          return @points.select { |p| region.contains_point?(p[:coords]) && (p[:category] == cat || cat.nil?) }
        end

        # Otherwise, recurse on children intersecting the regions and containing
        # the correct categories
        points = []
        @children.each do |child|
          if child.region.intersects?(region) && (cat.nil? || child.categories.include?(cat))
            points.concat(child.query(region, cat))
          end
        end
        return points
      end

      def insert(point)
        categories << point[:category]

        # If this is a point node, simply add the new point
        if is_point_node?
          @points.push(point)
          if @points.size > MAX_POINTS
            raise NodeOverflow
          end
          return
        end

        @children.each_with_index do |child, idx|
          if child.region.contains_point?(point[:coords])
            begin
              child.insert(point)
            rescue NodeOverflow
              # The child contains too many points.  Split it.
              split_child = child.split
              @children.delete_at(idx)
              @children.concat(split_child)

              if @children.size > MAX_CHILDREN
                raise NodeOverflow
              end
            end
            return
          end
        end

        raise "Error: The point to be inserted is not in this tree's domain"
      end

      def split(dimension = nil, cutter = nil)
        if dimension.nil? || cutter.nil?
          dimension = @split_dimension

          if is_point_node?
            cutter = dimension_median(dimension)
          else
            range = @region.ranges[dimension]
            cutter = (range.max - range.min) / 2 + range.min
          end
        end
        splits = split_nodes(dimension, cutter)

        if is_point_node?
          add_split_points(splits)
        else
          add_split_regions(splits, dimension, cutter)
        end

        return splits
      end

      private

      def dimension_median(dim)
        @points.sort_by { |p| p[:coords][dim] }
        len = @points.size
        (@points[len/2][:coords][dim] + @points[(len + 1)/2][:coords][dim]) / 2
      end

      def split_nodes(dimension, cutter)
        subregions = @region.split(dimension, cutter)
        next_dim = (dimension + 1) % @region.num_dimensions

        left = Node.new(subregions[0], next_dim)
        right = Node.new(subregions[1], next_dim)

        return [left, right]
      end

      def add_split_points(splits)
        @points.each do |p|
          if splits[0].region.contains_point?(p[:coords])
            splits[0].insert(p)
          else
            splits[1].insert(p)
          end
        end
      end

      def add_split_regions(splits, dimension, cutter)
        @children.each do |child|
          if splits[0].region.contains_region?(child.region)
            splits[0].children.push(child)
            splits[0].categories.merge(child.categories)
          elsif splits[1].region.contains_region?(child.region)
            splits[1].children.push(child)
            splits[1].categories.merge(child.categories)
          else
            split_child = child.split(dimension, cutter)
            splits[0].children.push(split_child[0])
            splits[0].categories.merge(split_child[0].categories)
            splits[1].children.push(split_child[1])
            splits[1].categories.merge(split_child[1].categories)
          end
        end
      end
    end  # class Node

    def initialize(domain)
      @domain = domain
    end

    def insert(coords, data, cat = nil)
      point = {:coords => coords, :data => data, :category => cat}

      if @root.nil?
        @root = Node.new(@domain)
        @root.points.push(point)
        return
      end

      begin
        @root.insert(point)
      rescue NodeOverflow
        # The root contains too many points.  Split it.
        split_root = @root.split

        @root = Node.new(@domain)
        @root.children.concat(split_root)
      end
    end

    def query(region, cat = nil)
      return [] if @root.nil?
      @root.query(region, cat)
    end

  end  # class Tree

end  # module KDBTree
