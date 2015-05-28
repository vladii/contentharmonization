var express = require('express');
var multer  = require('multer');
var fs = require('fs');
var path = require('path');
var serveIndex = require('serve-index');
var serveStatic = require('serve-static');
var exec = require('child_process').exec;
var app = express();
var done = false;

app.use(multer({dest: './uploads/',
    rename: function (fieldname, filename) {
        return filename;
    },
               
    changeDest: function(dest, req, res) {
        var newdest = dest + '/' + Math.random().toString(36).replace(/[^a-z]+/g, '').substr(0, 10);
               
        var stat = null;
               
        try {
            stat = fs.statSync(newdest);
        } catch(err) {
            fs.mkdirSync(newdest);
        }
               
        return newdest;
    },
               
    onFileUploadStart: function (file) {
    },
               
    onFileUploadComplete: function (file) {
        done = true;
    }
}));

app.use('/uploads', serveIndex('uploads', {'icons': true}));
app.use('/uploads', express.static(__dirname + '/uploads'));

app.get('/', function(req, res) {
    res.sendfile("index.html");
});

app.post('/api/photo', function(req, res) {
    if(done == true) {
         console.log("Start request ...");
         
         var imagepath = req.files.userPhoto.path;
         var imagedir = imagepath.substr(0, imagepath.lastIndexOf('/') + 1);
         
         res.end("Multumesc din suflet pentru ca ai uploadat aceasta imagine! \n" +
                 "Verifica folderul: " + imagedir + " pentru a vedea rezultatele. \n" +
                 "Tot procesul dureaza in jur de 30 sec, insa imagini sunt afisate pe parcurs.");
         
         done = false;
         
         console.log(req.files);
         console.log(req.body);
         
         // Run the whole process.
         var prefixpath = "../imageserver/";
         imagepath = prefixpath + imagepath;
         imagedir = prefixpath + imagedir;
         
         var pipeline_command = "cd ../all_code; octave -q --eval 'source spectral_residual.m; spectral_residual(\"" + imagepath + "\", " + req.body.userViewHeight + ", " + req.body.userViewWidth + ", \"" + imagedir + "\")'";
         
         console.log(pipeline_command);
         
         exec(pipeline_command, function callback(error, stdout, stderr) {
              console.log("All images were created!");
         });
    }
});

/*Run the server.*/
app.listen(6969, function(){
    console.log("Working on port 6969");
});