# deepbook(match + swap)

**caballeros 研究员 zgf**
**diem(libra)(aptos) 源代码贡献者**

## 如果使用deepbook

参考order源代码，实现大部分功能。deepbook官方提供部署包，没有提供源代码。

**命令如下:**

cd erc20  部署erc20合约

sui client publish ./ --gas-budget 30000000

export Erc20_Package=0x5394a83121c9cb1edef846088c1d18bd57b01fe4eabc08a0e3c6559f19aa8b65

export Apple_Treasury=0x3dfe8e9d536c7a6779d87e2d056a582334d5a461b5b818ddd93218d3a2cdf0f2

export Dai_Treasury=0x3fced7d184703a6ef9dcc4dbce673e3df5d3aa3492fec70327d199cc1a21e473


cd match  部署match合约

sui client publish ./ --gas-budget 30000000

export Order_Package=0x21d03cda76ff645c715b285c56a1a0d4cbf8e2346de4e94f424173a3db75487d

export Type_Apple=0x5394a83121c9cb1edef846088c1d18bd57b01fe4eabc08a0e3c6559f19aa8b65::**apple**::APPLE

export Type_Dai=0x5394a83121c9cb1edef846088c1d18bd57b01fe4eabc08a0e3c6559f19aa8b65::dai::DAI

export Create_Fee=0xc6ccc96f22f1090ca45e0dbcd01325d8ec925ebd12f29dcb99753910a4147a58

创建Apple/Dai交易对

sui client call --gas-budget 300000000 --package $Order_Package --module order --function create --type-args $Type_Apple $Type_Dai --args 100000000 100000000 $Create_Fee

export Pool=0x5d3cce4e2d288b65cd93265a9e5c4ff03e387fe34dcbccc120c68d7f949ab3df

mint Apple与Dai币 (可以从下面开始测试)

sui client call --gas-budget 3000000 --package $Erc20_Package --module apple --function mint --args $Apple_Treasury 10000000000000

sui client call --gas-budget 3000000 --package $Order_Package --module order --function create_account

export Apple_Coin=0x2efb8c40e1efcc83e2f84631e8c1b91baf7c24628151e8e70f691c7cfadaee67



export Apple_Cap=0x57636c78f0472b57bf774148a7ace305412a39f5f6f995ee4ca17e24c982ed3f

充值

sui client call --gas-budget 3000000 --package $Order_Package --module order --function deposit_base  --type-args $Type_Apple $Type_Dai --args $Pool $Apple_Coin  $Apple_Cap

提现(提部分)

sui client call --gas-budget 3000000 --package $Order_Package --module order --function withdraw_base --type-args $Type_Apple $Type_Dai --args $Pool 1000000000000  $Apple_Cap

挂单

sui client call --gas-budget 300000000 --package $Order_Package --module order --function place_limit_order --type-args $Type_Apple $Type_Dai --args $Pool 10000000000 1000000000000 false 1745424000000 0 0x6 $Apple_Cap

市场价成交

sui client call --gas-budget 3000000 --package $Erc20_Package --module apple --function mint --args $Apple_Treasury 0

sui client call --gas-budget 3000000 --package $Erc20_Package --module dai   --function mint --args $Dai_Treasury   100000000000000

export Apple_market=0x531812ff0d01a6eca4fe3921335be23745bd13ddbe557b15cf83307bc78f786a

export Dai_Coin=0xba11052db56d3a5eebd4ce562b1faef64e5d11229fa6127c319c7a02b643ac21

sui client call --gas-budget 600000000 --package $Order_Package --module order --function place_market_order --type-args $Type_Apple $Type_Dai --args $Pool 200000000000  true  $Apple_market $Dai_Coin 0x6

应该成功，但是返回如下：
Expected argument of type 0x2::coin::Coin<T0>, but found type 0x2::coin::Coin<0x5394a83121c9cb1edef846088c1d18bd57b01fe4eabc08a0e3c6559f19aa8b65::dai::DAI>

视图函数查询数数，参考[sui查询](https://learn-web3.gitbook.io/sui/sui-cha-xun-lian-shang-shu-ju)

以上命令供参考，特别感谢**Chainbase**提供测试币，供大家使用，deepbook现在的代码还需要完善，特别Event该发没有发。


