// Run this script: node script-3-3D.js image_path=\"Image_1.bmp\" text=\"VladIonescu\" font=\"OpenSans-Regular.ttf\" font_size=50 pos_x=250 pos_y=250
// Note: it requires node.js and conventjs installed (npm install convnetjs).

var fs = require('fs');
var exec = require('child_process').exec;
var google = require('googleapis');
var prediction = google.prediction('v1.6');

var PREDICTIONS_ENABLED = true;

if (!PREDICTIONS_ENABLED) {
    console.log("Error: predictions are disabled! Set PREDICTIONS_ENABLED flag to true.");
    
} else {
    // Evaluate arguments.
    var image_path;
    var text;
    var font;
    var font_size;
    var pos_x;
    var pos_y;
    var H1, S1, B1, H2, S2, B2, H3, S3, B3;
    var predicted_H, predicted_S, predicted_B;

    process.argv.forEach(function (val, index, array) {
        if (index > 1) {
            eval(val);
        }
    });
    
    // Run Octave script to obtain the H, S and B of three dominant colors.
    var dominant_colors_process = 'octave -q --eval "dominant_color ' + image_path + ' ' + text + ' ' + font + ' ' + font_size + ' ' + pos_x + ' ' + pos_y + '" 2> /dev/null';
    exec(dominant_colors_process, function callback(error, stdout, stderr) {
         var words = stdout.split(/\n|\r| /);
         H1 = 360 * words[0];
         S1 = 100 * words[1];
         B1 = 100 * words[2];
         H2 = 360 * words[3];
         S2 = 100 * words[4];
         B2 = 100 * words[5];
         H3 = 360 * words[6];
         S3 = 100 * words[7];
         B3 = 100 * words[8];
         
         console.log(H1 + "," + S1 + "," + B1 + "," + H2 + "," + S2 + "," + B2 + "," + H3 + "," + S3 + "," + B3);
         
         var authClient = new google.auth.JWT(
                        'Your google api key here!',
                        // use the PEM file we generated from the downloaded key
                        "googlekey.pem",
                        // Contents of private_key.pem if you want to load the pem file yourself
                        // (do not use the path parameter above if using this param)
                        // Scopes can be specified either as an array or as a single, space-delimited string
                        null,
                        ['https://www.googleapis.com/auth/prediction']
                        // User to impersonate (leave empty if no impersonation needed)
        );
         
        authClient.authorize(function(err, tokens) {
                                if (err) {
                                    console.log(err);
                                    return;
                              
                                } else {
                                    // console.log(tokens);
                                    prediction.trainedmodels.predict({
                                            auth: authClient,
                                            project: '766014067287',    // Your project here!!!
                                            id: 'complementarycolor',
                                            resource: {
                                                input: {
                                                    csvInstance: [H1, S1, B1, H2, S2, B2, H3, S3, B3]
                                                }
                                            }
                                    }, function(err, result) {
                                            if (result.outputLabel == "W") {
                                                predicted_H = 0;
                                                predicted_S = 0;
                                                predicted_B = 1;
                                                                     
                                            } else if (result.outputLabel == "B") {
                                                predicted_H = 0;
                                                predicted_S = 0;
                                                predicted_B = 0;
                                            }
                                                                     
                                            // console.log('Result predict: ' + (err ? err.message : JSON.stringify(result)));
                                                                     
                                            // Call the script which put the text onto the image.
                                            var write_text_process = 'octave -q --eval "write_color_image ' + image_path + ' ' + text + ' ' + font + ' ' + font_size + ' ' + pos_x + ' ' + pos_y + ' ' + predicted_H + ' ' + predicted_S + ' ' + predicted_B + '" 2> /dev/null';
                                             exec(write_text_process, function callback(error, stdout, stderr) {
                                            });
                                    });
                                }
         });
    });
}
