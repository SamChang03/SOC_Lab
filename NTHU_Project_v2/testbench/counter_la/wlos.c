#include "qsort.h"
#include "fir.h"
#include "matmul.h"
#include <defs.h>


void __attribute__ ( ( section ( ".mprjram" ) ) ) initfir() {
	//initial fir
	for (int n = 0; n < DATA_LENGTH; n++) {
		x[n] = n;
	}
}

void __attribute__ ( ( section ( ".mprjram" ) ) ) hardware_accelerator_initialization(){
	
	//------------------------------- (FIR part) -------------------------------//
	initfir();

	int WB_return_data;
	int i;
	
	// check idle
	WB_return_data = *((int*)FIR_BASE_ADDRESS); //WB_read((int*)FIR_BASE_ADDRESS);
	while (((WB_return_data>>2)&1)==0){ // which means "ap_idle_done_start[2]==0"
		WB_return_data = *((int*)FIR_BASE_ADDRESS); //WB_read((int*)FIR_BASE_ADDRESS);
	}

	// Program length, and tap parameters
	*((int*)(FIR_BASE_ADDRESS+0x10))=DATA_LENGTH; //WB_write((int*)(FIR_BASE_ADDRESS+0x10), DATA_LENGTH);
	for(i=0; i<N; i=i+1){ // Here "N" means the number of taps, which is "11" in lab3
		*((int*)(FIR_BASE_ADDRESS+0x20+4*i))=taps[i]; //WB_write((int*)(FIR_BASE_ADDRESS+0x20+4*i), taps[i]);
	}

	// Provide the base address of x[n] array to DMA_FIR (base address configuration address map as 8'h88)
	*((int*)(FIR_BASE_ADDRESS+0x88))=(int)(&x); //WB_write((int*)(FIR_BASE_ADDRESS+0x88), &x);


	//------------------------------- (MM part) -------------------------------//

	// check idle
	WB_return_data = *((int*)MM_BASE_ADDRESS);
	while (((WB_return_data>>2)&1)==0){
		WB_return_data = *((int*)MM_BASE_ADDRESS);
	}

	// Provide the base address of A matrix (base address configuration address map as 8'h04) & B matrix (base address configuration address map as 8'h08) to DMA_MM
	*((int*)(MM_BASE_ADDRESS+0x04))=(int)(&A);
	*((int*)(MM_BASE_ADDRESS+0x08))=(int)(&B);
	
	//------------------------------- (QS part) -------------------------------//

	// check idle
	WB_return_data = *((int*)QS_BASE_ADDRESS);
	while (((WB_return_data>>2)&1)==0){
		WB_return_data = *((int*)QS_BASE_ADDRESS);
	}

	// Provide the base address of Target_array (base address configuration address map as 8'h04)to DMA_QS
	*((int*)(QS_BASE_ADDRESS+0x04))=(int)(&Target_array);


	//------------------------------- (FIR part) -------------------------------//
	// Program ap_start
	*((int*)(FIR_BASE_ADDRESS))=1; //WB_write((int*)(FIR_BASE_ADDRESS), 1); // which means "ap_idle_done_start==1"
	


	//------------------------------- (MM part) -------------------------------//
	// Program ap_start
	*((int*)(MM_BASE_ADDRESS))=1;
	
	//------------------------------- (QS part) -------------------------------//
	// Program ap_start
	*((int*)(QS_BASE_ADDRESS))=1;
	
}


int* __attribute__ ( ( section ( ".mprjram" ) ) ) hardware_accelerator_check_result_FIR(){

	//------------------------------- (FIR part) -------------------------------//
	int WB_return_data;

	// check done
	WB_return_data = *((int*)FIR_BASE_ADDRESS);
	while (((WB_return_data>>6)&1)==0){ // that is, to check "FIR_done_shown_in_DMA"
		WB_return_data = *((int*)FIR_BASE_ADDRESS);
	}
	return (int*)(x)+63;
}


int* __attribute__ ( ( section ( ".mprjram" ) ) ) hardware_accelerator_check_result_MM(){

	//------------------------------- (MM part) -------------------------------//
	int WB_return_data;
	
	WB_return_data = *((int*)MM_BASE_ADDRESS);
	while (((WB_return_data>>6)&1)==0){ // that is, to check "MM_done_shown_in_DMA"
		WB_return_data = *((int*)MM_BASE_ADDRESS);
	}
	return (int*)(A)+15;
}

int* __attribute__ ( ( section ( ".mprjram" ) ) ) hardware_accelerator_check_result_QS(){

	//------------------------------- (QS part) -------------------------------//
	int WB_return_data;
	
	WB_return_data = *((int*)QS_BASE_ADDRESS);
	while (((WB_return_data>>6)&1)==0){ // that is, to check "QS_done_shown_in_DMA"
		WB_return_data = *((int*)QS_BASE_ADDRESS);
	}
	return (int*)(Target_array)+9;
}
