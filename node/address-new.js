#!/usr/bin/env node

var program = require('commander');

program.parse(process.argv);
var address = program.args[0];

var flag = address.startsWith('NEW')

var base58check = require('base58check');
if(flag) {
	var ethAddress = base58check.decode(address.slice(3), 'hex').data.slice(4)
	console.log('eth address is:0x', ethAddress)
} else {
	if(address.startsWith('0x')){
		address = address.slice(2)
	}
	var chainID = 16888;
	var PREFIX = 'NEW';
	var data = chainID.toString(16).slice(-8)+address;
	var newAddress = PREFIX + base58check.encode(data)
	console.log('new address is', newAddress)
}


