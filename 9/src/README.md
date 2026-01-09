# Day 9 Solution - Polygon Rectangle Finding

This solution finds the largest rectangle that fits inside a polygon. This implementation was developed with the help of AI.

## Problem Overview

Given a list of 2D coordinates that form a polygon (connected in order), we need to:
- **Part 1**: Find the largest rectangle formed by any two points (simple bounding box)
- **Part 2**: Find the largest rectangle where ALL points inside the rectangle are also inside or on the polygon boundary

## The Challenge

Part 2 is computationally expensive because:
- Input coordinates can be very large (e.g., 96000-98000 for x, 50000-62000 for y)
- A naive approach would check every coordinate point in potential rectangles
- This could mean checking millions or billions of points for each rectangle candidate

## Solution: Coordinate Compression

### What is Coordinate Compression?

Coordinate compression is an optimization technique that reduces a large coordinate space to a smaller, more manageable one without losing critical information.

**Key Insight**: For a polygon problem, the only coordinates that matter are where the polygon vertices are located. Between two consecutive vertex coordinates, the inside/outside relationship remains constant.

### Example

Suppose we have a polygon with these x-coordinates: `[10, 50, 100, 1000000]`

**Without compression:**
- To check a rectangle from x=10 to x=1000000
- We'd need to check: 10, 11, 12, 13, ..., 999999, 1000000
- That's ~1 million x-coordinates!

**With compression:**
- The polygon only has "interesting" boundaries at: `[10, 50, 100, 1000000]`
- Between x=10 and x=50, no polygon edges exist, so inside/outside status is uniform
- We only check: 10, 50, 100, 1000000
- That's only 4 x-coordinates!

### The Algorithm (Part 2)

#### Step 1: Collect and Compress Coordinates (Lines 46-64)

```zig
// Collect all unique x and y coordinates from polygon vertices
x_coords = [97585, 98011, 97624, ...] 
y_coords = [50248, 51467, 52664, ...]

// Sort and remove duplicates
unique_x = [96374, 96830, 97198, ..., 98011]  // maybe ~50 unique values
unique_y = [50248, 51467, 52664, ..., 62214]  // maybe ~50 unique values
```

#### Step 2: Create Compressed Polygon (Lines 66-74)

Map each polygon vertex from original coordinates to compressed indices:

```
Original: (97585, 50248) → Compressed: (5, 0)
Original: (98011, 51467) → Compressed: (30, 1)
...
```

Where the indices represent positions in the `unique_x` and `unique_y` arrays.

#### Step 3: Try Rectangle Candidates (Lines 79-90)

For each pair of polygon vertices, use them as opposite corners of a potential rectangle.

In compressed space:
```
p1 = (5, 0)
p2 = (30, 20)
```

This represents a rectangle in compressed coordinates from (5,0) to (30,20).

#### Step 4: Validate Rectangle (Lines 92-125)

##### 4a. Check Corners (Lines 100-110)

Convert the 4 corners back to original coordinates and verify each is inside or on the polygon:

```zig
corner_compressed = (5, 0)
corner_original = (unique_x[5], unique_y[0]) = (97585, 50248)
// Check if (97585, 50248) is inside/on polygon
```

##### 4b. Sample Interior Points (Lines 112-125)

**This is where compression shines!**

Instead of checking every coordinate in the rectangle, we only check at compressed grid intersections:

```zig
for cx from 5 to 30:        // Only 26 iterations (not thousands!)
    for cy from 0 to 20:    // Only 21 iterations
        original = (unique_x[cx], unique_y[cy])
        check if original point is inside polygon
```

We check at most 26 × 21 = 546 points instead of potentially millions!

#### Step 5: Calculate Real Area (Lines 127-141)

If all checks pass, compute the area using the ACTUAL original coordinates:

```zig
min_x = unique_x[5]  = 97585
max_x = unique_x[30] = 98011
min_y = unique_y[0]  = 50248
max_y = unique_y[20] = 62214

width = 98011 - 97585 + 1 = 427
height = 62214 - 50248 + 1 = 11967
area = 427 × 11967 = 5,109,909
```

### Why This Works

The polygon is formed by straight line segments between vertices. The inside/outside status of points can only change:
- At x-coordinates where polygon vertices exist
- At y-coordinates where polygon vertices exist

Between these "critical" coordinates, the relationship is constant. Therefore, checking only at vertex coordinates is sufficient to validate the entire rectangle.

### Performance Improvement

**Before (naive sampling with step=100):**
- Rectangle spanning (96374, 50248) to (98011, 62214)
- Width: ~1,600 coordinates, Height: ~12,000 coordinates
- With step=100: ~16 × 120 = 1,920 sample points per rectangle
- With many rectangle candidates: potentially millions of checks

**After (coordinate compression):**
- ~50 unique x-coordinates × ~50 unique y-coordinates
- Maximum ~2,500 checks per rectangle candidate
- More importantly: no wasted checks on coordinates where nothing changes

For large coordinate spaces with relatively few polygon vertices, this can be 100-1000x faster!

## Helper Functions

### `pointInPolygon` (Lines 172-190)
Uses ray casting algorithm to determine if a point is inside a polygon.

### `isOnPolygonEdge` (Lines 193-220)
Checks if a point lies exactly on a polygon edge (horizontal or vertical line segments).

### `deduplicateSorted` (Lines 148-162)
Removes duplicate values from a sorted array.

### `findIndex` (Lines 164-169)
Binary search would be more efficient here, but linear search is simple and works fine for small coordinate sets.

## Complexity Analysis

- **Time Complexity**: O(n² × k²) where n = number of polygon vertices, k = unique coordinates
  - For typical inputs: k ≈ n, so O(n⁴)
  - Without compression: O(n² × W × H) where W,H are coordinate ranges (can be millions)
  
- **Space Complexity**: O(n) for storing unique coordinates and compressed polygon

## Credits

This solution was developed with the assistance of AI to implement the coordinate compression optimization technique.
