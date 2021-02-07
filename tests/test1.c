int main () {
    // read_input_file();
    printf("\nPlease enter Source(s) and Sink(t) :\n");
    int s=0;
    int t=n-1;
    scanf("%d %d",&s,&t);
    printf("\nMax Flow : %d\n",max_flow(s,t));
    return 0;
}
