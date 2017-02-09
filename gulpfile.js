var gulp = require('gulp'),
    argv = require('yargs').argv,
    autoprefixer = require('gulp-autoprefixer'),
    browserify = require('browserify'),
    del = require('del'),
    fs = require('fs'),
    gulpFilter = require('gulp-filter'),
    gulpIf = require('gulp-if'),
    jshint = require('gulp-jshint'),
    livereload = require('gulp-livereload'),
    ngAnnotate = require('gulp-ng-annotate'),
    plumber = require('gulp-plumber'),
    sass = require('gulp-sass'),
    source = require('vinyl-source-stream'),
    sourcemaps = require('gulp-sourcemaps'),
    streamify = require('gulp-streamify'),
    uglify = require('gulp-uglify'),
    watch = require('gulp-watch'),
    webserver = require('gulp-webserver');

//erro handling
var onError = function (err) {  
  console.log(err.toString());
};

//JSHint configuration
var jsHintConfig = {
  loopfunc: true,
  predef: ['define','require'],
  devel: true,
  browser: true
};

var env = argv.env || argv.e || 'dev',
    shouldMinify = argv.minify,
    shouldWatch = argv.watch;

var buildTasks = ['scripts', 'sassy'];

if (shouldWatch) {
    buildTasks.push('initWatch');
}
 
gulp.task('watch:scripts', function() {
  watch(['src/js/**/*.js'], function(files) {
     gulp.src(['src/js/**/*.js'])
        .pipe(plumber({
            errorHandler: onError
          }))
        .pipe(jshint(jsHintConfig))
        .pipe(jshint.reporter('jshint-stylish'));
      gulp.start('scripts');
  });
});

gulp.task('watch:sass', function() {
  watch(['src/sass/**/*.scss'], function(files) {
    gulp.start('sassy');
  });
});

gulp.task('initWatch', function() {
	livereload.listen();
	gulp.start('watch');
});

gulp.task('watch', ['watch:scripts', 'watch:sass', 'scripts:vendor']);

gulp.task('clean:sass', function (cb) {
  del(['public/css/**/*'], cb)
});

gulp.task('clean:scripts', function (cb) {
  del(['public/js/**/*'], cb)
});

gulp.task('scripts', function() {
  var scripts = fs.readdirSync('./src/js').filter(function(n) {
        var shouldBuild = fs.statSync('./src/js/' + n).isFile() && n !== '.DS_Store';
        
        //don't rebuild vendor if you are working local and building on every file change
        if (shouldWatch && shouldBuild) {
          shouldBuild = n !== 'vendor.js';
        }
        return shouldBuild;

    }).map(function(n) {
        return browserify('./src/js/' + n)
        	.transform('babelify', {presets: ["es2015"]})
          .bundle()
          .pipe(source(n.replace('.js', '') + '.min.js'))
          .pipe(streamify(ngAnnotate()))
          .pipe(gulpIf(shouldMinify, streamify(uglify({mangle: false}))))
          .pipe(gulp.dest('./public/js'))
          .pipe(gulpIf(shouldWatch, livereload()));
    }); 
});

gulp.task('scripts:vendor', function() {
  return browserify('./src/js/vendor.js')
          .bundle()
          .pipe(source('vendor.min.js'))
          .pipe(streamify(ngAnnotate()))
          .pipe(gulpIf(shouldMinify, streamify(uglify({mangle: false}))))
          .pipe(gulp.dest('./public/js'));
});
 
gulp.task('sassy', function() {
	var filter = gulpFilter(['*.css', '!*.map']);

  gulp.src(['src/sass/**/*.scss'])
    .pipe(plumber({
      errorHandler: onError
    }))
    // .pipe(sourcemaps.init())
    .pipe(sass({
      outputStyle: 'compressed'
    }))
    // .pipe(sourcemaps.write('./'))
    // .pipe(filter)
    .pipe(autoprefixer({
          browsers: ['last 2 versions'],
          cascade: false
      }))
    // .pipe(filter.restore)
    .pipe(gulp.dest('./public/css'))
    .pipe(gulpIf(shouldWatch, livereload()));
});

gulp.task('build', buildTasks, function() {});