package viking.atlassian.tools.util;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Git utils.
 *
 * @author Andreas Borglin
 */
public class GitUtil {

    private static final String JIRA_MARKER = "JIRA:";

    public static Set<String> getJiraReferencesFromTopicBranch(String topicBranch, String targetBranch,
                                                               String baseCommit, boolean debug) {
        Set<String> jiraReferences = new HashSet<String>();
        String commonAncestor = baseCommit;
        // If client didn't provide a base commit, we have to look up the common ancestor
        if (commonAncestor == null || commonAncestor.trim().length() == 0) {
            commonAncestor = getCommonAncestor(topicBranch, targetBranch);
        }

        if (debug) {
            System.out.println("Common ancestor: " + commonAncestor);
        }
        List<String> newCommits = getCommitsOnBranchAfter(topicBranch, commonAncestor);
        for (String commit : newCommits) {
            if (debug) {
                System.out.println("Commit: " + commit);
            }
            jiraReferences.addAll(getJiraReferencesFromCommit(commit));
        }
        return jiraReferences;
    }

    public static String getCommonAncestor(String branchOne, String branchTwo) {
        List<String> output = getOutputLinesFromCommand("git merge-base " + branchOne + " " + branchTwo);
        if (output != null && output.size() > 0) {
            return output.get(0);
        }
        System.out.println("Failed to execute command for common ancestor");
        return null;
    }

    public static List<String> getCommitsOnBranchAfter(String branch, String commitId) {
        return getOutputLinesFromCommand("git rev-list ^" + commitId + " " + branch);
    }

    public static List<String> getJiraReferencesFromCommit(String commitId) {
        List<String> commitMsg = getOutputLinesFromCommand("git show -s --format=%B " + commitId);
        List<String> jiraReferences = new ArrayList<String>();
        for (String line : commitMsg) {
            if (line.startsWith(JIRA_MARKER)) {
                jiraReferences.add(line.substring(JIRA_MARKER.length(), line.length()).trim());
            }
        }
        return jiraReferences;
    }

    public static List<String> getOutputLinesFromCommand(String command) {
        Runtime runtime = Runtime.getRuntime();
        try {
            Process proc = runtime.exec(command);

            BufferedReader stdInput = new BufferedReader(new
                    InputStreamReader(proc.getInputStream()));

            BufferedReader stdError = new BufferedReader(new
                    InputStreamReader(proc.getErrorStream()));

            List<String> lines = new ArrayList<String>();
            String s;
            while ((s = stdInput.readLine()) != null) {
                lines.add(s);
            }

            // Print errors command line so we can debug
            while ((s = stdError.readLine()) != null) {
                System.out.println(s);
            }

            int status = proc.waitFor();
            if (status != 0) {
                System.out.println("Process exited with non-zero: " + status);
            }
            return lines;
        }
        catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }
}
