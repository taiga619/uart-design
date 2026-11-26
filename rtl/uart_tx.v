`timescale 1ns/1ps

// ---- UART送信 (仕様は uart_spec.md) ----
//   rst_n=0 (非同期)  : tx=1, busy=0 にする。ほかのレジスタも 0 にしてよい
//
//   待機中 (busy=0) に start=1 のクロックの立ち上がりを受けたら:
//     data を内部のレジスタ (sh) に取り込む
//     busy=1 にする
//     tx=0 にする (スタートビット。この立ち上がりの「後」から tx=0)
//     cnt=0, k=0 にする
//
//   送信中 (busy=1) は、1ビットを BIT_CLKS クロックずつ出す:
//     cnt  : 0 から BIT_CLKS-1 まで数える。BIT_CLKS-1 の次の立ち上がりで 0 に戻る
//     k    : いま何ビット目か。0=スタート, 1〜8=data[0]〜data[7], 9=ストップ
//     cnt が BIT_CLKS-1 の立ち上がりで、次のビットに進む:
//        k が 0〜7 のとき : k を +1 して、tx に「次のビットの値」を入れる
//                          (次が data[0]〜data[7] なら sh[k]、
//                           次がストップ (k が 8 のとき) なら 1)
//        k が 9 のとき   : 送信終了。busy=0, tx=1
//   送信中の start は無視する。
//
//   ポートの tx と busy は reg で宣言してある。
//   内部で使うレジスタ (sh, cnt, k) は、ここで宣言する。
//   cnt は [15:0] 幅にしておけば、BIT_CLKS の大きさを気にしなくてよい。
module uart_tx #(
 parameter BIT_CLKS = 4
)(
 input        clk, rst_n,
 input        start,
 input  [7:0] data,
 output reg   tx,
 output reg   busy
);
reg [7:0] sh;
reg [15:0] cnt;
reg [3:0] k;

always @(posedge clk or negedge rst_n)
 if(!rst_n) begin 
  cnt <= 16'd0;
  sh <= 8'd0;
  k <= 4'd0;
  tx <= 1'd1;
  busy <= 1'd0;
 end
 else if(!busy) begin
  sh <= start ? data : 8'd0;
  busy <= start;
  tx <= ~start;
  k <= 4'd0;
 end
 else begin
  cnt <= (cnt >= BIT_CLKS - 1) ? 16'd0 : cnt + 16'd1;
  if(cnt == BIT_CLKS -1) begin 
   k <= k + 4'd1;
   tx <= (k <= 7) ? sh[k] : 1'd1;
   busy <= (k == 9) ? 1'd0 : 1'd1;
  end
 end 


endmodule
