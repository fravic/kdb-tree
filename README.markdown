This program uses a kd-B Tree (which combines the properties of kd-trees and
B-trees) to store merchants. Because the list of merchants is theoretically
infinite, a simpler kd-tree would be unacceptable since it does not allow for
dynamic insertion. I've also modified the kd-B Tree to allow us to filter by
category at query-time. The tree can easily be changed to use secondary storage
if there are too many entries to fit in memory.

I chose Ruby so that the tree can be easily included into a RoR or Sinatra
project. I've also included rspec tests to ensure that the tree functions
correctly.

References
----------
- Robinson, John T. "The K-D-B Tree: A Search Structure for Large
Multidimensional Dynamic Indexes", Carnegie-Mellon University, Pittsburgh, 1981.
