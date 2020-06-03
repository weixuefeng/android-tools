#!/usr/bin/env node

var program = require('commander');
var base58check = require('base58check');

program.parse(process.argv);
console.log(program.args)
var address = program.args[0];
var chainId = program.args[1];

var isNewAddress = address.startsWith('NEW');

if(isNewAddress) {
	// convert new to hex address
	var ethAddress = newAddress2HexAddress(address);
	console.log('hex address is:', ethAddress);
} else {
	// convert hex address to new address
	console.log(chainId)
	if(chainId == undefined || chainId == "") {
		console.log("not found chain id, default 1002");
		chainId = "1002";
	}
	chainId = parseInt(chainId);
	var newAddress = hexAddress2NewAddress(address, chainId);
	console.log('new address is', newAddress);
}

function hexAddress2NewAddress(hexAddress, chainId) {
    if(hexAddress.startsWith("0x")) {
        hexAddress = hexAddress.slice(2);
    }
    var PREFIX = "NEW";
    var data = chainId.toString(16).slice(-8) + hexAddress;
    if(data.length % 2 != 0) {
        data = "0" + data;
    }
    return PREFIX + base58check.encode(data);
}

function newAddress2HexAddress(newAddress) {
    if(typeof(newAddress) == "string" && newAddress.startsWith("NEW")) {
        return "0x" + base58check.decode(newAddress.slice(3), "hex").data.slice(4);
    } else {
        return newAddress;
    }
}