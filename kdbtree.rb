require 'set'
require './region.rb'

module KDBTree

  class Tree

    REGION_CAPACITY = 5
    POINT_CAPACITY = 8

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
        return @points.select { |p|
          region.contains_point?(p[:coords]) &&
          (p[:category].include?(cat) || cat.nil?)
        }
      end

      def insert(point)
        categories.merge(point[:category])

        raise DomainError unless @region.contains_point?(point[:coords])

        # If the point already exists, just add to its data array
        exists = @points.select { |p| p[:coords] == point[:coords] }.first
        if !exists.nil?
          exists[:data].concat(point[:data])
          exists[:category].concat(point[:category])
        else
          @points.push(point)
        end

        if @points.size > @capacity
          raise NodeOverflow
        end
      end

      def split(dimension = nil, cutter = nil)
        if dimension.nil? || cutter.nil?
          dimension = @split_dimension

          # If all of the points are at the same coord on this dimension
          # choose another dimension to avoid a NodeOverflow
          while points_on_line?(dimension)
            dimension = (dimension + 1) % @region.num_dimensions
            if dimension == @split_dimension
              # All dimensions failed: splitting is impossible
              throw "Too many points on same coordinate"
            end
          end

          cutter = dimension_average(dimension)
        end

        splits = split_nodes(dimension, cutter)
        split_points(splits)

        return splits
      end

      private

      def points_on_line?(dim)
        @points.each_with_index do |p, i|
          next if i == 0
          on_line = p[:coords][dim] == @points[i-1][:coords][dim]
          return false unless on_line
        end
        return true
      end

      def dimension_average(dim)
        coords = @points.map { |p| p[:coords][dim] }
        return coords.inject(:+).to_f / coords.size
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

      def initialize(region, split_dimension = 0, capacity = REGION_CAPACITY)
        super(region, split_dimension, capacity)
        @children = []
      end
      attr_reader :children

      def query(region, cat = nil)
        # Recurse on children intersecting the regions with the correct category
        points = []
        @children.each do |child|
          category_match = (cat.nil? || child.categories.include?(cat))
          if child.region.intersects?(region) && category_match
            points.concat(child.query(region, cat))
          end
        end
        return points
      end

      def insert(point)
        categories << point[:category].first

        region = @children.select { |child|
          child.region.contains_point?(point[:coords])
        }.first
        raise DomainError if region.nil?

        begin
          region.insert(point)
        rescue NodeOverflow
          # The child contains too many points.  Split it.
          split_child = region.split
          @children.delete(region)
          @children.concat(split_child)

          if @children.size > @capacity
            raise NodeOverflow
          end
        end
      end

      def split(dimension = nil, cutter = nil)
        if dimension.nil? || cutter.nil?
          dimension = @split_dimension
          range = @region.ranges[dimension]
          cutter = (range.end - range.begin) / 2.0 + range.begin
        else
          # Ensure that the passed cutter is valid
          range = @region.ranges[dimension]
          throw DomainError unless range.include?(cutter)
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

    def initialize(domain,
                   region_cap = REGION_CAPACITY,
                   point_cap = POINT_CAPACITY)
      @domain = domain
      @region_capacity = region_cap
      @point_capacity = point_cap

      if region_cap < 2 || point_cap < 2
        raise "Region and point capacities must be at least 2"
      end
    end
    attr_reader :root

    def insert(coords, data, cat = nil)
      # Convert the data into array elements for internal collapsing
      point = {:coords => coords, :data => [data], :category => [cat]}

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

      # Uncollapse data points for output
      output = []
      @root.query(region, cat).each do |p|
        p[:data].each_with_index do |data, i|
          next unless p[:category][i] == cat || cat.nil?
          output << {
            :coords => p[:coords],
            :data => p[:data][i],
            :category => p[:category][i]
          }
        end
      end
      return output
    end

  end  # class Tree

end  # module KDBTree
