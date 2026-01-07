# Path Counting Through Graph Nodes

## Problem Overview

Given a directed graph represented as adjacency lists, count the number of distinct paths between nodes. Part 2 specifically requires finding all paths that pass through both "dac" and "fft" nodes.

## Input Format

Each line defines a node and its outgoing edges:
```
svr: aaa bbb
aaa: fft
fft: ccc
```

This represents a graph where "svr" has edges to "aaa" and "bbb", "aaa" has an edge to "fft", etc.

## Algorithm: Dynamic Programming with Memoization

### Part 1: Count All Paths (main.zig:25-39)

Count all paths from a start node (e.g., "you") to the target node "out".

### Part 2: Count Paths Through Required Nodes (main.zig:41-62)

To find paths that go through both "dac" and "fft", we use the **multiplication principle**:

1. **Path Decomposition**: A path from "svr" → "out" that goes through both nodes can be broken into segments:
   - Paths from "svr" → "fft"
   - Paths from "fft" → "dac"  
   - Paths from "dac" → "out"

2. **Multiplication Principle**: The total number of paths through both nodes is:
   ```
   total_paths = (svr → fft) × (fft → dac) × (dac → out)
   ```

3. **Key Insight**: This works because:
   - Any path segment is independent of the others
   - We can combine any path from svr→fft with any path from fft→dac with any path from dac→out
   - The graph structure ensures "fft" comes before "dac" in valid paths

### Core Function: find_paths (main.zig:64-82)

The function uses recursive DFS with memoization to count paths:

```zig
fn find_paths(allocator, current, target, devices, distances) !usize
```

**Algorithm Steps**:

1. **Base Case** (line 65-67): 
   - If current node equals target, return 1 (found one path)

2. **Handle Dead Ends** (line 69):
   - If current node has no neighbors, return 0 (dead end)

3. **Memoization Check** (line 73):
   - Check if we've already computed paths from this neighbor
   - If yes, reuse the cached result

4. **Recursive Exploration** (line 74):
   - Recursively count paths from each neighbor to target
   - Cache the result for future lookups

5. **Sum All Paths** (line 78):
   - Sum paths from all neighbors to get total paths through current node

**Key Implementation Details**:

- **Memoization**: Uses `std.StringHashMap(usize)` to cache results
- **Cache Clearing** (lines 47, 50, 53): The cache is cleared between different path computations because paths from node X to target A are different from X to target B
- **Dead End Handling**: Returns 0 when a node has no outgoing edges (line 69)

## Example

Given this graph:
```
svr: aaa bbb
aaa: fft
fft: ccc
bbb: tty
tty: ccc
ccc: ddd eee
ddd: hub
hub: fff
eee: dac
dac: fff
fff: ggg hhh
ggg: out
hhh: out
```

To find paths through both "fft" and "dac":

1. **svr → fft**: Count paths (e.g., 1 path: svr→aaa→fft)
2. **fft → dac**: Count paths (e.g., 1 path: fft→ccc→eee→dac)
3. **dac → out**: Count paths (e.g., 2 paths: dac→fff→ggg→out, dac→fff→hhh→out)
4. **Total**: 1 × 1 × 2 = 2 paths through both nodes

## Time Complexity

- **Without memoization**: O(V + E) for each path computation where V is vertices and E is edges
- **With memoization**: O(V + E) total, as each node is visited at most once per target
- **Part 2 total**: O(3 × (V + E)) for three separate path computations

## Space Complexity

- **Recursion stack**: O(V) in worst case (longest path)
- **Memoization cache**: O(V) to store path counts for each node
- **Graph storage**: O(V + E) for adjacency lists

## Notes

- The solution assumes the graph is a DAG (Directed Acyclic Graph) - otherwise path counting could be infinite
- The multiplication principle only works when the required nodes appear in a fixed order in all valid paths
- Clearing the memoization cache between computations is crucial for correctness
