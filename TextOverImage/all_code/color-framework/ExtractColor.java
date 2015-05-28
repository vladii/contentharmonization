import java.io.*;
import javax.imageio.*;
import java.awt.*;
import java.awt.image.*;
import java.util.*;

public class ExtractColor {
    public static final float CLOSE_THRESHOLD = (float) 0.01;
    
    public static int resizeFactor;
    public static Map<Float, Integer> val = new HashMap<Float, Integer>();
    public static Map<Float, Integer> valAux = new HashMap<Float, Integer>();
    public static java.util.List<Float> allPossibleSolutions;
    
    /*
     * Resize an Image with resizeFactor and return the new resized image.
     */
    public static BufferedImage resizeImage(BufferedImage originalImage){
        int type = originalImage.getType() == 0? BufferedImage.TYPE_INT_ARGB : originalImage.getType();
        
        BufferedImage resizedImage = new BufferedImage(resizeFactor, resizeFactor, type);
        Graphics2D g = resizedImage.createGraphics();
        g.drawImage(originalImage, 0, 0, resizeFactor, resizeFactor, null);
        g.dispose();
        
        return resizedImage;
    }

    public static void main(String[] args) {
        if (args.length < 6) {
            System.out.println("Usage: java ExtractColor image_path.png write_text file.ttf font_size X Y [resize_factor]");
            return ;
        }
        
        Random random = new Random();
        
        String imagePath = args[0];
        String textToWrite = args[1];
        String ttfFilePath = args[2];
        String fontSize = args[3];
        
        int upperX = Integer.parseInt(args[4]);
        int upperY = Integer.parseInt(args[5]);
        
        // Run harf-buzz
        String currPath = System.getProperty("user.dir") + "/";
        String command = "hb-view --output-file=WrittenTextTmp.png --output-format=png --margin=10 --font-size=" + fontSize +
                          " " + ttfFilePath + " " + textToWrite;
        
        try {
            Runtime r = Runtime.getRuntime();
            Process p = r.exec(command);
            p.waitFor();
            
            /**
            while (p.getErrorStream().available() > 0) {
                System.out.print((char) p.getErrorStream().read());
            }
            **/
            
        } catch (Exception e) {
            System.out.println("Error: Cannot run harf-buzz process!");
            return ;
        }
        
        // Open the image.
        BufferedImage image = null;
        try {
            image = ImageIO.read(new File(imagePath));
        } catch (IOException e) {
            System.out.println("Error: Image not found!");
            return ;
        }
        
        if (args.length > 6) {
            resizeFactor = Integer.parseInt(args[6]);
            
            image = resizeImage(image);
        }
        
        int height = image.getHeight();
        int width = image.getWidth();
        
        // Decide how big is the rectangle. Open text image file.
        BufferedImage textImage = null;
        try {
            textImage = ImageIO.read(new File("WrittenTextTmp.png"));
        } catch (IOException e) {
            System.out.println("Error: Text image file not found! Check harf-buzz command!");
            return ;
        }
        
        int lowerY = upperY + textImage.getHeight() - 1;
        int lowerX = upperX + textImage.getWidth() - 1;
        
        // Compute average H, S and B for the rectangle.
        float averageH = (float) 0.0;
        float averageS = (float) 0.0;
        float averageB = (float) 0.0;

        for (int i = upperX; i <= lowerX; i++) {
            for (int j = upperY; j <= lowerY; j++) {
                Color pixel = new Color(image.getRGB(i, j));
                float[] hsb = Color.RGBtoHSB(pixel.getRed(), pixel.getGreen(), pixel.getBlue(), null);
                
                averageH += hsb[0];
                averageS += hsb[1];
                averageB += hsb[2];
            }
        }
        
        averageH /= (float) (lowerY - upperY + 1) * (lowerX - upperX + 1);
        averageS /= (float) (lowerY - upperY + 1) * (lowerX - upperX + 1);
        averageB /= (float) (lowerY - upperY + 1) * (lowerX - upperX + 1);
        
        
        // Solve problem on each dimension (H, S, B) separately.
        float solH = 0, solS = 0, solB = 0;
        
        for (int part = 0; part < 3; part++) {
            
            // Initialize data structures.
            val.clear();
            valAux.clear();
            allPossibleSolutions = new ArrayList<>();
            
            // Traverse the rectangle.
            for (int i = upperX; i <= lowerX; i++) {
                for (int j = upperY; j <= lowerY; j++) {
                    Color pixel = new Color(image.getRGB(i, j));
                    
                    float[] hsb = Color.RGBtoHSB(pixel.getRed(), pixel.getGreen(), pixel.getBlue(), null);
                    float pixelValue = hsb[part];
                
                    if (valAux.containsKey(pixelValue)) {
                        int count = valAux.get(pixelValue);
                        valAux.put(pixelValue, count + 1);
                    } else {
                        valAux.put(pixelValue, 1);
                    }
                }
            }
            
            // Get all keys and merge them.
            Set<Float> keySet = valAux.keySet();
            java.util.List<Float> keyList = new ArrayList<>(keySet);
            
            Collections.sort(keyList);
            if (keyList.get(0) != (float) 0.0) {
                keyList.add(0, (float)0.0);
                valAux.put((float) 0.0, 0);
            }
            
            // Try to merge all very closed values.
            float start = keyList.get(0);
            int currCount = valAux.get(start);
            for (int i = 1; i < keyList.size(); i++) {
                float currX = keyList.get(i);
                
                if (currX - start > CLOSE_THRESHOLD) {
                    val.put(start, currCount);
                    
                    start = currX;
                    currCount = valAux.get(currX);
                } else {
                    currCount += valAux.get(currX);
                }
            }
            
            val.put(start, currCount);
            
            // Obtain new list of keys (merged) and find solutions.
            keySet = val.keySet();
            keyList = new ArrayList<>(keySet);
            
            Collections.sort(keyList);
            
            // Solve and find all possible solutions.
            float prevMinSol = (float) 0.0;
            int previous = 0;
            for (int i = 1; i < keyList.size(); i++) {
                int valCurr = 0;
                float xCurr = keyList.get(i);
                if (val.containsKey(keyList.get(i))) {
                    valCurr = val.get(keyList.get(i));
                }
                
                int valPrevious = 0;
                float xPrevious = keyList.get(previous);
                if (val.containsKey(keyList.get(previous))) {
                    valPrevious = val.get(keyList.get(previous));
                }

                float xSol = (float) (xPrevious * valCurr + xCurr * valPrevious) / (float) (valPrevious + valCurr);
                allPossibleSolutions.add(xSol);
                
                // System.out.println("[(" + xPrevious + ", " + valPrevious + "), (" + xCurr + ", " + valCurr + ")] -> " + xSol);
                
                // First approach: Choose that element with the biggest distance to its surrounding margins.
                if (Math.min(xSol - xPrevious, xCurr - xSol) > prevMinSol) {
                    prevMinSol = Math.min(xSol - xPrevious, xCurr - xSol);
                    
                    switch (part) {
                        case 0:
                            solH = xSol;
                            break;
                            
                        case 1:
                            solS = xSol;
                            break;
                            
                        case 2:
                            solB = xSol;
                            break;
                            
                        default:
                            break;
                    }
                }
                    
                previous = i;
            }
            
            if (keyList.get(previous) != 1.0 && val.containsKey(keyList.get(previous)) && val.get(keyList.get(previous)) > 0) {
                float xPrevious = keyList.get(previous);
                
                float xSol = (float) (xPrevious * 0 + 1.0 * val.get(xPrevious)) / (val.get(xPrevious) + 0);
                allPossibleSolutions.add(xSol);
                
                if (Math.min(xSol - xPrevious, (float) 1.0 - xSol) > prevMinSol) {
                    prevMinSol = Math.min(xSol - xPrevious, (float) 1.0 - xSol);
                    
                    switch (part) {
                        case 0:
                            solH = xSol;
                            break;
                            
                        case 1:
                            solS = xSol;
                            break;
                            
                        case 2:
                            solB = xSol;
                            break;
                            
                        default:
                            break;
                    }
                }
            }
            
            // Choose the best solution among all possible solutions.
            
            // Second approach: Random :-)
            /**
            switch (part) {
                case 0:
                    solH = allPossibleSolutions.get(random.nextInt(allPossibleSolutions.size()));
                    break;
                    
                case 1:
                    solS = allPossibleSolutions.get(random.nextInt(allPossibleSolutions.size()));
                    break;
                    
                case 2:
                    solB = allPossibleSolutions.get(random.nextInt(allPossibleSolutions.size()));
                    break;
                    
                default:
                    break;
            }
            **/
        }
        
        System.out.println("Solution: ");
        System.out.println(solH + " " + solS + " " + solB);
        
        System.out.println("Average values: ");
        System.out.println(averageH + " " + averageS + " " + averageB);
        
        // Write text on the original image.
        for (int i = upperX; i <= lowerX; i++) {
            for (int j = upperY; j <= lowerY; j++) {
                int xText = i - upperX;
                int yText = j - upperY;
                
                Color pixelText = new Color(textImage.getRGB(xText, yText));
                Color toWrite = Color.getHSBColor(solH, solS, solB);
                
                if (pixelText.getRed() > 0 && pixelText.getGreen() > 0 && pixelText.getBlue() > 0) {
                    continue;
                }

                image.setRGB(i, j, (new Color(toWrite.getRed(), toWrite.getGreen(), toWrite.getBlue())).getRGB());
            }
        }
        
        // Output image.
        try {
            ImageIO.write(image, "png", new File("output.png"));
        } catch (Exception e) {
            System.out.println("Error: when writting image to the output file!");
            return ;
        }
    }
}