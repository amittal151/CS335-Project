struct node {
    int data;
    struct node* left, *right;
};

 
/* Helper function that allocates a new node with the
   given data and NULL left and right pointers. */
  

struct node* newNode(int data)
{
    struct node* node
        = (struct node*)malloc(sizeof(struct node));
    node->data = data;
    node->left = (struct node*)malloc(sizeof(struct node));
    node->left->data = -1;
    node->right = (struct node*)malloc(sizeof(struct node));
 	node->right->data = -1;
    return (node);
}
 
/* Given a binary tree, print its nodes according to the
  "bottom-up" postorder traversal. */
void printPostorder(struct node* node)
{
    if (node->data == -1)
        return;
 
    // first recur on left subtree
    printPostorder(node->left);
 
    // then recur on right subtree
    printPostorder(node->right);
 
    // now deal with the node
    printf("%d ", node->data);
}
 
/* Given a binary tree, print its nodes in inorder*/
void printInorder(struct node* node)
{
    if (node->data == -1)
        return;
 
    /* first recur on left child */
    printInorder(node->left);
 
    /* then print the data of node */
    printf("%d ", node->data);
 
    /* now recur on right child */
    printInorder(node->right);
}
 
/* Given a binary tree, print its nodes in preorder*/
void printPreorder(struct node* node)
{
    if (node->data == -1)
        return;
 
    /* first print data of node */
    printf("%d ", node->data);
 
    /* then recur on left sutree */
    printPreorder(node->left);
 
    /* now recur on right subtree */
    printPreorder(node->right);
}

 
/* Driver program to test above functions*/
int main()
{
    struct node* root = newNode(1);
    root->left = newNode(2);
    root->right = newNode(3);
    root->left->left = newNode(4);
    root->left->right = newNode(5);
 
    printf("Preorder traversal of binary tree is \n");
    printPreorder(root);
 
    printf("\nInorder traversal of binary tree is \n");
    printInorder(root);
 
    printf("\nPostorder traversal of binary tree is \n");
    printPostorder(root);
    printf("\n");
    return 0;
}