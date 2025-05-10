#!/usr/bin/env node
var assert = require("assert"),
		fs = require("fs"),
Imgflipper = require("imgflipper");
 
cb = function (err, url) {
		console.log(url);
};
 
var imgflipper = new Imgflipper("qdzlug", "MemeMe3452");
imgflipper.generateMeme(61579, "one does not simply", process.argv[2] , cb);
