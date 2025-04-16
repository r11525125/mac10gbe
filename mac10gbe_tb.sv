`timescale 1ps/1ps

module mac10gbe_tb;

// Clock and reset signals
reg mac_reset_n, init_rst_n, mac10gbe_clk, init_clk;

// AXI-Stream Input Interface (TX side)
reg [63:0] tx_axis_mac_tdata;
reg tx_axis_mac_tvalid, tx_axis_mac_tlast;
reg [7:0] tx_axis_mac_tkeep;
reg tx_axis_mac_tuser;

// AXI-Stream Output Interface (RX side)
wire [63:0] rx_axis_mac_tdata;
wire rx_axis_mac_tvalid, rx_axis_mac_tlast;
wire [7:0] rx_axis_mac_tkeep;
wire rx_axis_mac_tuser;
wire tx_axis_mac_tready;

// XGMII Interface
reg [63:0] XGMII_RXD;
reg [7:0]  XGMII_RXC;
wire [63:0] XGMII_TXD;
wire [7:0]  XGMII_TXC;

// Dummy PHY Status Signals
wire PMA_XCVR_PLLCLK_EN;
wire [3:0] PMA_XCVR_POWER_STATE_REQ;
wire phy_init_done;
wire tx_pause_busy;

// Dummy Statistics Signals
wire [31:0] cnt_tx_frame_transmitted_good;
wire [31:0] cnt_tx_frame_pause_mac_ctrl;
wire [31:0] cnt_tx_frame_error_txfifo_overflow;
wire [31:0] cnt_tx_frame_is_fe;
wire [31:0] cnt_rx_frame_received_good;
wire [31:0] cnt_rx_frame_error_fcs;
wire [31:0] cnt_rx_frame_pause_mac_ctrl;
wire [31:0] cnt_rx_frame_errors;
wire [31:0] cnt_rx_frame_received_total;
wire [31:0] cnt_rx_frame_undersized;
wire [31:0] cnt_rx_frame_oversized;
wire [31:0] cnt_rx_frame_mismatched_length;
wire [31:0] cnt_rx_frame_filtered_by_address;
wire [13:0] rpt_rx_frame_length;

// DUT (Device Under Test) Instantiation
mac10gbe dut (
    .mac_reset_n(mac_reset_n),
    .mac10gbe_clk(mac10gbe_clk),
    .init_clk(init_clk),
    .init_rst_n(init_rst_n),

    // PHY Dummy Signals (fixed values for testing)
    .PMA_CMN_READY(1'b1),
    .PMA_XCVR_PLLCLK_EN_ACK(1'b1),
    .PMA_XCVR_POWER_STATE_ACK(4'hF),
    .PMA_RX_SIGNAL_DETECT(1'b1),
    .PMA_XCVR_PLLCLK_EN(PMA_XCVR_PLLCLK_EN),
    .PMA_XCVR_POWER_STATE_REQ(PMA_XCVR_POWER_STATE_REQ),
    .phy_init_done(phy_init_done),

    // AXI-Stream TX Interface
    .tx_axis_mac_tdata(tx_axis_mac_tdata),
    .tx_axis_mac_tvalid(tx_axis_mac_tvalid),
    .tx_axis_mac_tlast(tx_axis_mac_tlast),
    .tx_axis_mac_tkeep(tx_axis_mac_tkeep),
    .tx_axis_mac_tuser(tx_axis_mac_tuser),
    .tx_axis_mac_tready(tx_axis_mac_tready),

    // AXI-Stream RX Interface
    .rx_axis_mac_tdata(rx_axis_mac_tdata),
    .rx_axis_mac_tvalid(rx_axis_mac_tvalid),
    .rx_axis_mac_tlast(rx_axis_mac_tlast),
    .rx_axis_mac_tkeep(rx_axis_mac_tkeep),
    .rx_axis_mac_tuser(rx_axis_mac_tuser),

    // Pause & Filtering Settings
    .rx_pause_ignore(1'b0),
    .tx_pause_gen(1'b0),
    .tx_pause_busy(tx_pause_busy),
    .tx_pause_quant(16'd0),
    .rx_address_filtering_mask(48'd0),

    // Counter Reset and Statistics Outputs
    .cnt_rst_n(1'b1),
    .cnt_tx_frame_transmitted_good(cnt_tx_frame_transmitted_good),
    .cnt_tx_frame_pause_mac_ctrl(cnt_tx_frame_pause_mac_ctrl),
    .cnt_tx_frame_error_txfifo_overflow(cnt_tx_frame_error_txfifo_overflow),
    .cnt_tx_frame_is_fe(cnt_tx_frame_is_fe),
    .cnt_rx_frame_received_good(cnt_rx_frame_received_good),
    .cnt_rx_frame_error_fcs(cnt_rx_frame_error_fcs),
    .cnt_rx_frame_pause_mac_ctrl(cnt_rx_frame_pause_mac_ctrl),
    .cnt_rx_frame_errors(cnt_rx_frame_errors),
    .cnt_rx_frame_received_total(cnt_rx_frame_received_total),
    .cnt_rx_frame_undersized(cnt_rx_frame_undersized),
    .cnt_rx_frame_oversized(cnt_rx_frame_oversized),
    .cnt_rx_frame_mismatched_length(cnt_rx_frame_mismatched_length),
    .cnt_rx_frame_filtered_by_address(cnt_rx_frame_filtered_by_address),

    // XGMII Interface
    .XGMII_TXD(XGMII_TXD),
    .XGMII_TXC(XGMII_TXC),
    .XGMII_RXD(XGMII_RXD),
    .XGMII_RXC(XGMII_RXC),

    // Frame Length Reporting
    .rpt_rx_frame_length(rpt_rx_frame_length)
);

// Clock Generation (156.25 MHz for 10G Ethernet, period=6400ps)
initial mac10gbe_clk = 0;
always #3200 mac10gbe_clk = ~mac10gbe_clk; 

// Initialization Clock Generation (100 MHz, period=10000ps)
initial init_clk = 0;
always #5000 init_clk = ~init_clk; 

// Reset Sequence
initial begin
    mac_reset_n = 0;
    init_rst_n = 0;
    #20000; // Wait 20ns
    mac_reset_n = 1;
    init_rst_n = 1;
end

// Initial AXI-Stream TX Setup and Sending One Ethernet Frame
initial begin
    tx_axis_mac_tvalid = 0;
    tx_axis_mac_tdata  = 0;
    tx_axis_mac_tkeep  = 8'hFF;
    tx_axis_mac_tlast  = 0;
    tx_axis_mac_tuser  = 0;
    XGMII_RXD = 0;
    XGMII_RXC = 0;
    #25000; // Wait for reset completion

    // Send a standard Ethernet Frame
    @(posedge mac10gbe_clk);
    tx_axis_mac_tvalid = 1;
    tx_axis_mac_tdata = 64'hFFFFFFFFFFFF1122; // Destination and Source MAC (part)
    @(posedge mac10gbe_clk);
    tx_axis_mac_tdata = 64'h3344556608000102; // Source MAC (remaining), Ethertype, Payload
    @(posedge mac10gbe_clk);
    tx_axis_mac_tdata = 64'h030405060708090A; // Payload
    @(posedge mac10gbe_clk);
    tx_axis_mac_tdata = 64'h0B0C0D0E0F101112; // Payload
    @(posedge mac10gbe_clk);
    tx_axis_mac_tdata = 64'h131415161718191A; // Payload
    tx_axis_mac_tlast = 1;                    // End of Frame
    @(posedge mac10gbe_clk);
    tx_axis_mac_tvalid = 0;                   // Frame transmission done

    // Observe for a period
    #50000;
    $finish;
end

endmodule