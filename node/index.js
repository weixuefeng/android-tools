const newchainWeb3 = require("newchain-web3");
const newchainAccount = require('newchain-web3-accounts');

const account = new newchainAccount.Accounts(DevRpc);
function test() { 
    var priv = '0xe4dc3fddabf68b36aa61af08e0e0f8c06801e262faec95abf2c67c309ae5d42d';
    var privBuffer = Buffer.from(priv.replace("0x",""), 'hex');
    const account = new newchainAccount.Accounts(DevRpc);

    var address = account.privateKeyToAccount(priv).address;
    console.log("address:" + address);

 }