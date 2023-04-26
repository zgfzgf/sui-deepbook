# deepbook(match + swap)

**caballeros 研究员 zgf**
**diem(libra)(aptos) 源代码贡献者**

## 如果使用deepbook

参考order源代码，实现大部分功能。deepbook官方提供部署包，没有提供源代码。

**命令如下:**

export Erc20_Package=0x583ed29fb450d341fcb07d2cf79a7901f1b4cfdde246a6bd0a0890828b8190de

export Apple_Treasury=0xd3805b339d5ab83856acabd4fd9d0f196aff44ede580aab0782baaee56c31eaa

export Dai_Treasury=0xa27363ef6d50741919217a06cde7f308714b88ec2ff9f132eb93235e418a8cfe

sui client call --gas-budget 3000000 --package $Erc20_Package --module apple --function mint --args $Apple_Treasury 10000000000000

sui client call --gas-budget 3000000 --package $Erc20_Package --module dai   --function mint --args $Dai_Treasury   100000000000000

export Order_Package=0x6d5688415304e4727d256d9ba9434019600913b14379758ec8edc0013a1449d2

export Type_Apple=0x583ed29fb450d341fcb07d2cf79a7901f1b4cfdde246a6bd0a0890828b8190de::**apple**::APPLE

export Type_Dai=0x583ed29fb450d341fcb07d2cf79a7901f1b4cfdde246a6bd0a0890828b8190de::dai::DAI

export Create_Fee=0x938b7b0d628801efab9f9f53bac10d94f295290a97aaaafe4c1b4ba55b75ecfb

sui client call --gas-budget 300000000 --package $Order_Package --module order --function create --type-args $Type_Apple $Type_Dai --args 100000000 100000000 $Create_Fee

sui client call --gas-budget 3000000 --package $Order_Package --module order --function create_account

export Apple_Coin=0xd43459f0b3bfeb6fde42718107fa7e9780c38eb263cac83e751b0b3e8e928aa7

export Apple_Cap=0xdb2853ae60162de8d114d8ea1c963c9d581d897e789af2f5e93d492ea742e5e4

sui client call --gas-budget 3000000 --package $Order_Package --module order --function deposit_base  --type-args $Type_Apple $Type_Dai --args $Pool $Apple_Coin  $Apple_Cap

export Pool=0x9206b3cdd4582aa6e216577263a540dfb234fceb0dd23ac123160f2a828b130b
sui client call --gas-budget 3000000 --package $Order_Package --module order --function withdraw_base --type-args $Type_Apple $Type_Dai --args $Pool 1000000000000  $Apple_Cap

sui client call --gas-budget 3000000 --package $Order_Package --module order --function place_limit_order --type-args $Type_Apple $Type_Dai --args $Pool 10000000000 1000000000000 false 1745424000000 0 0x6 $Apple_Cap

以上命令供参考，以后会进一步完善，特别感谢**Chainbase**提供测试币，以后会部署到测试网上面，供大家使用，deepbook现在的代码还需要完善，特别Event该发没有发。
