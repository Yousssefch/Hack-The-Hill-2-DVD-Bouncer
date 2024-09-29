/****************************************************************************
FILENAME     :  video_uut.sv
PROJECT      :  Hack the Hill 2024
****************************************************************************/

/*  INSTANTIATION TEMPLATE  -------------------------------------------------

video_uut video_uut (       
    .clk_i          ( ),//               
    .cen_i          ( ),//
    .vid_sel_i      ( ),//
    .vdat_bars_i    ( ),//[19:0]
    .vdat_colour_i  ( ),//[19:0]
    .fvht_i         ( ),//[ 3:0]
    .fvht_o         ( ),//[ 3:0]
    .video_o        ( ) //[19:0]
);

-------------------------------------------------------------------------- */


module video_uut (
    input  wire         clk_i           ,// clock
    input  wire         cen_i           ,// clock enable
    input  wire         vid_sel_i       ,// select source video
    input  wire [19:0]  vdat_bars_i     ,// input video {luma, chroma}
    input  wire [19:0]  vdat_colour_i   ,// input video {luma, chroma}
    input  wire [3:0]   fvht_i          ,// input video timing signals
    output wire [3:0]   fvht_o          ,// 1 clk pulse after falling edge on input signal
    output wire [19:0]  video_o          // 1 clk pulse after any edge on input signal
); 

reg [19:0]  vid_d1;
reg [3:0]   fvht_d1;

wire h_in = fvht_i[1];
reg h_dly;
wire h_pos = h_in & ~h_dly;
wire h_neg = ~h_in & h_dly;


wire v_in = fvht_i[2];
reg v_dly;
wire v_pos = v_in & ~v_dly;
wire v_neg = ~v_in & v_dly;

reg [30:0] pixel_array [0:99][0:99];

integer i = 0;
integer j =0;

reg[15:0] h_pointer = 0;
reg[15:0] v_pointer = 0;

reg[15:0] h_counter = 0;
reg[15:0] v_counter = 0;

reg[15:0] box_width = 500;
reg[15:0] box_height = 500;
reg[15:0] h_start_position = 250;
reg[15:0] v_start_position = 250;

reg [12:0] x_offset = 0;
reg [12:0] y_offset = 0;
reg x_direction = 1; //moving right
reg y_direction = 1; //moving verticaly 
localparam RECT_COLOR = 20'hFFFFFF;
localparam BG_COLOR = 20'h0D98F1;
localparam SPEED=5;



wire is_in_rectangle = (h_counter >= h_start_position + x_offset - box_width / 2) && 
							  (h_counter < h_start_position + x_offset + box_width / 2) && 
							  (v_counter >= v_start_position + y_offset - box_height / 2) && 
							  (v_counter < v_start_position + y_offset + box_height / 2); 

							  
							  
wire is_in_circle = ( (h_counter - (h_start_position + x_offset)) * (h_counter - (h_start_position + x_offset)) +
                      (v_counter - (v_start_position + y_offset)) * (v_counter - (v_start_position + y_offset)) )
                      <= (box_width/2 * box_width/2);
							  
    

always @(posedge clk_i) begin
    if (cen_i) begin
        // Update horizontal and vertical delays
        h_dly <= h_in;
        v_dly <= v_in;
        
        // Reset horizontal counter at each new horizontal line
        h_counter <= (h_neg) ? 0 : h_counter + 1;
        
        // Reset vertical counter at each new frame
        if (h_pos && v_pos)
            v_counter <= 0;
        else if (h_pos)
            v_counter <= v_counter + 1;
        
        // Horizontal direction logic
        if (h_counter == 0 && v_counter == 0) begin
            if (x_direction) begin
                if (h_start_position + x_offset+(box_width/2) < 1919) begin
                    x_offset <= x_offset + SPEED;  // Move to the right
                end else begin
                    x_direction <= 0;  // Change direction to left
                end
            end else begin
                if (x_offset > 0) begin
                    x_offset <= x_offset - SPEED;  // Move to the left
                end else begin
                    x_direction <= 1;  // Change direction to right
                end
            end
            
            // Vertical direction logic
            if (y_direction) begin
                if (v_start_position + y_offset + (box_height/2)< 1125) begin
                    y_offset <= y_offset + SPEED;  // Move down
                end else begin
                    y_direction <= 0;  // Change direction to up
                end
            end else begin
                if (y_offset > 0) begin
                    y_offset <= y_offset - SPEED;  // Move up
                end else begin
                    y_direction <= 1;  // Change direction to down
                end
            end
        end
        
        // Draw the rectangle
        if (is_in_rectangle) begin
            vid_d1 <= RECT_COLOR;
        end else begin
            vid_d1 <= BG_COLOR;
        end
        
        // Copy the fvht signal
        fvht_d1 <= fvht_i;
    end
end

// OUTPUT
assign fvht_o  = fvht_d1;
assign video_o = vid_d1;

endmodule