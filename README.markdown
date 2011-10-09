Hello Square!
=============

Here's my solution to the Co-op coding question.  To run, ensure that Ruby
1.9.2+ is installed and then:

% chmod a+x square
% ./square payments.txt queries.txt

The solution uses a K-D-B Tree (which combines the properties of kd-trees and
B-trees) to store merchants.  Because the list of merchants is theoretically
infinite, a kd-tree would be unacceptable since it does not allow for dynamic
insertion.  The K-D-B Tree has been modified to allow us to filter by category
at query-time.  The tree can easily be changed to use secondary storage if there
are too many entries to fit in memory.

I chose Ruby so that the tree can be easily included into a RoR or Sinatra
project, which I hear you do some work with.  :)

[Fravic](http://fravic.com)


References
----------
- Robinson, John T. "The K-D-B Tree: A Search Structure for Large Multidimensional
  Dynamic Indexes", Carnegie-Mellon University, Pittsburgh, 1981.
