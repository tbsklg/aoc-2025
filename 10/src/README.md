# Part 2 Algorithm Explanation

## Problem Overview

Part 2 involves finding the minimum number of button presses needed to achieve specific joltage values at each light position. Unlike Part 1 (which uses BFS for lights toggling), Part 2 requires solving a system of linear equations to determine the optimal button press combinations.

## Algorithm: Gaussian Elimination with DFS Search

The solution uses a combination of **Gaussian Elimination** and **Depth-First Search (DFS)** to find the minimum number of button presses.

### Step 1: Matrix Construction

The problem is modeled as a system of linear equations:
- Each **row** represents a light position
- Each **column** represents a button
- Matrix values are 1 if pressing that button affects that light, 0 otherwise
- The last column contains the target joltage values

Example:
```
Button1  Button2  Button3  | Target
   1        0        1     |   3
   0        1        1     |   5
   1        1        0     |   4
```

This represents: `Button1 * x + Button2 * y + Button3 * z = Target` for each row.

### Step 2: Gaussian Elimination (main.zig:251-309)

The algorithm performs Gaussian Elimination to convert the matrix into **Reduced Row Echelon Form (RREF)**:

1. **Pivot Selection**: Find the row with the largest absolute value in the current column (partial pivoting)
2. **Free Variables**: If all values in a column are ~0, mark that variable as "independent" (free)
3. **Row Operations**: 
   - Normalize the pivot row by dividing by the pivot value
   - Eliminate the current column in all other rows
4. **Classification**: Variables are classified as:
   - **Dependent**: Variables with pivots (their values depend on independent variables)
   - **Independent**: Free variables that can take any value

### Step 3: DFS Search (main.zig:352-376)

Since independent variables can take multiple values, we use DFS to explore all possible combinations:

1. **Base Case**: When all independent variables are assigned, calculate dependent variables
2. **Validation**: Check if the solution is valid (main.zig:311-340):
   - Dependent variables must be **non-negative integers**
   - Calculate dependent values using: `dependent = target - sum(independent_i * coefficient_i)`
3. **Pruning**: Stop exploring if current total exceeds the minimum found so far
4. **Optimization**: Limit search space to `[0, max_joltage]` for each independent variable

### Step 4: Solution Validation

For each combination of independent variables:
- Calculate dependent variable values from the RREF matrix
- Check that all values are non-negative
- Check that all values are whole numbers (within EPSILON tolerance)
- Sum all button presses and update the minimum if better

## Key Implementation Details

- **EPSILON = 1e-9**: Tolerance for floating-point comparisons
- **Pruning**: DFS stops early if partial sum exceeds current minimum
- **Bounded Search**: Independent variables are searched in range `[0, max_joltage + 1]`

## Example Flow

```
Input: [#.##.] (0,1,2) (1,3) (2,3,4) {3,5,4,7}

1. Create matrix:
   [1 0 0 | 3]
   [1 1 0 | 5]
   [1 0 1 | 4]

2. Gaussian Elimination → RREF:
   [1 0 0 | 3]
   [0 1 0 | 2]
   [0 0 1 | 1]

3. All variables are dependent (no free variables)
4. Solution: Button1=3, Button2=2, Button3=1
5. Total presses = 6
```

## Time Complexity

- **Gaussian Elimination**: O(rows × cols²)
- **DFS Search**: O(max_joltage^(num_independent_variables))
- Overall: Exponential in the number of independent variables, but pruning helps significantly

## References

- [icub3d](https://www.youtube.com/watch?v=xibCHVRF6oI)
- Implementation developed with AI assistance

## Notes

This approach works well when the number of independent variables is small. The pruning optimization and bounded search space make it practical for typical problem inputs.
