module hardware (
  input clk_16mhz,

  output user_led,
  output usb_pullup
);
  // Drive the USB pull-up resistor low to disable USB
  assign usb_pullup = 0;

  // Incrementing clock to slow down our selection of the bit pattern being
  // output to the LED
  reg [25:0] blink_counter = 0;

  // Pattern that will be displayed on the LED over time
  wire [31:0] blink_pattern = 32'b101011110000101011110000101011110000;

  // Update our clock counter every clock cycle
  always @(posedge clk_16mhz) begin
    blink_counter <= blink_counter + 1;
  end

  // Use the high order bits of our blink counter to select the position in
  // our blink pattern we should be outputting
  assign user_led = blink_pattern[blink_counter[25:21]];
endmodule
