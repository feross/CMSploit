// String truncation code from Stack Overflow: http://goo.gl/kAq6w
String.prototype.trunc = function(n) {
  return this.substr(0,n-1)+(this.length>n?'...':'');
};