%{
	#include <stdio.h>
	#include <stdlib.h>
	#include <ctype.h>
	#include <string.h>
	#include <unistd.h>
	#include <sys/types.h>
	#include <sys/wait.h>
	#define LEN 20
%}
%union {
 	char *sym;
}
%token String
%right '&'
%type <sym> String ExecFile
%type <sym> '&'
%%

Command:
| Command '\n'{printf("mysh>");}
| Command Prog '\n'{make_exec(); reset(); printf("mysh>");}
| Command Prog '&' '\n' {make_bgexec();reset();printf("mysh>");}
;
Prog: ExecFile Args { }
;
ExecFile: String{ push(); }
;
Args:
| Args String { push(); }
;
%%

char *backjobs="&";
char *stack[LEN];
char buf[100];
char *p=buf;
char *path[]={"/bin/","/usr/bin/",NULL};
int lineno=0;
int top=0;

int main(int argc,char *argv[])
{
	printf("mysh>");
	yyparse();
}

yylex()
{
	int c;
	p=buf;
	while ((c=getchar())==' ' || c=='\t');
	if (c==EOF){
		printf("\n");
		return 0;
	}
	if (c!='\n'){
		do {
			*p++=c;
			c=getchar();
		}while (c!= ' ' && c!= '\t' && c!= '\n');
		ungetc(c,stdin);
		*p='\0';
		yylval.sym=buf;
		if (!strcmp(buf,backjobs)){
			return '&';
		}
		else{
			return String;
		}
	}
	else{
		lineno++;
	}
	return c;
}

yyerror(char *s)
{
	warning(s,(char*)0);
}

warning(char *s,char *t)
{
	if(t){
		fprintf(stderr,"%s",t);
	}
	fprintf(stderr," errno near line %d\n",lineno);
}

make_bgexec()
{
	pid_t pid;
	char temp[50];
	char *p_path;
	int i=0,ret=0;
	if ((pid=fork())<0){
		perror("fork faild");
		exit(EXIT_FAILURE);
	}

	if(!pid){
		while((p_path=path[i])!=NULL){
			strcpy(temp,stack[0]);
			strcpy(stack[0],path[i]);
			strcpy(stack[0],temp);
			i++;
			ret=execv(stack[0],stack);
			if(ret<0){
				strcpy(stack[0],temp);
			}
		}
		if(ret<0){
			printf("mysh:command not found 1\n");
		}
	}
	if(pid>0){
		waitpid(pid,NULL,WNOHANG);
	}
}

make_exec()
{
	pid_t pid;
	char temp[50];
	char *p_path;
	int i=0,ret=0;

	if((pid=fork())<0){
		perror("fork faild");
		exit(EXIT_FAILURE);
	}

	if(!pid){
		while ((p_path=path[i])!=NULL){
			strcpy(temp,stack[0]);
			strcpy(stack[0],path[i]);
			strcat(stack[0],temp);
			i++;
			ret=execv(stack[0],stack);
			if(ret<0){
				strcpy(stack[0],temp);
			}
		}
		if(ret<0){
			printf("mysh:command not found 2\n");
		}
	}
	if(pid>0){
		waitpid(pid,NULL,0);
	}
}

reset()
{
	int i;
	for(i=0;i<top;i++){
		free(stack[i]);
		stack[i]=NULL;
	}
	top=0;
}

push()
{
	char *temp=NULL;
	if(top==0){
		temp=(char*)malloc(sizeof(char)*100);
	}
	else{
		temp=(char*)malloc(strlen(buf)+1);
	}
	strcpy(temp,buf);
	stack[top]=temp;
	top++;
}
