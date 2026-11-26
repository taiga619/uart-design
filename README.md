# uart-design
UART回路のGithub環境構築

# フォルダ構成

```
uart-design
|-Makefile #共通コマンド集 
|-docs 
|   |_spec
|      |-uart_spec.md #本回路の仕様書
|-rtl
|   |-uart_tx.v #RTL
|-scripts
|   |-.gitkeep #
|-tb
    |-tb_uart_tx.v #テストベンチ
```

# 必要な道具
- WSL (Ubuntu):以下の道具を動かすLinux環境
- make:Makefileに書かれた手順を実行する
- Icarus Verilog (iverilog、vvp):Verilogのシミュレータ

# 使い方
WSLで `uart-design` に移動してから実行する。
以下が検証の流れ。`NG=0`なら合格。

```
make sim
```

生成物の削除は以下。

```
make clean
```