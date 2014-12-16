require('coffee-script/register');
module.exports = require('./lib/compiler.coffee');
if (require.main == module) {
    module.exports.main();
}
