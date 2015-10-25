package viking.atlassian.tools.util;


import java.io.Console;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;

/**
 * Helper for reviewers list.
 *
 * @author Andreas Borglin
 */
public class ReviewersHelper {

    private static final String REVIEWERS_FILE = ".stashreviewers";

    private static final String getReviewersFilePath() {
        if (System.getProperty("os.name").startsWith("Windows")) {
            return System.getProperty("user.home") + "\\" + REVIEWERS_FILE;
        }
        else {
            return System.getProperty("user.home") + "/" + REVIEWERS_FILE;
        }
    }

    public static List<String> getReviewers() {
        try {
            String reviewers = FileUtil.readStringFromFile(getReviewersFilePath());
            if (reviewers != null) {
                String[] arr = reviewers.split(",");
                if (arr != null && arr.length > 0) {
                    return Arrays.asList(arr);
                }
            }
        }
        catch (IOException e) {
            System.out.println("No reviewers file found");
        }

        return null;
    }

    public static void updateReviewersList() {
        Console console = System.console();
        System.out.println();
        System.out.println("Provide Stash reviewers names in comma separated list");
        System.out.println("Example: thor,odin,loke");
        String reviewers = console.readLine("Reviewers: ");
        if (reviewers != null && reviewers.length() > 0) {
            FileUtil.writeStringToFile(getReviewersFilePath(), reviewers);
        }
    }
}
