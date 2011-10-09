module KDBTree

  # A region is an array of n 1-dimensional range objects representing an n-hyperrectangle.
  class Region
    def initialize(ranges)
      @ranges = ranges
    end
    attr_reader :ranges

    def num_dimensions
      @ranges.size
    end

    def contains_point?(coords)
      @ranges.each_with_index do |r, i|
        return false unless r.include?(coords[i])
      end
      return true
    end

    def contains_region?(region_y)
      @ranges.each_with_index do |r, i|
        r_y = region_y.ranges[i]
        return false unless r.min <= r_y.min && r.max >= r_y.max
      end
      return true
    end

    def intersects?(region_y)
      @ranges.each_with_index do |r, i|
        r_y = region_y.ranges[i]
        return false unless (r.first <= r_y.last) && (r_y.first <= r.last)
      end
      return true
    end

    def split(dimension, splitter)
      left = Array.new(@ranges)
      right = Array.new(@ranges)

      if right[dimension].max < splitter
        left, right = right, left
      end

      left[dimension] = (left[dimension].min..splitter)
      right[dimension] = (splitter..right[dimension].max)

      return [Region.new(left), Region.new(right)]
    end
  end

end
