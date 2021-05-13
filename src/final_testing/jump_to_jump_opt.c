int main(){
	// Jump to jump optimzation
	// labels corresponding to B to E wont be emitted 
	A: 
		printf("HELLO\n");
		goto B;
	B:
		goto C;
	C:
		goto D;
	D:
		goto E;
	E:
		goto F;
	F:
		printf("HELLO USER\n");
}
