import java.awt.Color;
import java.awt.GridLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.util.Random;

import javax.swing.JButton;
import javax.swing.JColorChooser;
import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JTextPane;


public class AppMainScreen extends JFrame {
	private int nrColors;
	private Random random;
	private BufferedWriter writer;
	
	private JPanel colorPanels[];
	private JTextPane textOnPanel[];
	private JPanel complColorPanel;
	private JButton refreshButton;
	private JButton submitButton;
	
	// Class for complementary color panel mouse event.
	class JPanelMouseListener implements MouseListener {

		@Override
		public void mouseClicked(MouseEvent e) {
			Color c = JColorChooser.showDialog(null, "Choose the complementary Color",
								complColorPanel.getBackground());
			if (c != null) {
				complColorPanel.setBackground(c);
				
				for (int i = 0; i < nrColors; i++) {
					textOnPanel[i].setForeground(c);
				}
			}
			
		}

		@Override
		public void mousePressed(MouseEvent e) {
		}

		@Override
		public void mouseReleased(MouseEvent e) {
		}

		@Override
		public void mouseEntered(MouseEvent e) {
		}

		@Override
		public void mouseExited(MouseEvent e) {
		}
		
	}
	
	public void refresh() {
		for (int i = 0; i < nrColors; i++) {
			int R, G, B;
			
			if (random.nextInt(2) == 0) {
				// Totally random.
				R = random.nextInt(256);
				G = random.nextInt(256);
				B = random.nextInt(256);
				
			} else {
				// Try to generate similar colors.
				int baseR = random.nextInt(256);
				int baseG = random.nextInt(256);
				int baseB = random.nextInt(256);
				
				int limit = 30;
				
				// Set R, G, B.
				// R.
				if (random.nextInt(2) == 0) {
					R = Math.max(0, baseR - random.nextInt(limit));
				} else {
					R = Math.min(255, baseR + random.nextInt(limit));
				}
				
				// G.
				if (random.nextInt(2) == 0) {
					G = Math.max(0, baseG - random.nextInt(limit));
				} else {
					G = Math.min(255, baseG + random.nextInt(limit));
				}
				
				// B.
				if (random.nextInt(2) == 0) {
					B = Math.max(0, baseB - random.nextInt(limit));
				} else {
					B = Math.min(255, baseB + random.nextInt(limit));
				}
			}
        	
        	colorPanels[i].setBackground(new Color(R, G, B));
        	textOnPanel[i].setBackground(colorPanels[i].getBackground());
        	
        	String text = "Vlad Ionescu\n";
        	text += "H: " + Math.floor(360 * (Color.RGBtoHSB(R, G, B, null))[0]) + ", ";
        	text += "S: " + Math.floor(100 * (Color.RGBtoHSB(R, G, B, null))[1]) + ", ";
        	text += "B: " + Math.floor(100 * (Color.RGBtoHSB(R, G, B, null))[2]);
        	
        	textOnPanel[i].setText(text);
        }
	}
	
	// Constructor
	public AppMainScreen(int nrColors, String fileName) {
		this.nrColors = nrColors;
		
		// Open file in append mode.
		try {
			writer = new BufferedWriter(new FileWriter(fileName, true));
		} catch (Exception e) {
			throw new RuntimeException("Error! :-(");
		}
		
		// Initialize random number generators.
		random = new Random();
		
		// Set details.
		setTitle("Complementary Color Picker");
		setSize(600, 300);
		setDefaultCloseOperation(EXIT_ON_CLOSE);
		setLayout(new GridLayout(2, nrColors + 1));
		
		// Add color panels.
		colorPanels = new JPanel[nrColors];
		textOnPanel = new JTextPane[nrColors];
		
		for (int i = 0; i < nrColors; i++) {
			colorPanels[i] = new JPanel();
			this.add(colorPanels[i]);
			
			int R = random.nextInt(256);
			int G = random.nextInt(256);
			int B = random.nextInt(256);
			
			colorPanels[i].setBackground(new Color(R, G, B));
			
			textOnPanel[i] = new JTextPane();
			colorPanels[i].add(textOnPanel[i]);
		}
		
		refresh();
		
		// Add complementary color panel.
		complColorPanel = new JPanel();
		this.add(complColorPanel);
		
		complColorPanel.setBackground(new Color(200, 200, 200));
		complColorPanel.addMouseListener(new JPanelMouseListener());
		
		// Add two buttons.
		refreshButton = new JButton("Refresh");
		submitButton = new JButton("Submit");
		this.add(refreshButton);
		this.add(submitButton);
		
		// Button for refreshing colors.
		refreshButton.addActionListener(new ActionListener() {
			@Override
            public void actionPerformed(ActionEvent event) {
                refresh();
            }
		});
		
		// Button for submitting this choice.
		submitButton.addActionListener(new ActionListener() {
			@Override
            public void actionPerformed(ActionEvent event) {
                String result = "";
                
                // Add information about dominant colors.
                for (int i = 0; i < nrColors; i++) {
                	Color c = colorPanels[i].getBackground();
                	float[] hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
                	
                	result += hsb[0] + "," + hsb[1] + "," + hsb[2] + ",";
                }
                
                // Add information about complementary color.
                Color c = complColorPanel.getBackground();
                float[] hsb = Color.RGBtoHSB(c.getRed(), c.getGreen(), c.getBlue(), null);
                
                result += hsb[0] + "," + hsb[1] + "," + hsb[2];
                
                try {
                	writer.write(result);
                	writer.newLine();
                	writer.flush();
                } catch (Exception e) {
                	throw new RuntimeException("Error when writting in file! :-(.");
                }
                
                // Refresh
                refresh();
            }
		});
	}
}
