import rv32i_types::*;

module cmp(
		input branch_funct3_t 	cmpop,
		input rv32i_word 			in_A,
		input rv32i_word			in_B,
		output logic 				br_en
);
	
	always_comb
	begin
		unique case(cmpop)
			beq: 		br_en = (in_A == in_B);
			bne: 		br_en = (in_A != in_B);
			blt: 		br_en = ($signed(in_A) < $signed(in_B));
			bge: 		br_en = ($signed(in_A) >= $signed(in_B));
			bltu: 	br_en = (in_A < in_B);
			bgeu: 	br_en = (in_A >= in_B);
			default: br_en = 0;
		endcase
	end

endmodule: cmp