var express = require('express');
var multer  = require('multer');
var gm = require('gm');
var fs = require('fs');
var path = require('path');
var serveIndex = require('serve-index');
var serveStatic = require('serve-static');
var exec = require('child_process').exec;
var app = express();
var done = false;
var globalError = false;
var errorReason = '';

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

app.get('/api/photo/:baseFolder/:tempFolder/:imagename/:userText/:userTextDim', function(req, res) {
    var imagepath = req.params.baseFolder + '/' + req.params.tempFolder + '/' + req.params.imagename;
    var imagedir = imagepath.substr(0, imagepath.lastIndexOf('/') + 1);
        
    var pageContent = "";
    
    pageContent += "Multumesc din suflet pentru ca ai uploadat aceasta imagine! " +
        "Verifica folderul: " + "<a href=\"/" + imagedir + "\">" + imagedir +"</a>" + " pentru a vedea rezultatele. " +
        "Tot procesul dureaza in jur de 30 sec, insa imagini sunt afisate pe parcurs. <br />";
    pageContent += "In caz ca iti este lene sa verifici folderul de mai sus, mai jos vor fi listate imaginile care au fost create. <br />" +
        "De asemenea, imaginea finala (cu text) va fi afisata aici la sfarsit. Pagina isi face refresh automat o data la 5 secunde pana termina. <br />";
        
    // Traverse all files in the image folder.
    // Check if the final image was found.
    var finalImageFound = false;
    var finalImageName = '';
    var files = [];
        
    fs.readdirSync(imagedir).forEach(function(name) {
        var filePath = path.join(imagedir, name);
        var stat = fs.statSync(filePath);
                                               
        if (stat.isFile()) {
            var fileName = name;
            files.push(fileName);
                                     
            if (fileName.indexOf("text_") == 0) {
                // Yay, final image.
                finalImageFound = true;
                finalImageName = fileName;
            }
        }
    });
    
    if (finalImageFound == false) {
        if (globalError == true) {
            pageContent += '<b>An error has occured! Terminated! :-( Reason: ' + errorReason + '</b> <br />';
            globalError = false;
            errorReason = '';
        
        } else {
            // Refresh every 5 seconds.
            pageContent += '<meta http-equiv="refresh" content="5" />';
        }
    
    } else {
        pageContent += '<img src="/' + imagedir + '/' + finalImageName + '">Final image</img><br />';
    }
        
    // Add all files to the html.
    for (var i = 0; i < files.length; i++) {
        pageContent += files[i] + "<br />";
    }
        
    res.setHeader('Content-Type', 'text/html');
    res.send(pageContent);
});

app.post('/api/photo', function(req, res) {
    if (done == true) {
         console.log("Start request ...");
         
         var imagepath = req.files.userPhoto.path;
         var imagedir = imagepath.substr(0, imagepath.lastIndexOf('/') + 1);
         
         var newUrl = '/api/photo/' + imagepath + '/' + req.body.userText + '/' + req.body.userTextDim;
         
         // If the image has a big dimensions, scale it.
         var maxDim = 1024;
         
         gm(imagepath).size(function(err, value) {
            if (value.height > maxDim || value.width > maxDim) {
                // Resize if the image is too big.
                gm(imagepath).resize(maxDim, maxDim).write(imagepath, function (err) {
                        // Run the whole process.
                        var prefixpath = "../imageserver/";
                        imagepath = prefixpath + imagepath;
                        imagedir = prefixpath + imagedir;
                                                           
                        var pipeline_command = "cd ../all_code; octave -q --eval 'source spectral_residual.m; spectral_residual(\"" + imagepath + "\", \"" + req.body.userText + "\", \"OpenSans-Regular.ttf\", " + req.body.userTextDim + ", \"" + imagedir + "\")'";
                                                           
                        console.log(pipeline_command);
                                                           
                        exec(pipeline_command, function callback(error, stdout, stderr) {
                             console.log(stderr);
                            if (stderr != null) {
                               if (stderr.indexOf("SyntaxError: Unexpected token") >= 0) {
                                    globalError = true;
                                    errorReason = "Text contains spaces!";
                               } else if (stderr.indexOf("IMAX") >= 0) {
                                    globalError = true;
                                    errorReason = "Cannot find free spaces for this text dimension!";
                               }
                            }
                            console.log("All images were created!");
                        });
                                                           
                        // Set done to false to be able to perform other requests.
                        done = false;
                                                           
                        // Redirect.
                       res.redirect(newUrl);
                });
                            
            } else {
                    // Run the whole process.
                    var prefixpath = "../imageserver/";
                    imagepath = prefixpath + imagepath;
                    imagedir = prefixpath + imagedir;
                            
                    var pipeline_command = "cd ../all_code; octave -q --eval 'source spectral_residual.m; spectral_residual(\"" + imagepath + "\", \"" + req.body.userText + "\", \"OpenSans-Regular.ttf\", " + req.body.userTextDim + ", \"" + imagedir + "\")'";
                            
                    console.log(pipeline_command);
                            
                    exec(pipeline_command, function callback(error, stdout, stderr) {
                         if (stderr != null) {
                            if (stderr.indexOf("SyntaxError: Unexpected token") >= 0) {
                                globalError = true;
                                errorReason = "Text contains spaces!";
                            } else if (stderr.indexOf("IMAX") >= 0) {
                                globalError = true;
                                errorReason = "Cannot find free spaces for this text dimension!";
                            }
                         }
                         
                        console.log("All images were created!");
                    });
                            
                    // Set done to false to be able to perform other requests.
                    done = false;
                            
                    // Redirect.
                    res.redirect(newUrl);
            }
         });
    }
});

/*Run the server.*/
app.listen(6969, function(){
    console.log("Working on port 6969");
});