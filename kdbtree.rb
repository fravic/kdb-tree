require 'set'
require './region.rb'

module KDBTree

  class Tree

    REGION_NODE_CAPACITY = 5
    POINT_NODE_CAPACITY = 8

    class DomainError < Exception; end
    class NodeOverflow < Exception; end

    class Node

      def initialize(region, split_dimension, capacity)
        @region = region
        @split_dimension = split_dimension
        @categories = Set.new
        @capacity = capacity
      end
      attr_reader :region, :categories

      def split_nodes(dimension, cutter)
        subregions = @region.split(dimension, cutter)
        next_dim = (dimension + 1) % @region.num_dimensions

        return [self.class.new(subregions[0], next_dim, @capacity),
                self.class.new(subregions[1], next_dim, @capacity)]
      end

    end  # class Node

    class PointNode < Node

      def initialize(region, split_dimension = 0, capacity = POINT_NODE_CAPCITY)
        super(region, split_dimension, capacity)
        @points = []
      end
      attr_reader :points

      def query(region, cat = nil)
        # Return points within the region
        return @points.select { |p| region.contains_point?(p[:coords]) && (p[:category] == cat || cat.nil?) }
      end

      def insert(point)
        categories << point[:category]

        raise DomainError unless @region.contains_point?(point[:coords])

        @points.push(point)
        if @points.size > @capacity
          raise NodeOverflow
        end
      end

      def split(dimension = nil, cutter = nil)
        if dimension.nil? || cutter.nil?
          dimension = @split_dimension
          cutter = dimension_median(dimension)
        end

        splits = split_nodes(dimension, cutter)
        split_points(splits)

        return splits
      end

      private

      def dimension_median(dim)
        med_idx = (@points.size / 2).floor - 1
        @points.sort_by { |p| p[:coords][dim] }
        (@points[med_idx][:coords][dim] + @points[med_idx + 1][:coords][dim]) / 2
      end

      def split_points(splits)
        @points.each do |p|
          if splits[0].region.contains_point?(p[:coords])
            splits[0].insert(p)
          else
            splits[1].insert(p)
          end
        end
      end

    end  # class PointNode

    class RegionNode < Node

      def initialize(region, split_dimension = 0, capacity = REGION_NODE_CAPACITY)
        super(region, split_dimension, capacity)
        @children = []
      end
      attr_reader :children

      def query(region, cat = nil)
        # Recurse on children intersecting the regions and containing the correct categories
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

        @children.each_with_index do |child, idx|
          if child.region.contains_point?(point[:coords])
            begin
              child.insert(point)
            rescue NodeOverflow
              # The child contains too many points.  Split it.
              split_child = child.split
              @children.delete_at(idx)
              @children.concat(split_child)

              if @children.size > @capacity
                raise NodeOverflow
              end
            end
            return
          end
        end

        raise DomainError
      end

      def split(dimension = nil, cutter = nil)
        if dimension.nil? || cutter.nil?
          dimension = @split_dimension
          range = @region.ranges[dimension]
          cutter = (range.max - range.min) / 2 + range.min
        end

        splits = split_nodes(dimension, cutter)
        split_regions(splits, dimension, cutter)

        return splits
      end

      protected

      def add_child(child)
        @children.push(child)
        @categories.merge(child.categories)
      end

      private

      def split_regions(splits, dimension, cutter)
        @children.each do |child|
          if splits[0].region.contains_region?(child.region)
            splits[0].add_child(child)
          elsif splits[1].region.contains_region?(child.region)
            splits[1].add_child(child)
          else
            split_child = child.split(dimension, cutter)
            splits.each_with_index do |split, i|
              split.add_child(split_child[i])
            end
          end
        end
      end

    end  # class RegionNode

    def initialize(domain, region_capacity = REGION_NODE_CAPACITY, point_capacity = POINT_NODE_CAPACITY)
      @domain = domain
      @region_capacity = region_capacity
      @point_capacity = point_capacity

      if region_capacity < 2 || point_capacity < 2
        raise "Region and point capacities must be at least 2"
      end
    end
    attr_reader :root

    def insert(coords, data, cat = nil)
      point = {:coords => coords, :data => data, :category => cat}

      @root = PointNode.new(@domain, 0, @point_capacity) if @root.nil?

      begin
        @root.insert(point)
      rescue NodeOverflow
        # The root contains too many points.  Split it.
        split_root = @root.split

        @root = RegionNode.new(@domain, 0, @region_capacity)
        @root.children.concat(split_root)
      end
    end

    def query(region, cat = nil)
      return [] if @root.nil?
      @root.query(region, cat)
    end

  end  # class Tree

end  # module KDBTree
