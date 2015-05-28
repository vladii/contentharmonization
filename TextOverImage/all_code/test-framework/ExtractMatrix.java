// Extract a binary matrix from an image and write it to a file.
import java.io.*;
import javax.imageio.*;
import java.awt.*;
import java.awt.image.*;

public class ExtractMatrix {
    public static int resizeFactor;
    
    public static BufferedImage resizeImage(BufferedImage originalImage){
        int type = originalImage.getType() == 0? BufferedImage.TYPE_INT_ARGB : originalImage.getType();
        
        BufferedImage resizedImage = new BufferedImage(resizeFactor, resizeFactor, type);
        Graphics2D g = resizedImage.createGraphics();
        g.drawImage(originalImage, 0, 0, resizeFactor, resizeFactor, null);
        g.dispose();
        
        return resizedImage;
    }

    public static void main(String[] args) {
        if (args.length < 2) {
            System.out.println("Usage: java ExtractMatrix image_path.png matrix_file [resize_factor]");
            return ;
        }
        
        String imagePath = args[0];
        String matrixOutput = args[1];
        
        // Open the image.
        BufferedImage image = null;
        try {
            image = ImageIO.read(new File(imagePath));
        } catch (IOException e) {
            System.out.println("Error: Image not found!");
            return ;
        }
        
        if (args.length > 2) {
            resizeFactor = Integer.parseInt(args[2]);
            
            image = resizeImage(image);
        }
        
        int height = image.getHeight();
        int width = image.getWidth();
        
        // Open file to write matrix.
        PrintWriter writer = null;
        try {
            writer = new PrintWriter(matrixOutput, "UTF-8");
        } catch (Exception e) {
            System.out.println("Error: Problems with output file!");
            return ;
        }
        
        writer.println(height + " " + width);   // Write number of lines/columns
        
        for (int i = 0; i < height; i++) {
            for (int j = 0; j < width; j++) {
                Color pixel = new Color(image.getRGB(i, j));
                
                if (pixel.getRed() == 255 && pixel.getGreen() == 255 && pixel.getBlue() == 255) {
                    writer.print(1);
                } else {
                    writer.print(0);
                }
                
                writer.print(" ");
            }
            
            writer.println();
        }
        
        writer.close();
    }
}