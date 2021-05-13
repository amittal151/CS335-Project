int main(){
	char* a = "THIS IS A STRING";
	char* b = "ANOTHER ONE";
	char* c = "ANOTHER ONE";
	if(!strcmp(a,b)){
		printf("a and b are equal\n");
	}
	else if(!strcmp(a,c)){
		printf("a and c are equal\n");
	}
	else if(!strcmp(b,c)){
		printf("b and c are equal\n");
	}
	else printf("none are equal\n");
	
	printf("LENGTH of a = %d\n", strlen(a));
}
