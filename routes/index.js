var express = require('express');
var router = express.Router();

router.get('/', function(req, res, next) {
  res.render('index', { title: 'Mods' });
});

router.get('/mods', function(req, res, next) {
  res.download('/var/www/admin/public/files/mods.zip', 'mods.zip');
});

module.exports = router;
