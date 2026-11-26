`timescale 1ns/1ps

// 確認は、各サイクルの真ん中 (negedge) で行う。
// 「サイクル t」は、start を受けた立ち上がりの直後を t=1 とする。
//   frame[0]=スタート(0)、frame[1]〜frame[8]=data[0]〜data[7]、frame[9]=ストップ(1)
//   サイクル t の tx の期待値は frame[(t-1)/B]、busy の期待値は 1 (t=1〜10*B)
module tb_uart_tx;
parameter B = 4;

reg        clk, rst_n, start;
reg  [7:0] data;
wire       tx, busy;
reg  [9:0] frame;
integer    ng, t, i;
reg        etx, trace;

uart_tx #(.BIT_CLKS(B)) dut(.clk(clk), .rst_n(rst_n), .start(start), .data(data), .tx(tx), .busy(busy));

always #5 clk = ~clk;

task check_cycle;
  input integer tt;
  begin
    etx = frame[(tt-1)/B];
    if (tx !== etx || busy !== 1'b1) begin
      ng = ng + 1;
      $display("NG t=%0d tx=%b(期待 %b) busy=%b(期待 1)", tt, tx, etx, busy);
    end
  end
endtask

task check_idle;
  input integer n;
  integer j;
  begin
    for (j = 0; j < n; j = j + 1) begin
      @(negedge clk);
      if (tx !== 1'b1 || busy !== 1'b0) begin
        ng = ng + 1;
        $display("NG 待機中 tx=%b busy=%b (期待 tx=1 busy=0)", tx, busy);
      end
    end
  end
endtask

// d を送る。intr_t が 0 でなければ、サイクル intr_t の間に start=1 を出して、無視されるか確かめる。
task send;
  input [7:0] d;
  input integer intr_t;
  integer tt;
  begin
    @(negedge clk); start = 1; data = d;
    @(posedge clk); #1 start = 0; data = ~d;     // 取り込んだあとは data を変える (保持しているか確かめる)
    frame = {1'b1, d, 1'b0};
    for (tt = 1; tt <= 10 * B; tt = tt + 1) begin
      @(negedge clk);
      check_cycle(tt);
      if (trace) begin $write("%b", tx); if (tt % B == 0) $write(" "); end
      if (tt == intr_t) begin start = 1; data = 8'hFF; end
      else begin start = 0; data = ~d; end
    end
    start = 0;
  end
endtask

initial begin
  clk = 0; rst_n = 0; start = 0; data = 0; ng = 0; trace = 0;
  #12 rst_n = 1;

  check_idle(5);

  // 例: data = 8'b10110010 を送る (下位から 0,1,0,0,1,1,0,1)
  $display("---- data=8'b10110010 を送る (B=%0d)。tx を 1サイクルずつ表示 ----", B);
  trace = 1; $write("tx: "); send(8'b10110010, 0); $display(""); trace = 0;
  check_idle(3);

  send(8'h00, 0);
  send(8'hFF, 0);                // 前の送信が終わった直後 (待機を挟まず) に次を送る
  check_idle(2);
  send(8'hA5, 3*B + 2);          // 送信中に start を出しても、無視される
  check_idle(2);

  // 非同期リセット: 送信中、クロックの立ち上がりを待たずに tx=1, busy=0 に戻るか
  @(negedge clk); start = 1; data = 8'h55;
  @(posedge clk); #1 start = 0;
  frame = {1'b1, 8'h55, 1'b0};
  for (t = 1; t <= 2*B + 1; t = t + 1) begin
    @(negedge clk);
    check_cycle(t);
  end
  #1 rst_n = 0;               // クロックは Low のまま。立ち上がりはまだ来ない
  #1 if (tx !== 1'b1 || busy !== 1'b0) begin
       ng = ng + 1;
       $display("NG 非同期リセット: tx=%b busy=%b (期待 tx=1 busy=0)", tx, busy);
     end
  #2 rst_n = 1;
  check_idle(3);
  send(8'h77, 0);              // リセット後も、また送れるか

  // ランダムなデータを 30 回
  for (i = 0; i < 30; i = i + 1) send($random, 0);
  check_idle(2);

  $display("UART送信: NG=%0d", ng);
  $finish;
end
endmodule
