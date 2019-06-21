module prescaler(
  input wire inclk,
  output reg outclk
    );

reg [3:0] counter;

always @(posedge inclk)
begin
  counter <= counter + 1'b1;
  if(counter==4'b1111)
     outclk<=~outclk;
end 
endmodule
