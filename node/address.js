#!/usr/bin/env node

var program = require('commander');

program
	.version('1.0.0')
	.usage('<command> [options]')
	.command('new', 'eth')
	.parse(process.argv);
