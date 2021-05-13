int isSafe(int M[][5], int row, int col, int visited[][5])
{
    // row number is in range, column number is in range and value is 1
    // and not yet visited
    return (row >= 0) && (row < 5) && (col >= 0) && (col < 5) && (M[row][col] && !visited[row][col]);
}
 
// A utility function to do DFS for a 2D boolean matrix. It only considers
// the 8 neighbours as adjacent vertices
void DFS(int M[][5], int row, int col, int visited[][5])
{
    // These arrays are used to get row and column numbers of 8 neighbours
    // of a given cell
    int rowNbr[] = { -1, -1, -1, 0, 0, 1, 1, 1 };
    int colNbr[] = { -1, 0, 1, -1, 1, -1, 0, 1 };
 	int k;
    // Mark this cell as visited
    visited[row][col] = 1;
 
    // Recur for all connected neighbours
    for (k = 0; k < 8; ++k)
        if (isSafe(M, row + rowNbr[k], col + colNbr[k], visited))
            DFS(M, row + rowNbr[k], col + colNbr[k], visited);
}
 
// The main function that returns count of islands in a given boolean
// 2D matrix
int countIslands(int M[][5])
{
    // Make a int array to mark visited cells.
    // Initially all cells are unvisited
    int visited[5][5];
    //memset(visited, 0, sizeof(visited));
 
    // Initialize count as 0 and travese through the all cells of
    // given matrix
    int count = 0, i, j;
    for(i = 0; i<5; i++)
    	for(j = 0; j<5; j++) visited[i][j] = 0;
    
    for (i = 0; i < 5; ++i)
        for (j = 0; j < 5; ++j)
            if (M[i][j] && !visited[i][j]) // If a cell with value 1 is not
            { // visited yet, then new island found
                DFS(M, i, j, visited); // Visit all cells in this island.
                ++count; // and increment island count
            }
 
    return count;
}
 
// Driver program to test above function
int main()
{
    int M[][5] = { { 1, 1, 0, 0, 0 },
                     { 0, 1, 0, 0, 1 },
                     { 1, 0, 0, 1, 1 },
                     { 0, 0, 0, 0, 0 },
                     { 1, 0, 1, 0, 1 } };
 
    printf("Number of islands is: %d\n", countIslands(M));
 
    return 0;
}
