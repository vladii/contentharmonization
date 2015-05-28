
public class ComplementaryColorPicker {

	public static final int NR_DOMINANT_COLORS = 3;
	public static final String FILE_NAME = "colors_dominant_compl.txt";
	
	public static void main(String[] args) {
		AppMainScreen screen = new AppMainScreen(NR_DOMINANT_COLORS, FILE_NAME);
		screen.setVisible(true);
	}
}
