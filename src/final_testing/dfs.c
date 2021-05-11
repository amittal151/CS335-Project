void DFS(int i, int G[][10], int n, int* visited);
   //n is no of vertices and graph is sorted in array G[10][10]
 
void main()
{
    int i,j;
    int G[10][10],visited[10],n; 
    printf("Enter number of vertices:");
   
	scanf("%d",&n);
 
    //read the adjecency matrix
	printf("\nEnter adjecency matrix of the graph:");
   
	for(i=0;i<n;i++)
       for(j=0;j<n;j++)
			scanf("%d",&G[i][j]);
 
    //visited is initialized to zero
   for(i=0;i<n;i++)
        visited[i]=0;
 
    DFS(0, G, n, visited);
}
 
void DFS(int i, int G[][10], int n, int* visited)
{
    int j;
	printf("VERT = %d\n",i);
    visited[i]=1;
	
	for(j=0;j<n;j++)
       if(!visited[j]&&G[i][j]==1)
            DFS(j, G, n, visited);
}

