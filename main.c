#include <avr/io.h>
#include <avr/interrupt.h>
#define F_CPU 1000000
#include <util/delay.h>

// Func addr,Stack addr,parameter,priority
void setStackBase(void*,int,void*,void*,int);
int createThread(void* f,void* par){
static int i=1;
	setStackBase(f,i,(void*)(RAMEND-1-1-24-2*24-i*64/*64 now,until mallocator*/),par,0x10);
	return i++;
}

void test1(int a){
	while(1){PORTA ^=a;};
}

void init(void){
	DDRA=0xFF;
	PORTA=0x00;
	createThread(&test1,(void*)1);
	createThread(&test1,(void*)2);
	createThread(&test1,(void*)4);
	createThread(&test1,(void*)8);
	createThread(&test1,(void*)16);
	createThread(&test1,(void*)32);
	createThread(&test1,(void*)64);
	createThread(&test1,(void*)128);
}







